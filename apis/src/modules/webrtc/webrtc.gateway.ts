import { WebSocketGateway, WebSocketServer, SubscribeMessage, OnGatewayConnection, OnGatewayDisconnect, MessageBody, ConnectedSocket } from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { Logger } from '@nestjs/common';
import { FcmService } from './fcm.service';
import { PrismaService } from '../../database/prisma.service';

@WebSocketGateway({
  cors: { origin: '*' },
  namespace: '/webrtc',
})
export class WebrtcGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer() server: Server;
  private readonly logger = new Logger(WebrtcGateway.name);

  // roomId -> Set of socketIds
  private rooms = new Map<string, Set<string>>();
  // socketId -> roomId
  private socketToRoom = new Map<string, string>();
  // userId -> socketId (for targeting specific users)
  private userToSocket = new Map<string, string>();
  // socketId -> userId
  private socketToUser = new Map<string, string>();

  constructor(
    private readonly fcmService: FcmService,
    private readonly prisma: PrismaService,
  ) {}

  handleConnection(client: Socket) {
    this.logger.log(`Client connected: ${client.id}`);
  }

  handleDisconnect(client: Socket) {
    this.logger.log(`Client disconnected: ${client.id}`);

    // Clean up user mapping
    const userId = this.socketToUser.get(client.id);
    if (userId) {
      this.userToSocket.delete(userId);
      this.socketToUser.delete(client.id);
    }

    const roomId = this.socketToRoom.get(client.id);
    if (roomId) {
      const room = this.rooms.get(roomId);
      if (room) {
        room.delete(client.id);
        if (room.size === 0) this.rooms.delete(roomId);
        else {
          client.to(roomId).emit('peer-left', { socketId: client.id });
        }
      }
      this.socketToRoom.delete(client.id);
    }
  }

  @SubscribeMessage('register-user')
  handleRegisterUser(
    @MessageBody() data: { userId: string },
    @ConnectedSocket() client: Socket,
  ) {
    const { userId } = data;
    this.userToSocket.set(userId, client.id);
    this.socketToUser.set(client.id, userId);
    this.logger.log(`User ${userId} registered with socket ${client.id}`);
    client.emit('user-registered', { userId, socketId: client.id });
  }

  @SubscribeMessage('join-room')
  handleJoinRoom(
    @MessageBody() data: { roomId: string; userId: string },
    @ConnectedSocket() client: Socket,
  ) {
    const { roomId, userId } = data;
    client.join(roomId);

    // Register user-socket mapping on join too
    if (userId) {
      this.userToSocket.set(userId, client.id);
      this.socketToUser.set(client.id, userId);
    }

    if (!this.rooms.has(roomId)) this.rooms.set(roomId, new Set());
    this.rooms.get(roomId)!.add(client.id);
    this.socketToRoom.set(client.id, roomId);

    const otherUsers = [...this.rooms.get(roomId)!].filter((id) => id !== client.id);
    this.logger.log(`User ${userId} joined room ${roomId}. Others: ${otherUsers.length}`);

    client.emit('room-joined', { roomId, otherUsers, userId });
    client.to(roomId).emit('peer-joined', { socketId: client.id, userId });
  }

  // ── Vet initiates call → notify farmer via Socket.IO + FCM ──────────────
  @SubscribeMessage('initiate-call')
  async handleInitiateCall(
    @MessageBody() data: { consultationId: string; callerName: string; roomId: string; targetUserId: string },
    @ConnectedSocket() client: Socket,
  ) {
    const { consultationId, callerName, roomId, targetUserId } = data;
    this.logger.log(`Call initiated by ${callerName} to user ${targetUserId} in room ${roomId}`);

    // 1. Try Socket.IO first (if farmer is online)
    const farmerSocketId = this.userToSocket.get(targetUserId);
    if (farmerSocketId) {
      this.server.to(farmerSocketId).emit('incoming-call', {
        consultationId,
        callerName,
        roomId,
        callerSocketId: client.id,
      });
      this.logger.log(`Socket.IO call notification sent to ${targetUserId}`);
    } else {
      this.logger.log(`User ${targetUserId} not online — falling back to FCM`);
    }

    // 2. Always send FCM push too (for background/killed app)
    try {
      const user = await this.prisma.user.findUnique({
        where: { id: targetUserId },
        select: { fcmToken: true },
      });
      if (user?.fcmToken) {
        await this.fcmService.sendCallNotification({
          fcmToken: user.fcmToken,
          callerName,
          roomId,
          consultationId,
        });
      }
    } catch (e) {
      this.logger.error('Error fetching user FCM token', e?.message);
    }

    client.emit('call-initiated', { success: true, targetUserId, roomId });
  }

  @SubscribeMessage('call-declined')
  handleCallDeclined(
    @MessageBody() data: { roomId: string; callerSocketId: string },
    @ConnectedSocket() client: Socket,
  ) {
    this.server.to(data.callerSocketId).emit('call-declined', { socketId: client.id });
    this.logger.log(`Call declined in room ${data.roomId}`);
  }

  @SubscribeMessage('offer')
  handleOffer(
    @MessageBody() data: { to: string; offer: RTCSessionDescriptionInit; from: string },
    @ConnectedSocket() client: Socket,
  ) {
    this.server.to(data.to).emit('offer', { offer: data.offer, from: client.id });
  }

  @SubscribeMessage('answer')
  handleAnswer(
    @MessageBody() data: { to: string; answer: RTCSessionDescriptionInit },
    @ConnectedSocket() client: Socket,
  ) {
    this.server.to(data.to).emit('answer', { answer: data.answer, from: client.id });
  }

  @SubscribeMessage('ice-candidate')
  handleIceCandidate(
    @MessageBody() data: { to: string; candidate: RTCIceCandidateInit },
    @ConnectedSocket() client: Socket,
  ) {
    this.server.to(data.to).emit('ice-candidate', { candidate: data.candidate, from: client.id });
  }

  @SubscribeMessage('call-ended')
  handleCallEnded(
    @MessageBody() data: { roomId: string },
    @ConnectedSocket() client: Socket,
  ) {
    client.to(data.roomId).emit('call-ended');
    this.logger.log(`Call ended in room ${data.roomId}`);
  }

  @SubscribeMessage('toggle-audio')
  handleToggleAudio(
    @MessageBody() data: { roomId: string; muted: boolean },
    @ConnectedSocket() client: Socket,
  ) {
    client.to(data.roomId).emit('peer-audio-toggle', { socketId: client.id, muted: data.muted });
  }

  @SubscribeMessage('toggle-video')
  handleToggleVideo(
    @MessageBody() data: { roomId: string; videoOff: boolean },
    @ConnectedSocket() client: Socket,
  ) {
    client.to(data.roomId).emit('peer-video-toggle', { socketId: client.id, videoOff: data.videoOff });
  }
}
