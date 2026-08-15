import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../network/api_client.dart';
import 'notification_service.dart';

class ChatNotificationSyncService {
  static bool _isSyncing = false;

  /// Call upon login, splash auto-login, or dashboard start
  static Future<void> syncUnreadMessages([String? customUserId]) async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final user = ApiClient.currentUser;
      final userId = customUserId ?? user?['id']?.toString();
      if (userId == null || userId.isEmpty) {
        _isSyncing = false;
        return;
      }

      final unreadSummary = await ApiClient.getUnreadChatSummary(userId);
      if (unreadSummary.isEmpty) {
        _isSyncing = false;
        return;
      }

      final prefs = await SharedPreferences.getInstance();

      for (final item in unreadSummary) {
        if (item is! Map) continue;
        final senderId = item['senderId']?.toString() ?? '';
        final senderName = item['senderName']?.toString() ?? 'ব্যবহারকারী';
        final lastMessage = item['lastMessage']?.toString() ?? '';
        final count = (item['count'] is int) ? item['count'] as int : 1;
        final createdAt = item['createdAt']?.toString() ?? '';

        if (senderId.isEmpty || lastMessage.isEmpty) continue;

        final prefKey = 'chat_last_notified_${userId}_$senderId';
        final lastNotifiedTime = prefs.getString(prefKey);

        // If not notified yet or this message is newer
        if (lastNotifiedTime != createdAt) {
          final displayBody = count > 1 ? '$lastMessage ($countটি নতুন বার্তা)' : lastMessage;
          final titlePrefix = (item['senderRole'] == 'VET') ? 'ডাঃ $senderName (পশু চিকিৎসক)' : senderName;

          await NotificationService().showChatNotification(
            senderId: senderId,
            senderName: titlePrefix,
            message: displayBody,
          );

          await prefs.setString(prefKey, createdAt);
          debugPrint('[ChatNotificationSync] Pushed notification for sender $senderName: $displayBody');
        }
      }
    } catch (e) {
      debugPrint('[ChatNotificationSync] Error syncing unread messages: $e');
    } finally {
      _isSyncing = false;
    }
  }
}
