import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'core/network/api_client.dart';
import 'core/theme/app_theme.dart';
import 'core/router/router.dart';
import 'core/services/call_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// ── Local notifications channel ─────────────────────────────────────────────
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel incomingCallChannel = AndroidNotificationChannel(
  'incoming_call',
  'Incoming Calls',
  description: 'Full-screen incoming video call notifications',
  importance: Importance.max,
  playSound: true,
  enableVibration: true,
);

// ── FCM background handler (top-level) ──────────────────────────────────────
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('[FCM Background] Message: ${message.data}');

  // Show heads-up notification for incoming calls
  if (message.data['type'] == 'INCOMING_CALL') {
    final callerName = message.data['callerName'] ?? 'ডাক্তার';
    await flutterLocalNotificationsPlugin.show(
      id: 0,
      title: '📞 ইনকামিং ভিডিও কল',
      body: 'ডাঃ $callerName আপনাকে কল করছেন',
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          incomingCallChannel.id,
          incomingCallChannel.name,
          channelDescription: incomingCallChannel.description,
          importance: Importance.max,
          priority: Priority.max,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.call,
          playSound: true,
          enableVibration: true,
          ongoing: false,
          autoCancel: true,
        ),
      ),
      payload: 'INCOMING_CALL|${message.data['roomId']}|${message.data['callerName']}|${message.data['consultationId']}',
    );
  }
}

Future<void> setupFirebase() async {
  if (kIsWeb) return;
  try {
    await Firebase.initializeApp();

    // Create notification channel
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(incomingCallChannel);

    // Explicitly request OS notification permissions (Android 13+ POST_NOTIFICATIONS & iOS)
    try {
      await Permission.notification.request();
    } catch (e) {
      debugPrint('[Permission] Notification request error: $e');
    }
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // Initialize local notifications
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings =
        InitializationSettings(android: androidSettings);

    await flutterLocalNotificationsPlugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // User tapped the notification — navigate to incoming call
        final payload = response.payload;
        if (payload != null) {
          if (payload.startsWith('INCOMING_CALL|')) {
            final parts = payload.split('|');
            if (parts.length >= 4) {
              final roomId = parts[1];
              final callerName = parts[2];
              final consultationId = parts[3];
              router.push('/incoming-call', extra: {
                'roomId': roomId,
                'callerName': callerName,
                'consultationId': consultationId,
                'callerSocketId': '',
              });
            }
          } else if (payload.startsWith('NEW_CHAT_MESSAGE|')) {
            final parts = payload.split('|');
            if (parts.length >= 3) {
              final senderId = parts[1];
              final senderName = parts[2];
              router.push('/chat/$senderId?name=${Uri.encodeComponent(senderName)}');
            }
          }
        }
      },
    );

    final FirebaseMessaging messaging = FirebaseMessaging.instance;

    final NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      criticalAlert: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      final String? token = await messaging.getToken();
      if (token != null) {
        debugPrint('[FCM] Token: ${token.substring(0, 20)}...');
        await ApiClient.updateFcmToken(token);
      }

      // Refresh token when it changes
      messaging.onTokenRefresh.listen((newToken) {
        ApiClient.updateFcmToken(newToken);
      });
    }

    // Background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Foreground message handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('[FCM Foreground] Message: ${message.data}');
      if (message.data['type'] == 'INCOMING_CALL') {
        // CallService will handle this via Socket.IO already if online,
        // but if not show a local notification as fallback
        final callerName = message.data['callerName'] ?? 'ডাক্তার';
        final roomId = message.data['roomId'] ?? '';
        final consultationId = message.data['consultationId'] ?? '';

        flutterLocalNotificationsPlugin.show(
          id: 0,
          title: '📞 ইনকামিং ভিডিও কল',
          body: 'ডাঃ $callerName আপনাকে কল করছেন',
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              incomingCallChannel.id,
              incomingCallChannel.name,
              importance: Importance.max,
              priority: Priority.max,
              fullScreenIntent: true,
              category: AndroidNotificationCategory.call,
              playSound: true,
            ),
          ),
          payload: 'INCOMING_CALL|$roomId|$callerName|$consultationId',
        );
      } else if (message.data['type'] == 'NEW_CHAT_MESSAGE') {
        final senderName = message.data['senderName'] ?? 'ব্যবহারকারী';
        final content = message.notification?.body ?? message.data['body'] ?? '';
        final senderId = message.data['senderId'] ?? '';

        flutterLocalNotificationsPlugin.show(
          id: senderId.hashCode,
          title: senderName,
          body: content,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'chat_messages',
              'Chat Messages',
              importance: Importance.max,
              priority: Priority.max,
              playSound: true,
            ),
          ),
          payload: 'NEW_CHAT_MESSAGE|$senderId|$senderName',
        );
      }
    });

    // App opened from notification
    final RemoteMessage? initialMessage =
        await messaging.getInitialMessage();
    if (initialMessage != null) {
      if (initialMessage.data['type'] == 'INCOMING_CALL') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final data = initialMessage.data;
          router.push('/incoming-call', extra: {
            'roomId': data['roomId'],
            'callerName': data['callerName'],
            'consultationId': data['consultationId'],
            'callerSocketId': '',
          });
        });
      } else if (initialMessage.data['type'] == 'NEW_CHAT_MESSAGE') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final data = initialMessage.data;
          final senderId = data['senderId'];
          final senderName = data['senderName'] ?? 'ব্যবহারকারী';
          router.push('/chat/$senderId?name=${Uri.encodeComponent(senderName)}');
        });
      }
    }

    // App in background, notification tapped
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (message.data['type'] == 'INCOMING_CALL') {
        final data = message.data;
        router.push('/incoming-call', extra: {
          'roomId': data['roomId'],
          'callerName': data['callerName'],
          'consultationId': data['consultationId'],
          'callerSocketId': '',
        });
      } else if (message.data['type'] == 'NEW_CHAT_MESSAGE') {
        final data = message.data;
        final senderId = data['senderId'];
        final senderName = data['senderName'] ?? 'ব্যবহারকারী';
        router.push('/chat/$senderId?name=${Uri.encodeComponent(senderName)}');
      }
    });
  } catch (e) {
    debugPrint('[Firebase] Initialization error: $e');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {}

  await setupFirebase();

  // Wire navigator key into CallService so it can show incoming call overlay
  CallService().setNavigatorKey(navigatorKey);

  runApp(
    const ProviderScope(
      child: FarmAIApp(),
    ),
  );
}

class FarmAIApp extends StatelessWidget {
  const FarmAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'FarmAI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
