import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/time_utils.dart';

class VetSlotsScreen extends StatefulWidget {
  const VetSlotsScreen({super.key});

  @override
  State<VetSlotsScreen> createState() => _VetSlotsScreenState();
}

class _VetSlotsScreenState extends State<VetSlotsScreen> {
  List<dynamic> _allSlots = [];
  bool _isLoading = true;
  int _selectedDayFilterIndex = 0; // 0 = All, 1..7 = Next 7 Days

  final List<DateTime> _weekDays = List.generate(7, (i) => DateTime.now().add(Duration(days: i)));

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final user = ApiClient.currentUser;
      if (user != null) {
        final vetId = user['id'];
        final slots = await ApiClient.getVetSlots(vetId: vetId);
        if (mounted) {
          setState(() {
            _allSlots = slots;
            _isLoading = false;
          });
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<dynamic> get _filteredSlots {
    if (_selectedDayFilterIndex == 0) return _allSlots;
    final targetDate = _weekDays[_selectedDayFilterIndex - 1];
    final targetStr = "${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}";
    return _allSlots.where((s) {
      final d = s['date']?.toString().split('T')[0];
      return d == targetStr;
    }).toList();
  }

  Future<void> _deleteSlot(String slotId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('স্লট মুছে ফেলবেন?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: const Text('আপনি কি নিশ্চিত যে এই সময়সূচিটি মুছে ফেলতে চান?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('বাতিল')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
            child: const Text('মুছে ফেলুন'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ApiClient.deleteVetSlot(slotId);
        _load();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('স্লট মুছে ফেলা হয়েছে'), backgroundColor: Color(0xFF16A34A)),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('মুছে ফেলা ব্যর্থ: $e'), backgroundColor: const Color(0xFFDC2626)),
          );
        }
      }
    }
  }

  void _showEditSlotModal(Map<String, dynamic> slot) {
    final slotId = slot['id'];
    DateTime selectedDate = DateTime.tryParse(slot['date'] ?? '') ?? DateTime.now();
    
    // Parse time
    TimeOfDay parseTime(String? tStr) {
      if (tStr == null) return const TimeOfDay(hour: 10, minute: 0);
      final parts = tStr.split(':');
      return TimeOfDay(hour: int.tryParse(parts[0]) ?? 10, minute: int.tryParse(parts[1]) ?? 0);
    }

    TimeOfDay startTime = parseTime(slot['startTime']);
    TimeOfDay endTime = parseTime(slot['endTime']);
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final dateStr = "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";
          final start24 = "${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}";
          final end24 = "${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}";

          return Padding(
            padding: EdgeInsets.only(
              left: 20, right: 20, top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('সময়সূচি সম্পাদন (Edit Slot)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                const SizedBox(height: 16),

                ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: Color(0xFFCBD5E1))),
                  leading: const Icon(Icons.calendar_month_rounded, color: Color(0xFF1565C0)),
                  title: const Text('তারিখ', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  subtitle: Text(dateStr, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 60)),
                    );
                    if (picked != null) setModalState(() => selectedDate = picked);
                  },
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: Color(0xFFCBD5E1))),
                        title: const Text('শুরুর সময়', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        subtitle: Text(TimeUtils.formatTimeOfDay(startTime), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
                        onTap: () async {
                          final picked = await showTimePicker(context: context, initialTime: startTime);
                          if (picked != null) setModalState(() => startTime = picked);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ListTile(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: Color(0xFFCBD5E1))),
                        title: const Text('শেষের সময়', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        subtitle: Text(TimeUtils.formatTimeOfDay(endTime), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
                        onTap: () async {
                          final picked = await showTimePicker(context: context, initialTime: endTime);
                          if (picked != null) setModalState(() => endTime = picked);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: isSaving ? null : () async {
                      setModalState(() => isSaving = true);
                      try {
                        await ApiClient.updateVetSlot(slotId, startTime: start24, endTime: end24, date: dateStr);
                        if (mounted) {
                          Navigator.pop(ctx);
                          _load();
                        }
                      } catch (e) {
                        if (mounted) setModalState(() => isSaving = false);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: isSaving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('আপডেট নিশ্চিত করুন', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAddSlotModal() {
    int mode = 0; // 0 = Single, 1 = Multi/Bulk
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    
    // Multi mode variables
    TimeOfDay bulkStart = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay bulkEnd = const TimeOfDay(hour: 13, minute: 0);
    int durationMinutes = 30;
    List<Map<String, String>> generatedSlots = [];

    // Single mode variables
    TimeOfDay singleStart = const TimeOfDay(hour: 10, minute: 0);
    TimeOfDay singleEnd = const TimeOfDay(hour: 10, minute: 30);

    bool isSaving = false;

    void updateGeneratedSlots() {
      generatedSlots.clear();
      int startMins = bulkStart.hour * 60 + bulkStart.minute;
      int endMins = bulkEnd.hour * 60 + bulkEnd.minute;

      final dateStr = "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";

      while (startMins + durationMinutes <= endMins) {
        int nextMins = startMins + durationMinutes;
        String sHour = (startMins ~/ 60).toString().padLeft(2, '0');
        String sMin = (startMins % 60).toString().padLeft(2, '0');
        String eHour = (nextMins ~/ 60).toString().padLeft(2, '0');
        String eMin = (nextMins % 60).toString().padLeft(2, '0');

        generatedSlots.add({
          'date': dateStr,
          'startTime': "$sHour:$sMin",
          'endTime': "$eHour:$eMin",
        });

        startMins = nextMins;
      }
    }

    updateGeneratedSlots();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final dateStr = "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('নতুন সময়সূচি (Slots)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                      IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Segmented control for mode selection
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setModalState(() => mode = 0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: mode == 0 ? const Color(0xFF1565C0) : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'একক স্লট (Single)',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: mode == 0 ? Colors.white : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setModalState(() {
                                mode = 1;
                                updateGeneratedSlots();
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: mode == 1 ? const Color(0xFF1565C0) : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'একাধিক স্লট তৈরি (Bulk)',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: mode == 1 ? Colors.white : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Common Date Picker
                  ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: Color(0xFFCBD5E1))),
                    leading: const Icon(Icons.calendar_month_rounded, color: Color(0xFF1565C0)),
                    title: const Text('তারিখ নির্ধারণ করুন', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    subtitle: Text(dateStr, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 60)),
                      );
                      if (picked != null) {
                        setModalState(() {
                          selectedDate = picked;
                          if (mode == 1) updateGeneratedSlots();
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 14),

                  Expanded(
                    child: SingleChildScrollView(
                      child: mode == 0
                          ? Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: ListTile(
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: Color(0xFFCBD5E1))),
                                        title: const Text('শুরুর সময়', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                        subtitle: Text(TimeUtils.formatTimeOfDay(singleStart), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
                                        onTap: () async {
                                          final picked = await showTimePicker(context: context, initialTime: singleStart);
                                          if (picked != null) setModalState(() => singleStart = picked);
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: ListTile(
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: Color(0xFFCBD5E1))),
                                        title: const Text('শেষের সময়', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                        subtitle: Text(TimeUtils.formatTimeOfDay(singleEnd), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
                                        onTap: () async {
                                          final picked = await showTimePicker(context: context, initialTime: singleEnd);
                                          if (picked != null) setModalState(() => singleEnd = picked);
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: ListTile(
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: Color(0xFFCBD5E1))),
                                        title: const Text('শিফট শুরু', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                        subtitle: Text(TimeUtils.formatTimeOfDay(bulkStart), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
                                        onTap: () async {
                                          final picked = await showTimePicker(context: context, initialTime: bulkStart);
                                          if (picked != null) {
                                            setModalState(() {
                                              bulkStart = picked;
                                              updateGeneratedSlots();
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: ListTile(
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: Color(0xFFCBD5E1))),
                                        title: const Text('শিফট শেষ', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                        subtitle: Text(TimeUtils.formatTimeOfDay(bulkEnd), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
                                        onTap: () async {
                                          final picked = await showTimePicker(context: context, initialTime: bulkEnd);
                                          if (picked != null) {
                                            setModalState(() {
                                              bulkEnd = picked;
                                              updateGeneratedSlots();
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Duration Picker
                                Row(
                                  children: [
                                    const Text('প্রতিটি স্লটের সময়সীমা: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                                    const Spacer(),
                                    DropdownButton<int>(
                                      value: durationMinutes,
                                      underline: const SizedBox(),
                                      style: const TextStyle(color: Color(0xFF1565C0), fontWeight: FontWeight.bold, fontSize: 13),
                                      items: const [
                                        DropdownMenuItem(value: 15, child: Text('১৫ মিনিট')),
                                        DropdownMenuItem(value: 20, child: Text('২০ মিনিট')),
                                        DropdownMenuItem(value: 30, child: Text('৩০ মিনিট')),
                                        DropdownMenuItem(value: 45, child: Text('৪৫ মিনিট')),
                                        DropdownMenuItem(value: 60, child: Text('১ ঘন্টা')),
                                      ],
                                      onChanged: (val) {
                                        if (val != null) {
                                          setModalState(() {
                                            durationMinutes = val;
                                            updateGeneratedSlots();
                                          });
                                        }
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                Text('অটো-জেনারেটেড স্লটসমূহ (${generatedSlots.length}টি):', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                                const SizedBox(height: 8),

                                Wrap(
                                  spacing: 8, runSpacing: 8,
                                  children: generatedSlots.map((s) {
                                    final startAmPm = TimeUtils.formatAmPm(s['startTime']);
                                    final endAmPm = TimeUtils.formatAmPm(s['endTime']);
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEFF6FF),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: const Color(0xFFBFDBFE)),
                                      ),
                                      child: Text('$startAmPm - $endAmPm', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8))),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: isSaving
                          ? null
                          : () async {
                              setModalState(() => isSaving = true);
                              try {
                                final user = ApiClient.currentUser;
                                if (user != null) {
                                  final vetId = user['id'];
                                  final List<Map<String, String>> slotsToSave = [];

                                  if (mode == 0) {
                                    final s24 = "${singleStart.hour.toString().padLeft(2, '0')}:${singleStart.minute.toString().padLeft(2, '0')}";
                                    final e24 = "${singleEnd.hour.toString().padLeft(2, '0')}:${singleEnd.minute.toString().padLeft(2, '0')}";
                                    slotsToSave.add({'date': dateStr, 'startTime': s24, 'endTime': e24});
                                  } else {
                                    slotsToSave.addAll(generatedSlots);
                                  }

                                  if (slotsToSave.isNotEmpty) {
                                    await ApiClient.createVetSlots(vetId: vetId, slots: slotsToSave);
                                  }
                                }
                                if (mounted) {
                                  Navigator.pop(ctx);
                                  _load();
                                }
                              } catch (e) {
                                if (mounted) setModalState(() => isSaving = false);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1565C0),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: isSaving
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(
                              mode == 0 ? 'স্লট সংরক্ষণ করুন' : 'সবগুলো (${generatedSlots.length}টি) স্লট সংরক্ষণ করুন',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final displaySlots = _filteredSlots;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text('সময়সূচি ব্যবস্থাপনা (Slot Manager)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white, size: 24),
            onPressed: _showAddSlotModal,
          ),
        ],
      ),
      body: Column(
        children: [
          // Weekday Filter Chips Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            child: SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 8, // 0 = All, 1..7 = Next 7 Days
                itemBuilder: (context, index) {
                  final isSelected = index == _selectedDayFilterIndex;
                  String label;
                  if (index == 0) {
                    label = 'সকল স্লট (${_allSlots.length})';
                  } else {
                    final date = _weekDays[index - 1];
                    final weekDaysBn = ['সোম', 'মঙ্গল', 'বুধ', 'বৃহঃ', 'শুক্র', 'শনি', 'রবি'];
                    final dayName = weekDaysBn[date.weekday - 1];
                    label = '$dayName ${date.day}/${date.month}';
                  }

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(label),
                      selected: isSelected,
                      onSelected: (val) {
                        if (val) setState(() => _selectedDayFilterIndex = index);
                      },
                      selectedColor: const Color(0xFF1565C0),
                      backgroundColor: const Color(0xFFF1F5F9),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : const Color(0xFF64748B),
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      showCheckmark: false,
                    ),
                  );
                },
              ),
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF1565C0)))
                : RefreshIndicator(
                    onRefresh: _load,
                    child: displaySlots.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.calendar_today_rounded, size: 48, color: Color(0xFFCBD5E1)),
                                const SizedBox(height: 12),
                                const Text('এই ফিল্টারে কোনো সময়সূচি নেই', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: _showAddSlotModal,
                                  icon: const Icon(Icons.add_rounded),
                                  label: const Text('নতুন স্লট তৈরি করুন'),
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1565C0), foregroundColor: Colors.white),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(14),
                            itemCount: displaySlots.length,
                            itemBuilder: (context, index) {
                              final slot = displaySlots[index];
                              final slotId = slot['id'];
                              final isBooked = slot['isBooked'] == true;
                              final startAmPm = TimeUtils.formatAmPm(slot['startTime']);
                              final endAmPm = TimeUtils.formatAmPm(slot['endTime']);
                              final dateStr = slot['date'] != null ? slot['date'].toString().split('T')[0] : 'আজ';

                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.02),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    )
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: isBooked ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        Icons.access_time_filled_rounded,
                                        color: isBooked ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "$startAmPm - $endAmPm",
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                                          ),
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              const Icon(Icons.calendar_month_outlined, size: 12, color: Color(0xFF94A3B8)),
                                              const SizedBox(width: 4),
                                              Text(
                                                dateStr,
                                                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Actions
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: isBooked ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            isBooked ? 'বুকড' : 'ফ্রি',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: isBooked ? const Color(0xFF991B1B) : const Color(0xFF166534),
                                            ),
                                          ),
                                        ),
                                        if (!isBooked) ...[
                                          IconButton(
                                            icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF1565C0)),
                                            onPressed: () => _showEditSlotModal(slot),
                                            tooltip: 'সম্পাদন করুন',
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFDC2626)),
                                            onPressed: () => _deleteSlot(slotId),
                                            tooltip: 'মুছে ফেলুন',
                                          ),
                                        ]
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}
