import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final List<Map<String, dynamic>> _notifications = [
    {
      'id': '1',
      'title': 'FMD টিকা রিমাইন্ডার 💉',
      'body': 'গাভী নং ৩ (লালমনি) এর খুরা রোগের ২য় ডোজ টিকা দিতে হবে আগামীকাল সকাল ১০:০০ টায়।',
      'time': '১০ মিনিট আগে',
      'type': 'vaccine',
      'isRead': false,
      'color': const Color(0xFF9333EA),
      'bgColor': const Color(0xFFF3E8FF),
      'icon': Icons.vaccines_rounded,
    },
    {
      'id': '2',
      'title': 'স্মার্ট কলার লো-ব্যাটারি 🔋',
      'body': 'স্মার্ট কলার #১০২ (গাভী নং ১) এর চার্জ ১৫% এ নেমে এসেছে। চার্জার সংযোগ দিন।',
      'time': '১ ঘণ্টা আগে',
      'type': 'collar',
      'isRead': false,
      'color': const Color(0xFFDC2626),
      'bgColor': const Color(0xFFFEE2E2),
      'icon': Icons.battery_alert_rounded,
    },
    {
      'id': '3',
      'title': 'ভারী বৃষ্টিপাতের সতর্কতা 🌧️',
      'body': 'বগুড়া অঞ্চলে আজ বিকেলে ভারী বৃষ্টিপাতের সম্ভাবনা। পশুকে শেডের ভেতরে রাখুন।',
      'time': '৩ ঘণ্টা আগে',
      'type': 'weather',
      'isRead': true,
      'color': const Color(0xFF0284C7),
      'bgColor': const Color(0xFFE0F2FE),
      'icon': Icons.cloud_sync_rounded,
    },
    {
      'id': '4',
      'title': 'দুধ উৎপাদন রেকর্ড! 🥛',
      'body': 'গতকাল রহিম ফার্মের মোট দুধ উৎপাদন ২৮ লিটারে উন্নীত হয়েছে (১৫% বৃদ্ধি)।',
      'time': 'গতকাল',
      'type': 'milk',
      'isRead': true,
      'color': const Color(0xFF059669),
      'bgColor': const Color(0xFFD1FAE5),
      'icon': Icons.trending_up_rounded,
    },
    {
      'id': '5',
      'title': 'ভেটেরিনারি ডাক্তারের অ্যাপয়েন্টমেন্ট 🩺',
      'body': 'ডাঃ মোঃ রফিকুল ইসলামের সাথে আগামী পরশু বেলা ৩:০০ টায় ভিডিও কল বুকড।',
      'time': '২ দিন আগে',
      'type': 'doctor',
      'isRead': true,
      'color': const Color(0xFFDB2777),
      'bgColor': const Color(0xFFFCE7F3),
      'icon': Icons.medical_services_rounded,
    },
  ];

  String _selectedFilter = 'সকল';

  void _markAllAsRead() {
    setState(() {
      for (var n in _notifications) {
        n['isRead'] = true;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('সকল নোটিফিকেশন পড়া হয়েছে হিসেবে চিহ্নিত ✉️'),
        backgroundColor: Color(0xFF064E3B),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n['isRead']).length;
    final filtered = _notifications.where((n) {
      if (_selectedFilter == 'অপঠিত') return !n['isRead'];
      return true;
    }).toList();

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
            if (unreadCount > 0)
              TextButton.icon(
                onPressed: _markAllAsRead,
                icon: const Icon(Icons.done_all_rounded, size: 16, color: Color(0xFFFDE047)),
                label: const Text(
                  'পড়া হয়েছে',
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

          // Notifications List
          Expanded(
            child: ListView.separated(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(14),
              itemCount: filtered.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final n = filtered[index];
                final isRead = n['isRead'] as bool;
                final bgColor = n['bgColor'] as Color;
                final iconColor = n['color'] as Color;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      n['isRead'] = true;
                    });
                  },
                  child: Container(
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
                          child: Icon(n['icon'] as IconData, color: iconColor, size: 22),
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
                                      n['title'] as String,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: isRead ? FontWeight.bold : FontWeight.w900,
                                        color: const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    n['time'] as String,
                                    style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                n['body'] as String,
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
