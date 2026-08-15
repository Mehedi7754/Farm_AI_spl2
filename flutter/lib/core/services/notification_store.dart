import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A lightweight notification model
class AppNotification {
  final String id;
  final String type; // 'weather' | 'chat' | 'reminder' | 'call' | 'milk'
  final String title;
  final String body;
  final String time; // human-readable, e.g. 'এইমাত্র'
  final DateTime createdAt;
  bool isRead;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.time,
    required this.createdAt,
    this.isRead = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'title': title,
        'body': body,
        'time': time,
        'createdAt': createdAt.toIso8601String(),
        'isRead': isRead,
      };

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: json['id'] as String,
        type: json['type'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        time: json['time'] as String? ?? 'এইমাত্র',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
        isRead: json['isRead'] as bool? ?? false,
      );
}

/// Singleton store for all in-app notifications.
/// Persists to SharedPreferences. Exposes [unreadCountNotifier] for widgets.
class NotificationStore {
  static final NotificationStore _instance = NotificationStore._internal();
  factory NotificationStore() => _instance;
  NotificationStore._internal();

  static const _key = 'app_notifications_v3';

  final List<AppNotification> _notifications = [];
  final ValueNotifier<int> unreadCountNotifier = ValueNotifier<int>(0);

  /// Must be called once during app startup.
  Future<void> init() async {
    await _load();
  }

  List<AppNotification> get all => List.unmodifiable(_notifications);

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  /// Push a new notification. Dedupes by id. Newest first.
  Future<void> push({
    required String id,
    required String type,
    required String title,
    required String body,
  }) async {
    // Avoid exact duplicate within last 60 seconds
    final now = DateTime.now();
    final existingIdx = _notifications.indexWhere((n) => n.id == id);
    if (existingIdx >= 0) {
      final existing = _notifications[existingIdx];
      if (now.difference(existing.createdAt).inSeconds < 60) return;
      _notifications.removeAt(existingIdx);
    }

    final n = AppNotification(
      id: id,
      type: type,
      title: title,
      body: body,
      time: _relativeTime(now),
      createdAt: now,
      isRead: false,
    );
    _notifications.insert(0, n);

    // Keep max 50 entries
    while (_notifications.length > 50) {
      _notifications.removeLast();
    }

    await _save();
    unreadCountNotifier.value = unreadCount;
  }

  Future<void> markRead(String id) async {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx >= 0) {
      _notifications[idx].isRead = true;
      await _save();
      unreadCountNotifier.value = unreadCount;
    }
  }

  Future<void> markAllRead() async {
    for (final n in _notifications) {
      n.isRead = true;
    }
    await _save();
    unreadCountNotifier.value = 0;
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _notifications.map((n) => n.toJson()).toList();
      await prefs.setString(_key, jsonEncode(list));
    } catch (e) {
      debugPrint('[NotificationStore] save error: $e');
    }
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw != null) {
        final list = jsonDecode(raw) as List<dynamic>;
        _notifications.clear();
        for (final item in list) {
          try {
            _notifications.add(AppNotification.fromJson(item as Map<String, dynamic>));
          } catch (_) {}
        }
      }
    } catch (e) {
      debugPrint('[NotificationStore] load error: $e');
    }
    unreadCountNotifier.value = unreadCount;
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'এইমাত্র';
    if (diff.inMinutes < 60) return '${diff.inMinutes} মিনিট আগে';
    if (diff.inHours < 24) return '${diff.inHours} ঘণ্টা আগে';
    return '${diff.inDays} দিন আগে';
  }
}
