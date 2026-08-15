import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'notification_store.dart';
import '../router/router.dart';

/// Centralized notification service for Farm AI.
/// Handles:
///  - Weather push alerts (daily morning summary + storm warnings)
///  - Chat message notifications
///  - Medication / vaccine reminders scheduled at a specific date & time
///  - Integrates with NotificationStore for in-app notification center
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // ── Channel IDs ────────────────────────────────────────────────────────────
  static const String _weatherChannelId = 'weather_alerts';
  static const String _weatherChannelName = 'Weather Alerts';
  static const String _weatherChannelDesc =
      'Daily weather summary and storm warnings for farmers';

  static const String _medicationChannelId = 'medication_reminders';
  static const String _medicationChannelName = 'Medication Reminders';
  static const String _medicationChannelDesc =
      'Vaccine, deworming and vitamin reminders for livestock';

  static const String _chatChannelId = 'chat_messages';
  static const String _chatChannelName = 'Chat Messages';
  static const String _chatChannelDesc =
      'Incoming messages from vets and community users';

  // ── Notification ID ranges ─────────────────────────────────────────────────
  static const int _weatherNotifId = 9000; // fixed ID for daily weather
  static const int _weatherTomorrowNotifId = 9001; // tomorrow forecast

  // ── Init ───────────────────────────────────────────────────────────────────
  Future<void> initialize() async {
    if (_initialized) return;
    try {
      tz_data.initializeTimeZones();

      // Set local timezone — Bangladesh = Asia/Dhaka
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Dhaka'));
      } catch (_) {}

      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidSettings);

      await _plugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: _onNotificationTap,
        onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationTap,
      );

      // Request permissions
      try {
        await Permission.notification.request();
      } catch (_) {}
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();

      // Create channels
      await _createChannels();

      _initialized = true;

      // Init store
      await NotificationStore().init();

      debugPrint('[NotificationService] Initialized ✓');
    } catch (e) {
      debugPrint('[NotificationService] Init error: $e');
    }
  }

  Future<void> _createChannels() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;

    await android.createNotificationChannel(const AndroidNotificationChannel(
      _weatherChannelId,
      _weatherChannelName,
      description: _weatherChannelDesc,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    ));

    await android.createNotificationChannel(const AndroidNotificationChannel(
      _medicationChannelId,
      _medicationChannelName,
      description: _medicationChannelDesc,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    ));

    await android.createNotificationChannel(const AndroidNotificationChannel(
      _chatChannelId,
      _chatChannelName,
      description: _chatChannelDesc,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    ));
  }

  @pragma('vm:entry-point')
  static void _onBackgroundNotificationTap(NotificationResponse response) {
    debugPrint('[NotificationService] BG Tapped: ${response.payload}');
  }

  void _onNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    debugPrint('[NotificationService] Tapped: $payload');
    if (payload != null && payload.startsWith('NEW_CHAT_MESSAGE')) {
      final parts = payload.split('|');
      if (parts.length >= 3) {
        final senderId = parts[1];
        final senderName = parts[2];
        router.push('/chat/$senderId?name=${Uri.encodeComponent(senderName)}');
      }
    }
  }

  // ── Weather Notifications ─────────────────────────────────────────────────

  /// Show an immediate weather alert (e.g. storm warning detected on refresh).
  Future<void> showWeatherAlert({
    required String title,
    required String body,
    String? payload,
  }) async {
    await _ensureInit();
    try {
      await _plugin.show(
        id: _weatherNotifId,
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _weatherChannelId,
            _weatherChannelName,
            channelDescription: _weatherChannelDesc,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            color: Color(0xFF047857),
            playSound: true,
            enableVibration: true,
          ),
        ),
        payload: payload,
      );

      // Also store in in-app notification center
      await NotificationStore().push(
        id: 'weather_${DateTime.now().millisecondsSinceEpoch}',
        type: 'weather',
        title: title,
        body: body,
      );
    } catch (e) {
      debugPrint('[NotificationService] showWeatherAlert error: $e');
    }
  }

  /// Show a cold-start weather notification immediately on app open.
  Future<void> showColdStartWeatherNotification({
    required String title,
    required String body,
  }) async {
    await _ensureInit();
    try {
      await _plugin.show(
        id: _weatherNotifId + 10,
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _weatherChannelId,
            _weatherChannelName,
            channelDescription: _weatherChannelDesc,
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            icon: '@mipmap/ic_launcher',
            color: Color(0xFF047857),
            playSound: false,
            enableVibration: false,
            onlyAlertOnce: true,
            autoCancel: true,
          ),
        ),
        payload: 'WEATHER_COLD_START',
      );

      await NotificationStore().push(
        id: 'weather_cold_start',
        type: 'weather',
        title: title,
        body: body,
      );
    } catch (e) {
      debugPrint('[NotificationService] showColdStartWeatherNotification error: $e');
    }
  }

  /// Schedule a daily morning weather reminder at a specific hour & minute.
  /// Defaults to 07:00 AM local time.
  Future<void> scheduleDailyWeatherReminder({
    int hour = 7,
    int minute = 0,
    String title = '🌤️ আজকের আবহাওয়া আপডেট',
    String body =
        'আজকের আবহাওয়া ও কৃষি পরামর্শ দেখতে ক্লিক করুন। পশুদের যত্ন নিন।',
  }) async {
    await _ensureInit();
    try {
      final now = tz.TZDateTime.now(tz.local);
      var scheduled = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );
      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }

      await _plugin.zonedSchedule(
        id: _weatherNotifId,
        title: title,
        body: body,
        scheduledDate: scheduled,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _weatherChannelId,
            _weatherChannelName,
            channelDescription: _weatherChannelDesc,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            color: Color(0xFF047857),
            playSound: true,
            enableVibration: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'WEATHER_DAILY',
      );
      debugPrint(
          '[NotificationService] Daily weather reminder set for $hour:${minute.toString().padLeft(2, '0')}');
    } catch (e) {
      debugPrint('[NotificationService] scheduleDailyWeatherReminder error: $e');
    }
  }

  /// Schedule a one-time tomorrow-morning weather forecast notification.
  Future<void> scheduleTomorrowWeatherForecast({
    required String weatherSummary,
    required String location,
    int hour = 6,
    int minute = 30,
  }) async {
    await _ensureInit();
    try {
      final now = tz.TZDateTime.now(tz.local);
      final tomorrow = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day + 1,
        hour,
        minute,
      );

      await _plugin.zonedSchedule(
        id: _weatherTomorrowNotifId,
        title: '🌦️ আগামীকালের পূর্বাভাস — $location',
        body: weatherSummary,
        scheduledDate: tomorrow,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _weatherChannelId,
            _weatherChannelName,
            channelDescription: _weatherChannelDesc,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            color: Color(0xFF0284C7),
            playSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'WEATHER_TOMORROW',
      );
      debugPrint('[NotificationService] Tomorrow weather forecast scheduled');
    } catch (e) {
      debugPrint(
          '[NotificationService] scheduleTomorrowWeatherForecast error: $e');
    }
  }

  // ── Chat Notifications ─────────────────────────────────────────────────────

  /// Show an immediate chat message notification.
  Future<void> showChatNotification({
    required String senderId,
    required String senderName,
    required String message,
  }) async {
    await _ensureInit();
    try {
      await _plugin.show(
        id: senderId.hashCode,
        title: '💬 $senderName',
        body: message,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _chatChannelId,
            _chatChannelName,
            channelDescription: _chatChannelDesc,
            importance: Importance.max,
            priority: Priority.max,
            icon: '@mipmap/ic_launcher',
            color: Color(0xFF047857),
            playSound: true,
            enableVibration: true,
            channelShowBadge: true,
            enableLights: true,
            ledColor: Color(0xFF047857),
            category: AndroidNotificationCategory.message,
          ),
        ),
        payload: 'NEW_CHAT_MESSAGE|$senderId|$senderName',
      );

      await NotificationStore().push(
        id: 'chat_${senderId}_${DateTime.now().millisecondsSinceEpoch}',
        type: 'chat',
        title: '💬 $senderName',
        body: message,
      );
    } catch (e) {
      debugPrint('[NotificationService] showChatNotification error: $e');
    }
  }

  /// Trigger a test chat notification to verify Android OS Notification Panel display
  Future<void> showTestChatNotification() async {
    await showChatNotification(
      senderId: 'test_vet_101',
      senderName: 'ডাঃ মোফাজ্জল হোসেন (পশু চিকিৎসক)',
      message: 'আপনার গরুর লম্পি স্কিন ডিসিজের জন্য নতুন ওষুধ দেওয়া হয়েছে। বিস্তারিত দেখতে ক্লিক করুন।',
    );
  }

  // ── Medication / Vaccine Reminders ────────────────────────────────────────

  /// Schedule a medication / vaccine reminder at [scheduledTime].
  /// If [scheduledTime] is in the past, fires immediately.
  Future<void> scheduleMedicationReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    await _ensureInit();
    try {
      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          _medicationChannelId,
          _medicationChannelName,
          channelDescription: _medicationChannelDesc,
          importance: Importance.max,
          priority: Priority.max,
          icon: '@mipmap/ic_launcher',
          color: Color(0xFF059669),
          playSound: true,
          enableVibration: true,
          fullScreenIntent: false,
        ),
      );

      if (scheduledTime.isAfter(DateTime.now())) {
        final tzTime = tz.TZDateTime.from(scheduledTime, tz.local);
        await _plugin.zonedSchedule(
          id: id,
          title: title,
          body: body,
          scheduledDate: tzTime,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: 'MEDICATION|$id',
        );
        debugPrint(
            '[NotificationService] Medication reminder #$id set for $scheduledTime');
      } else {
        await _plugin.show(
          id: id,
          title: title,
          body: body,
          notificationDetails: details,
          payload: 'MEDICATION|$id',
        );
        debugPrint('[NotificationService] Medication reminder #$id fired immediately');
      }

      // Store in in-app notification center
      await NotificationStore().push(
        id: 'medication_$id',
        type: 'reminder',
        title: title,
        body: body,
      );
    } catch (e) {
      debugPrint('[NotificationService] scheduleMedicationReminder error: $e');
    }
  }

  /// Cancel a specific medication reminder by [id].
  Future<void> cancelMedicationReminder(int id) async {
    await _ensureInit();
    try {
      await _plugin.cancel(id: id);
      debugPrint('[NotificationService] Cancelled reminder #$id');
    } catch (e) {
      debugPrint('[NotificationService] cancel error: $e');
    }
  }

  /// Cancel the daily weather reminder.
  Future<void> cancelDailyWeatherReminder() async {
    await _ensureInit();
    try {
      await _plugin.cancel(id: _weatherNotifId);
    } catch (e) {
      debugPrint('[NotificationService] cancelDailyWeatherReminder error: $e');
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Future<void> _ensureInit() async {
    if (!_initialized) await initialize();
  }
}
