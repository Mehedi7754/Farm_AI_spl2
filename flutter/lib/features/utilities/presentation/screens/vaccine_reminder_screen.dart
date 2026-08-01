import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../../../animals/presentation/providers/livestock_provider.dart';

class VaccineReminderScreen extends ConsumerStatefulWidget {
  const VaccineReminderScreen({super.key});

  @override
  ConsumerState<VaccineReminderScreen> createState() => _VaccineReminderScreenState();
}

class _VaccineReminderScreenState extends ConsumerState<VaccineReminderScreen> {
  late FlutterLocalNotificationsPlugin _notificationsPlugin;
  bool _isNotificationInitialized = false;

  String _selectedCattle = 'সকল গবাদিপশু (All Cattle)';

  List<Map<String, dynamic>> _reminders = [];

  static const String _prefKey = 'vaccine_reminders_v1';

  @override
  void initState() {
    super.initState();
    _initNotifications();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefKey);
      if (raw != null) {
        final decoded = jsonDecode(raw) as List<dynamic>;
        if (mounted) {
          setState(() {
            _reminders = decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
            // Restore Color objects (stored as int)
            for (var r in _reminders) {
              if (r['colorValue'] != null) {
                r['color'] = Color(r['colorValue'] as int);
              } else {
                r['color'] = const Color(0xFF059669);
              }
              if (r['isCompleted'] == null) r['isCompleted'] = false;
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Load reminders error: $e');
    }
  }

  Future<void> _saveReminders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Serialize: Colors are not JSON serializable, store as int
      final serializable = _reminders.map((r) {
        final copy = Map<String, dynamic>.from(r);
        copy['colorValue'] = (r['color'] as Color?)?.value;
        copy.remove('color');
        return copy;
      }).toList();
      await prefs.setString(_prefKey, jsonEncode(serializable));
    } catch (e) {
      debugPrint('Save reminders error: $e');
    }
  }

  void _initNotifications() async {
    _notificationsPlugin = FlutterLocalNotificationsPlugin();
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    try {
      tz_data.initializeTimeZones();
      await _notificationsPlugin.initialize(settings: initSettings);

      // Request system notification permission explicitly
      try {
        await Permission.notification.request();
      } catch (_) {}
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();

      if (mounted) setState(() => _isNotificationInitialized = true);
    } catch (e) {
      debugPrint('Notification init error: $e');
    }
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    DateTime? scheduledTime,
  }) async {
    if (!_isNotificationInitialized) return;

    const androidDetails = AndroidNotificationDetails(
      'vaccine_channel',
      'Vaccine Reminders',
      channelDescription: 'Farm AI Vaccine and Deworming Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);

    try {
      if (scheduledTime != null && scheduledTime.isAfter(DateTime.now())) {
        // Schedule at the user-selected future time
        final tzTime = tz.TZDateTime.from(scheduledTime, tz.local);
        await _notificationsPlugin.zonedSchedule(
          id: id,
          title: title,
          body: body,
          scheduledDate: tzTime,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
                  );
      } else {
        // Fire immediately if time is in the past or not provided
        await _notificationsPlugin.show(
          id: id,
          title: title,
          body: body,
          notificationDetails: details,
        );
      }
    } catch (e) {
      debugPrint('Notification schedule error: $e');
    }
  }

  List<String> _buildRealCattleOptions(List<dynamic> realCattleList) {
    final List<String> options = ['সকল গবাদিপশু (All Cattle)'];
    for (var c in realCattleList) {
      final name = (c['name'] ?? 'গবাদিপশু').toString();
      final tag = (c['collarId'] ?? c['tagId'] ?? c['id'] ?? 'আনবাইন্ড').toString();
      options.add('$name [$tag]');
    }
    return options;
  }

  void _showAddVaccineModal(List<String> cattleOptions) {
    final titleCtrl = TextEditingController();
    DateTime? selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay? selectedTime = const TimeOfDay(hour: 10, minute: 0);
    DateTime? selectedNextBoosterDate = DateTime.now().add(const Duration(days: 60));

    String modalSelectedCattle = cattleOptions.length > 1
        ? cattleOptions[1]
        : (_selectedCattle == 'সকল গবাদিপশু (All Cattle)' ? 'সকল গবাদিপশু (All Cattle)' : _selectedCattle);

    String vaccineType = 'টিকা';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final formattedScheduleDate = selectedDate != null && selectedTime != null
                ? '${DateFormat('dd MMMM, yyyy').format(selectedDate!)} - ${selectedTime!.format(context)}'
                : 'তারিখ ও সময় নির্বাচন করুন';

            final formattedNextBooster = selectedNextBoosterDate != null
                ? DateFormat('dd MMMM, yyyy').format(selectedNextBoosterDate!)
                : 'পরবর্তী বুস্টার ডোজের তারিখ (ঐচ্ছিক)';

            final availableModalCattle = cattleOptions.length > 1
                ? cattleOptions.where((opt) => opt != 'সকল গবাদিপশু (All Cattle)').toList()
                : ['নতুন গবাদিপশু [স্বয়ংক্রিয়]'];

            if (!availableModalCattle.contains(modalSelectedCattle)) {
              modalSelectedCattle = availableModalCattle.first;
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                top: 20,
                left: 18,
                right: 18,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'নতুন টিকা সিডিউল যুক্ত করুন 💉',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Real Cattle Selector
                    const Text('রিয়েল গবাদিপশু নির্বাচন করুন (Cattle Management API)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: modalSelectedCattle,
                          isExpanded: true,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          items: availableModalCattle.map((opt) {
                            return DropdownMenuItem(value: opt, child: Text(opt));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setModalState(() => modalSelectedCattle = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Vaccine Type Selector
                    Row(
                      children: ['টিকা', 'কৃমিনাশক', 'ভিটামিন'].map((t) {
                        final isSel = vaccineType == t;
                        return GestureDetector(
                          onTap: () => setModalState(() => vaccineType = t),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSel ? const Color(0xFF059669) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              t,
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isSel ? Colors.white : const Color(0xFF64748B)),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),

                    _buildInputField('টিকা বা ওষুধের নাম', titleCtrl, 'যেমন: খুরা রোগ (FMD) ৩য় ডোজ'),
                    const SizedBox(height: 12),

                    // Date & Time Picker Field
                    const Text('টিকা প্রদানের তারিখ ও সময় (Schedule Date & Time)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: selectedDate ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2030),
                        );
                        if (pickedDate != null && mounted) {
                          final pickedTime = await showTimePicker(
                            context: context,
                            initialTime: selectedTime ?? TimeOfDay.now(),
                          );
                          setModalState(() {
                            selectedDate = pickedDate;
                            if (pickedTime != null) selectedTime = pickedTime;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF059669)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, size: 18, color: Color(0xFF059669)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                formattedScheduleDate,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                              ),
                            ),
                            const Icon(Icons.access_time_rounded, size: 18, color: Color(0xFF059669)),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Next Booster Reminder Date Picker
                    const Text('পরবর্তী বুস্টার ডোজের তারিখ (Next Booster Reminder Date)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () async {
                        final pickedNextDate = await showDatePicker(
                          context: context,
                          initialDate: selectedNextBoosterDate ?? DateTime.now().add(const Duration(days: 60)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2030),
                        );
                        if (pickedNextDate != null) {
                          setModalState(() {
                            selectedNextBoosterDate = pickedNextDate;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF3B82F6)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.event_repeat_rounded, size: 18, color: Color(0xFF2563EB)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                formattedNextBooster,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (titleCtrl.text.isNotEmpty) {
                            final cattleName = modalSelectedCattle.split(' [')[0];
                            final collarCode = modalSelectedCattle.contains('[') ? modalSelectedCattle.split('[')[1].replaceAll(']', '') : 'আনবাইন্ড';
                            final reminderId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

                            setState(() {
                              _reminders.insert(0, {
                                'id': '$reminderId',
                                'title': titleCtrl.text,
                                'cattle': cattleName,
                                'collar': collarCode,
                                'date': formattedScheduleDate,
                                'nextBooster': formattedNextBooster,
                                'isCompleted': false,
                                'type': vaccineType,
                                'color': vaccineType == 'কৃমিনাশক' ? const Color(0xFFD97706) : const Color(0xFF059669),
                              });
                            });
                            // Persist reminders to SharedPreferences
                            _saveReminders();

                            // Schedule notification at the user-chosen date/time
                            final schedDT = selectedDate != null && selectedTime != null
                                ? DateTime(
                                    selectedDate!.year, selectedDate!.month, selectedDate!.day,
                                    selectedTime!.hour, selectedTime!.minute,
                                  )
                                : null;
                            _scheduleNotification(
                              id: reminderId,
                              title: '🔔 ফার্ম ভেক্সিন রিমাইন্ডার: ${titleCtrl.text}',
                              body: '$cattleName এর জন্য $formattedScheduleDate এ টিকা দেওয়ার সময় হয়েছে।',
                              scheduledTime: schedDT,
                            );

                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('$cattleName এর জন্য ${titleCtrl.text} সিডিউল ও নোটিফিকেশন সেট হয়েছে 🔔'),
                                backgroundColor: const Color(0xFF059669),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF059669),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 18),
                        label: const Text('সিডিউল ও নোটিফিকেশন সেট করুন', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
          ),
        ),
      ],
    );
  }

  void _deleteReminder(String id) {
    // Cancel the scheduled notification for this reminder
    final idInt = int.tryParse(id);
    if (idInt != null) {
      _notificationsPlugin.cancel(id: idInt);
    }
    setState(() {
      _reminders.removeWhere((r) => r['id'] == id);
    });
    // Persist the updated list
    _saveReminders();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('টিকা সিডিউল মুছে ফেলা হয়েছে')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncLivestock = ref.watch(livestockProvider);

    return asyncLivestock.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('টিকা ও ডিনোমিং ড্যাশবোর্ড'), backgroundColor: const Color(0xFF059669)),
        body: const Center(child: CircularProgressIndicator(color: Color(0xFF059669))),
      ),
      error: (err, stack) => Scaffold(
        appBar: AppBar(title: const Text('টিকা ও ডিনোমিং ড্যাশবোর্ড'), backgroundColor: const Color(0xFF059669)),
        body: Center(child: Text('ডেটা লোড করতে সমস্যা হয়েছে: $err')),
      ),
      data: (realCattleList) {
        final cattleOptions = _buildRealCattleOptions(realCattleList);

        if (!cattleOptions.contains(_selectedCattle)) {
          _selectedCattle = cattleOptions.first;
        }

        final filteredReminders = _reminders.where((r) {
          if (_selectedCattle == 'সকল গবাদিপশু (All Cattle)') return true;
          final cattleNameOnly = _selectedCattle.split(' [')[0];
          return r['cattle'].toString().contains(cattleNameOnly);
        }).toList();

        final completedCount = filteredReminders.where((r) => r['isCompleted'] as bool).length;
        final totalCount = filteredReminders.length;
        final pendingCount = totalCount - completedCount;
        final progressVal = totalCount == 0 ? 0.0 : completedCount / totalCount;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: const Color(0xFF059669),
            elevation: 0,
            toolbarHeight: 64,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'টিকা ও ডিনোমিং ড্যাশবোর্ড',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white),
                ),
                Text(
                  'রিয়েল এপিআই: ${realCattleList.length} টি নিবন্ধিত গবাদিপশু',
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.add_circle_rounded, color: Colors.white, size: 24),
                onPressed: () => _showAddVaccineModal(cattleOptions),
              ),
            ],
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. KPI PERFORMANCE CARDS GRID
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.55,
                  children: [
                    _buildKpiCard(
                      title: 'টিকাদান অগ্রগতি',
                      value: '${(progressVal * 100).toInt()}%',
                      subtitle: '$completedCount/$totalCount টি ডোজ সম্পন্ন',
                      icon: Icons.health_and_safety_rounded,
                      color: const Color(0xFF059669),
                    ),
                    _buildKpiCard(
                      title: 'আসন্ন বকেয়া টিকা',
                      value: '$pendingCount টি',
                      subtitle: 'জরুরি নোটিফিকেশন সক্রিয়',
                      icon: Icons.notifications_active_rounded,
                      color: const Color(0xFFD97706),
                    ),
                    _buildKpiCard(
                      title: 'নিবন্ধিত গবাদিপশু',
                      value: '${realCattleList.length} টি',
                      subtitle: 'Cattle Management API',
                      icon: Icons.pets_rounded,
                      color: const Color(0xFF2563EB),
                    ),
                    _buildKpiCard(
                      title: 'পরবর্তী বুস্টার সূচি',
                      value: '৬০ দিন',
                      subtitle: 'বুস্টার ডেট নির্ধারিত',
                      icon: Icons.event_repeat_rounded,
                      color: const Color(0xFF7C3AED),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // 2. REAL CATTLE SELECTOR DROPDOWN CARD
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.filter_alt_rounded, size: 16, color: Color(0xFF059669)),
                          SizedBox(width: 6),
                          Text(
                            'রিয়েল গবাদিপশু ফিল্টার (API Source):',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedCattle,
                            isExpanded: true,
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF059669)),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            items: cattleOptions.map((opt) {
                              return DropdownMenuItem(value: opt, child: Text(opt));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedCattle = val);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // 3. REMINDERS LIST
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'ভ্যাকসিন ও বুস্টার সিডিউল',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF0F172A)),
                    ),
                    Text(
                      '${filteredReminders.length} টি সিডিউল',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                filteredReminders.isEmpty
                    ? Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.event_available_rounded, size: 40, color: Color(0xFFCBD5E1)),
                            const SizedBox(height: 10),
                            Text(
                              realCattleList.isEmpty
                                  ? 'ক্যাটল ম্যানেজমেন্টে কোনো গবাদিপশু যুক্ত করা নেই। "গবাদিপশু ব্যবস্থাপনা" স্ক্রিন থেকে প্রাণী যুক্ত করুন।'
                                  : 'এই গবাদিপশুর জন্য কোনো টিকা সিডিউল দেওয়া নেই',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredReminders.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final r = filteredReminders[index];
                          final isDone = r['isCompleted'] as bool;
                          final color = r['color'] as Color;

                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          r['isCompleted'] = !isDone;
                                        });
                                      },
                                      child: Icon(
                                        isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                        color: isDone ? const Color(0xFF059669) : const Color(0xFF94A3B8),
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            r['title'] as String,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w800,
                                              color: isDone ? const Color(0xFF94A3B8) : const Color(0xFF0F172A),
                                              decoration: isDone ? TextDecoration.lineThrough : null,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            '${r['cattle']} (${r['collar']})',
                                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        r['type'] as String,
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 18),
                                      onPressed: () => _deleteReminder(r['id'] as String),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                                const SizedBox(height: 8),

                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.alarm_rounded, size: 14, color: Color(0xFF059669)),
                                        const SizedBox(width: 4),
                                        Text(
                                          'সময়: ${r['date']}',
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                                        ),
                                      ],
                                    ),
                                    if (r['nextBooster'] != null)
                                      Row(
                                        children: [
                                          const Icon(Icons.event_repeat_rounded, size: 14, color: Color(0xFF2563EB)),
                                          const SizedBox(width: 4),
                                          Text(
                                            'পরবর্তী ডোজ: ${r['nextBooster']}',
                                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
              ),
              Icon(icon, size: 18, color: color),
            ],
          ),
          Text(
            value,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color),
          ),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }
}
