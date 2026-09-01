import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../../database/prisma.service';
import { FcmService } from '../webrtc/fcm.service';

@Injectable()
export class ChatService {
  private readonly logger = new Logger(ChatService.name);

  constructor(
    private prisma: PrismaService,
    private fcmService: FcmService,
  ) {}

  async sendMessage(senderId: string, receiverId: string, content: string) {
    const message = await this.prisma.chatMessage.create({
      data: {
        senderId,
        receiverId,
        content,
        isRead: false,
      },
    });

    // Send push notification asynchronously so we don't block the HTTP response
    this._sendPushNotification(senderId, receiverId, content).catch((e) => {
      this.logger.error('Error sending chat push notification', e);
    });

    return message;
  }

  private async _sendPushNotification(senderId: string, receiverId: string, content: string) {
    // 1. Fetch sender name
    const sender = await this.prisma.user.findUnique({
      where: { id: senderId },
      select: { name: true },
    });

    // 2. Fetch receiver token
    const receiver = await this.prisma.user.findUnique({
      where: { id: receiverId },
      select: { fcmToken: true },
    });

    if (receiver?.fcmToken) {
      const senderName = sender?.name ?? 'ব্যবহারকারী';
      await this.fcmService.sendGenericNotification({
        fcmToken: receiver.fcmToken,
        title: senderName,
        body: content.length > 60 ? `${content.substring(0, 60)}...` : content,
        data: {
          type: 'NEW_CHAT_MESSAGE',
          senderId,
          senderName,
        },
      });
      this.logger.log(`Chat notification sent to receiver ${receiverId}`);
    }
  }

  async getChatHistory(userId1: string, userId2: string) {
    const messages = await this.prisma.chatMessage.findMany({
      where: {
        OR: [
          { senderId: userId1, receiverId: userId2 },
          { senderId: userId2, receiverId: userId1 },
        ],
      },
      orderBy: {
        createdAt: 'asc',
      },
    });

    // Mark messages received by userId1 from userId2 as read
    await this.prisma.chatMessage.updateMany({
      where: {
        senderId: userId2,
        receiverId: userId1,
        isRead: false,
      },
      data: { isRead: true },
    });

    return messages;
  }

  async getChatList(userId: string) {
    const messages = await this.prisma.chatMessage.findMany({
      where: {
        OR: [{ senderId: userId }, { receiverId: userId }],
      },
      orderBy: {
        createdAt: 'desc',
      },
      include: {
        sender: true,
        receiver: true,
      },
    });

    const conversations = new Map<string, any>();

    for (const msg of messages) {
      const otherUser = msg.senderId === userId ? msg.receiver : msg.sender;
      if (!otherUser) continue;
      if (!conversations.has(otherUser.id)) {
        conversations.set(otherUser.id, {
          user: otherUser,
          lastMessage: msg.content,
          createdAt: msg.createdAt,
        });
      }
    }

    return Array.from(conversations.values());
  }

  /**
   * Returns unread messages grouped by sender for the given userId (receiver).
   * Each entry includes: senderId, senderName, senderRole, lastMessage, lastMessageId, count.
   */
  async getUnreadSummary(userId: string) {
    const messages = await this.prisma.chatMessage.findMany({
      where: {
        receiverId: userId,
        isRead: false,
      },
      orderBy: { createdAt: 'desc' },
      include: {
        sender: {
          select: { id: true, name: true, role: true },
        },
      },
    });

    const senderMap = new Map<string, any>();
    for (const msg of messages) {
      if (!senderMap.has(msg.senderId)) {
        senderMap.set(msg.senderId, {
          senderId: msg.senderId,
          senderName: msg.sender?.name || 'ব্যবহারকারী',
          senderRole: msg.sender?.role,
          lastMessage: msg.content,
          lastMessageId: msg.id,
          createdAt: msg.createdAt.toISOString(),
          count: 1,
        });
      } else {
        senderMap.get(msg.senderId).count += 1;
      }
    }

    return Array.from(senderMap.values());
  }

  /**
   * Mark all messages from senderId to receiverId as read.
   */
  async markAsRead(receiverId: string, senderId: string) {
    return this.prisma.chatMessage.updateMany({
      where: { receiverId, senderId, isRead: false },
      data: { isRead: true },
    });
  }
}
