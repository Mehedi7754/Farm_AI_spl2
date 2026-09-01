import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../network/api_client.dart';
import 'notification_service.dart';

class ChatNotificationSyncService {
  /// Called upon login, splash auto-login, or dashboard init.
  /// Checks for unread messages and pushes Android system-panel notifications.
  static Future<void> syncUnreadMessages([String? customUserId]) async {
    try {
      // Ensure NotificationService is initialized
      await NotificationService().initialize();

      final user = ApiClient.currentUser;
      final userId = customUserId ?? user?['id']?.toString();

      if (userId == null || userId.isEmpty) {
        debugPrint('[ChatNotificationSync] No userId — skipping.');
        return;
      }

      debugPrint('[ChatNotificationSync] Syncing unread messages for user: $userId');
      final unreadSummary = await ApiClient.getUnreadChatSummary(userId);
      debugPrint('[ChatNotificationSync] Got ${unreadSummary.length} unread sender(s).');

      if (unreadSummary.isEmpty) return;

      final prefs = await SharedPreferences.getInstance();

      for (final item in unreadSummary) {
        if (item is! Map) continue;

        final senderId = item['senderId']?.toString() ?? '';
        final senderName = item['senderName']?.toString() ?? 'ব্যবহারকারী';
        final lastMessage = item['lastMessage']?.toString() ?? '';
        final lastMessageId = item['lastMessageId']?.toString() ?? '';
        final count = (item['count'] is int) ? item['count'] as int : 
                      int.tryParse(item['count']?.toString() ?? '1') ?? 1;

        if (senderId.isEmpty || lastMessage.isEmpty) continue;

        // Dedup key: use lastMessageId — fires only when there's a NEW message
        final prefKey = 'chat_last_notified_msgid_${userId}_$senderId';
        final lastNotifiedMsgId = prefs.getString(prefKey);

        debugPrint('[ChatNotificationSync] Sender: $senderName | lastMsgId: $lastMessageId | stored: $lastNotifiedMsgId');

        if (lastMessageId.isNotEmpty && lastMessageId == lastNotifiedMsgId) {
          // Already notified for this message
          debugPrint('[ChatNotificationSync] Already notified — skipping $senderName');
          continue;
        }

        // Build notification content
        final displayBody = count > 1
            ? '$lastMessage  ($count টি নতুন বার্তা)'
            : lastMessage;

        final String titleDisplay;
        final senderRole = item['senderRole']?.toString() ?? '';
        if (senderRole == 'VET') {
          titleDisplay = 'ডাঃ $senderName';
        } else {
          titleDisplay = senderName;
        }

        debugPrint('[ChatNotificationSync] Pushing notification: "$titleDisplay" → "$displayBody"');

        await NotificationService().showChatNotification(
          senderId: senderId,
          senderName: titleDisplay,
          message: displayBody,
        );

        // Store the lastMessageId so we don't re-notify for the same message
        if (lastMessageId.isNotEmpty) {
          await prefs.setString(prefKey, lastMessageId);
        }
      }
    } catch (e, st) {
      debugPrint('[ChatNotificationSync] ERROR: $e\n$st');
    }
  }

  /// Clear stored notification state for a sender (call when user opens chat with them)
  static Future<void> markSenderAsRead(String userId, String senderId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'chat_last_notified_msgid_${userId}_$senderId';
      // We don't delete — we don't want to re-notify same message if user re-logins
      // The backend marks messages isRead=true when getChatHistory is called
      debugPrint('[ChatNotificationSync] Marked sender $senderId as read for user $userId');
    } catch (_) {}
  }
}
