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
import 'core/services/notification_service.dart';
import 'core/services/notification_store.dart';
import 'core/services/weather_startup_service.dart';

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

// ── FCM background handler (top-level, runs even when app is killed) ─────────
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('[FCM Background] Message: ${message.data}');

  // Init local notifications plugin (background isolate)
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  await flutterLocalNotificationsPlugin.initialize(
    settings: const InitializationSettings(android: androidSettings),
  );

  final type = message.data['type'] as String? ?? '';

  if (type == 'INCOMING_CALL') {
    final callerName = message.data['callerName'] ?? 'ডাক্তার';
    final roomId = message.data['roomId'] ?? '';
    final consultationId = message.data['consultationId'] ?? '';
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
      payload: 'INCOMING_CALL|$roomId|$callerName|$consultationId',
    );
  } else if (type == 'NEW_CHAT_MESSAGE') {
    final senderName = message.data['senderName'] ?? 'ব্যবহারকারী';
    final content = message.notification?.body ?? message.data['body'] ?? '';
    final senderId = message.data['senderId'] ?? '';
    await flutterLocalNotificationsPlugin.show(
      id: senderId.hashCode,
      title: '💬 $senderName',
      body: content,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'chat_messages',
          'Chat Messages',
          channelDescription: 'Messages from vets and community users',
          importance: Importance.max,
          priority: Priority.max,
          playSound: true,
          enableVibration: true,
          category: AndroidNotificationCategory.message,
        ),
      ),
      payload: 'NEW_CHAT_MESSAGE|$senderId|$senderName',
    );
  } else if (type == 'WEATHER_ALERT') {
    final title = message.data['title'] ?? '🌤️ আবহাওয়া আপডেট';
    final body = message.data['body'] ?? 'আপনার এলাকার আবহাওয়া পরিবর্তন হয়েছে।';
    await flutterLocalNotificationsPlugin.show(
      id: 9099,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'weather_alerts',
          'Weather Alerts',
          channelDescription: 'Daily weather summary and storm warnings',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          color: Color(0xFF047857),
        ),
      ),
      payload: 'WEATHER_ALERT',
    );
  } else if (type.startsWith('RESERVATION_')) {
    final title = message.notification?.title ?? message.data['title'] ?? '📅 কনসালটেশন আপডেট';
    final body = message.notification?.body ?? message.data['body'] ?? 'আপনার অ্যাপয়েন্টমেন্ট স্ট্যাটাস আপডেট হয়েছে।';
    await flutterLocalNotificationsPlugin.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'chat_messages',
          'Chat Messages',
          channelDescription: 'Consultation & reservation updates',
          importance: Importance.max,
          priority: Priority.max,
          playSound: true,
          enableVibration: true,
          category: AndroidNotificationCategory.event,
        ),
      ),
      payload: 'RESERVATION',
    );
  }
}

Future<void> setupFirebase() async {
  if (kIsWeb) return;
  try {
    await Firebase.initializeApp();

    // Create notification channels
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(incomingCallChannel);

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          'chat_messages',
          'Chat Messages',
          description: 'Messages from vets and community users',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        ));

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          'weather_alerts',
          'Weather Alerts',
          description: 'Daily weather summary and storm warnings',
          importance: Importance.high,
          playSound: true,
        ));

    // Explicitly request OS notification permissions (Android 13+ POST_NOTIFICATIONS)
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
        final payload = response.payload;
        if (payload == null) return;
        if (payload.startsWith('INCOMING_CALL|')) {
          final parts = payload.split('|');
          if (parts.length >= 4) {
            router.push('/incoming-call', extra: {
              'roomId': parts[1],
              'callerName': parts[2],
              'consultationId': parts[3],
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
        } else if (payload.startsWith('WEATHER') || payload.startsWith('MEDICATION')) {
          router.push('/notifications');
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
      messaging.onTokenRefresh.listen((newToken) {
        ApiClient.updateFcmToken(newToken);
      });
    }

    // Background handler — handles KILLED app state
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Foreground message handler — app is open (cold start / foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      debugPrint('[FCM Foreground] Message: ${message.data}');
      final type = message.data['type'] as String? ?? '';

      if (type == 'INCOMING_CALL') {
        final callerName = message.data['callerName'] ?? 'ডাক্তার';
        final roomId = message.data['roomId'] ?? '';
        final consultationId = message.data['consultationId'] ?? '';

        await flutterLocalNotificationsPlugin.show(
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

        await NotificationStore().push(
          id: 'call_${DateTime.now().millisecondsSinceEpoch}',
          type: 'call',
          title: '📞 ইনকামিং ভিডিও কল',
          body: 'ডাঃ $callerName আপনাকে কল করছেন',
        );
      } else if (type == 'NEW_CHAT_MESSAGE') {
        final senderName = message.data['senderName'] ?? 'ব্যবহারকারী';
        final content = message.notification?.body ?? message.data['body'] ?? '';
        final senderId = message.data['senderId'] ?? '';

        // Use NotificationService so it also writes to store
        await NotificationService().showChatNotification(
          senderId: senderId,
          senderName: senderName,
          message: content,
        );
      } else if (type == 'WEATHER_ALERT') {
        final title = message.data['title'] ?? '🌤️ আবহাওয়া আপডেট';
        final body = message.data['body'] ?? 'আপনার এলাকার আবহাওয়া পরিবর্তন হয়েছে।';
        await NotificationService().showWeatherAlert(title: title, body: body, payload: 'WEATHER_ALERT');
      } else if (type.startsWith('RESERVATION_')) {
        final title = message.notification?.title ?? message.data['title'] ?? '📅 কনসালটেশন আপডেট';
        final body = message.notification?.body ?? message.data['body'] ?? 'আপনার অ্যাপয়েন্টমেন্ট স্ট্যাটাস আপডেট হয়েছে।';
        await NotificationService().showChatNotification(
          senderId: 'reservation_${DateTime.now().millisecondsSinceEpoch}',
          senderName: title,
          message: body,
        );
      }
    });

    // App opened from notification (cold start - killed state)
    final RemoteMessage? initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleFcmNavigation(initialMessage);
    }

    // App in background, notification tapped
    FirebaseMessaging.onMessageOpenedApp.listen(_handleFcmNavigation);
  } catch (e) {
    debugPrint('[Firebase] Initialization error: $e');
  }
}

void _handleFcmNavigation(RemoteMessage message) {
  final type = message.data['type'] as String? ?? '';
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (type == 'INCOMING_CALL') {
      router.push('/incoming-call', extra: {
        'roomId': message.data['roomId'] ?? '',
        'callerName': message.data['callerName'] ?? 'ডাক্তার',
        'consultationId': message.data['consultationId'] ?? '',
        'callerSocketId': '',
      });
    } else if (type == 'NEW_CHAT_MESSAGE') {
      final senderId = message.data['senderId'] ?? '';
      final senderName = message.data['senderName'] ?? 'ব্যবহারকারী';
      router.push('/chat/$senderId?name=${Uri.encodeComponent(senderName)}');
    } else if (type == 'WEATHER_ALERT') {
      router.push('/notifications');
    } else if (type.startsWith('RESERVATION_')) {
      router.push('/my-consultations');
    }
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {}

  await setupFirebase();

  // Initialize centralized notification service (also inits timezone + store)
  await NotificationService().initialize();

  // Schedule daily morning weather reminder at 07:00 AM
  await NotificationService().scheduleDailyWeatherReminder(
    hour: 7,
    minute: 0,
    title: '🌤️ আজকের আবহাওয়া আপডেট',
    body: 'সকালের আবহাওয়া পূর্বাভাস দেখুন ও আপনার পশুর সঠিক যত্ন নিন।',
  );

  // Initialize notification store (load persisted notifications)
  await NotificationStore().init();

  // Cold-start: fetch REAL weather data and fire a notification with actual conditions
  // Uses live backend API → real temperature, rain, heat stress data
  await WeatherStartupService().fireOnColdStart();

  // Wire navigator key into CallService
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
