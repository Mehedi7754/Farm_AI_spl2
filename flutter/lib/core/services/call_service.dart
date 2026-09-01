import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../../core/network/api_client.dart';
import '../../../features/video_call/presentation/screens/incoming_call_screen.dart';

/// Singleton service that maintains a persistent Socket.IO connection
/// for the logged-in user to receive incoming call notifications.
class CallService {
  static final CallService _instance = CallService._internal();
  factory CallService() => _instance;
  CallService._internal();

  io.Socket? _socket;
  bool _isConnected = false;
  GlobalKey<NavigatorState>? _navigatorKey;

  void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  /// Call this after user logs in.
  void connect(String userId) {
    if (_isConnected) return;

    final wsUrl = ApiClient.baseUrl
        .replaceFirst('/api', '')
        .replaceFirst('http', 'ws');

    _socket = io.io(
      '$wsUrl/webrtc',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionDelay(2000)
          .build(),
    );

    _socket!.onConnect((_) {
      debugPrint('[CallService] Connected. Registering user $userId');
      _socket!.emit('register-user', {'userId': userId});
      _isConnected = true;
    });

    _socket!.on('incoming-call', (data) {
      debugPrint('[CallService] Incoming call: $data');
      _showIncomingCallScreen(
        roomId: data['roomId'] as String,
        callerName: data['callerName'] as String,
        consultationId: data['consultationId'] as String,
        callerSocketId: data['callerSocketId'] as String? ?? '',
      );
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
      debugPrint('[CallService] Disconnected');
    });

    _socket!.onError((e) {
      debugPrint('[CallService] Socket error: $e');
    });
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
  }

  void _showIncomingCallScreen({
    required String roomId,
    required String callerName,
    required String consultationId,
    required String callerSocketId,
  }) {
    final ctx = _navigatorKey?.currentContext;
    if (ctx == null) {
      debugPrint('[CallService] No navigator context available');
      return;
    }

    // Push full-screen incoming call over whatever is showing
    Navigator.of(ctx, rootNavigator: true).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => IncomingCallScreen(
          roomId: roomId,
          callerName: callerName,
          consultationId: consultationId,
          callerSocketId: callerSocketId,
        ),
      ),
    );
  }
}
