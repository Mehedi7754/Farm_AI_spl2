import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/notification_store.dart';
import '../../../../core/services/notification_service.dart';

// Icon & color helpers by type
IconData _typeIcon(String type) {
  switch (type) {
    case 'weather':
      return Icons.cloud_sync_rounded;
    case 'chat':
      return Icons.chat_bubble_rounded;
    case 'reminder':
      return Icons.vaccines_rounded;
    case 'call':
      return Icons.video_call_rounded;
    case 'milk':
      return Icons.local_drink_rounded;
    default:
      return Icons.notifications_rounded;
  }
}

Color _typeColor(String type) {
  switch (type) {
    case 'weather':
      return const Color(0xFF0284C7);
    case 'chat':
      return const Color(0xFF1565C0);
    case 'reminder':
      return const Color(0xFF9333EA);
    case 'call':
      return const Color(0xFFBE185D);
    case 'milk':
      return const Color(0xFF059669);
    default:
      return const Color(0xFF64748B);
  }
}

Color _typeBgColor(String type) {
  switch (type) {
    case 'weather':
      return const Color(0xFFE0F2FE);
    case 'chat':
      return const Color(0xFFEFF6FF);
    case 'reminder':
      return const Color(0xFFF3E8FF);
    case 'call':
      return const Color(0xFFFCE7F3);
    case 'milk':
      return const Color(0xFFD1FAE5);
    default:
      return const Color(0xFFF1F5F9);
  }
}

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final _store = NotificationStore();
  String _selectedFilter = 'সকল';

  @override
  void initState() {
    super.initState();
    // Listen to store changes
    _store.unreadCountNotifier.addListener(_onStoreChanged);
  }

  @override
  void dispose() {
    _store.unreadCountNotifier.removeListener(_onStoreChanged);
    super.dispose();
  }

  void _onStoreChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _markAllAsRead() async {
    await _store.markAllRead();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('সকল নোটিফিকেশন পড়া হয়েছে হিসেবে চিহ্নিত ✉️'),
        backgroundColor: Color(0xFF064E3B),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final all = _store.all;
    final unreadCount = all.where((n) => !n.isRead).length;
    final filtered = _selectedFilter == 'অপঠিত'
        ? all.where((n) => !n.isRead).toList()
        : all;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: AppBar(
          backgroundColor: const Color(0xFF064E3B),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          title: const Text(
            'নোটিফিকেশন সেন্টার',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.notification_add_rounded, size: 20, color: Color(0xFFFDE047)),
              tooltip: 'টেস্ট চ্যাট নোটিফিকেশন পাঠান',
              onPressed: () async {
                await NotificationService().showTestChatNotification();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('🔔 টেস্ট চ্যাট নোটিফিকেশন পাঠানো হয়েছে! ফোন নোটিফিকেশন প্যানেল চেক করুন।'),
                      backgroundColor: Color(0xFF047857),
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              },
            ),
            if (unreadCount > 0)
              TextButton.icon(
                onPressed: _markAllAsRead,
                icon: const Icon(Icons.done_all_rounded, size: 16, color: Color(0xFFFDE047)),
                label: const Text(
                  'পড়া হয়েছে',
                  style: TextStyle(color: Color(0xFFFDE047), fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Filter Row Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: ['সকল', 'অপঠিত'].map((filter) {
                    final isSel = _selectedFilter == filter;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedFilter = filter),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSel ? const Color(0xFF064E3B) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          filter == 'অপঠিত' ? '$filter ($unreadCount)' : filter,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isSel ? Colors.white : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                Text(
                  'মোট ${filtered.length}টি নোটিফিকেশন',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),

          // Empty state
          if (filtered.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text(
                      _selectedFilter == 'অপঠিত'
                          ? 'কোনো অপঠিত নোটিফিকেশন নেই'
                          : 'কোনো নোটিফিকেশন নেই',
                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'আবহাওয়া আপডেট, চ্যাট ও রিমাইন্ডার এখানে দেখা যাবে',
                      style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            // Notifications List
            Expanded(
              child: ListView.separated(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(14),
                itemCount: filtered.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final n = filtered[index];
                  final isRead = n.isRead;
                  final iconColor = _typeColor(n.type);
                  final bgColor = _typeBgColor(n.type);
                  final icon = _typeIcon(n.type);

                  return GestureDetector(
                    onTap: () async {
                      await _store.markRead(n.id);
                      if (mounted) setState(() {});
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isRead ? Colors.white : const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isRead ? const Color(0xFFCBD5E1) : const Color(0xFFA7F3D0),
                          width: isRead ? 1 : 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: bgColor,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(icon, color: iconColor, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        n.title,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: isRead ? FontWeight.bold : FontWeight.w900,
                                          color: const Color(0xFF0F172A),
                                        ),
                                      ),
                                    ),
                                    Text(
                                      n.time,
                                      style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  n.body,
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.3),
                                ),
                              ],
                            ),
                          ),
                          if (!isRead)
                            Container(
                              margin: const EdgeInsets.only(left: 6, top: 4),
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF059669),
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
