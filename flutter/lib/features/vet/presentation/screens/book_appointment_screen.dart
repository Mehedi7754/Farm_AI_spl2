import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/time_utils.dart';

class BookAppointmentScreen extends StatefulWidget {
  final String vetId;
  final Map<String, dynamic>? vetData;

  const BookAppointmentScreen({super.key, required this.vetId, this.vetData});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _slots = [];
  String? _selectedSlotId;
  bool _isLoadingSlots = false;
  bool _isBooking = false;
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSlots();
  }

  Future<void> _loadSlots() async {
    setState(() { _isLoadingSlots = true; _selectedSlotId = null; });
    try {
      final dateStr = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
      final data = await ApiClient.getVetSlots(vetId: widget.vetId, date: dateStr);
      if (mounted) setState(() { _slots = List<Map<String, dynamic>>.from(data); _isLoadingSlots = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoadingSlots = false);
    }
  }

  Future<void> _book() async {
    if (_selectedSlotId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('একটি সময়স্লট নির্বাচন করুন'), backgroundColor: Color(0xFFDC2626)));
      return;
    }
    setState(() => _isBooking = true);
    try {
      final user = ApiClient.currentUser;
      await ApiClient.bookAppointment(
        farmerId: user?['id'] ?? '',
        vetId: widget.vetId,
        slotId: _selectedSlotId!,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('অ্যাপয়েন্টমেন্ট সফলভাবে বুক হয়েছে! চিকিৎসক নিশ্চিত করলে আপনাকে জানানো হবে।'),
          backgroundColor: Color(0xFF059669),
          duration: Duration(seconds: 4),
        ));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isBooking = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('বুকিং ব্যর্থ: $e'), backgroundColor: const Color(0xFFDC2626)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vetData = widget.vetData ?? {};
    final user = vetData['user'] as Map<String, dynamic>? ?? {};
    final vetName = user['name'] ?? 'ডাক্তার';
    final spec = vetData['specialization'] ?? '';
    final fee = (vetData['consultationFee'] ?? 0).toDouble();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('অ্যাপয়েন্টমেন্ট বুক করুন', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Vet summary card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF1565C0), Color(0xFF1976D2)]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(children: [
                CircleAvatar(
                  radius: 28, backgroundColor: Colors.white.withOpacity(0.2),
                  child: Text(vetName[0], style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 14),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Dr. $vetName', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(spec, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  Text('পরামর্শ ফি: ৳${fee.toInt()}', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                ]),
              ]),
            ),
            const SizedBox(height: 20),

            // Date picker
            const Text('তারিখ নির্বাচন করুন', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            const SizedBox(height: 8),
            SizedBox(
              height: 70,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 14,
                itemBuilder: (_, i) {
                  final date = DateTime.now().add(Duration(days: i));
                  final isSelected = date.year == _selectedDate.year && date.month == _selectedDate.month && date.day == _selectedDate.day;
                  final weekDays = ['সোম', 'মঙ্গল', 'বুধ', 'বৃহস্পতি', 'শুক্র', 'শনি', 'রবি'];
                  final months = ['জান', 'ফেব', 'মার্চ', 'এপ্রিল', 'মে', 'জুন', 'জুলাই', 'আগ', 'সেপ্ট', 'অক্ট', 'নভ', 'ডিস'];
                  return GestureDetector(
                    onTap: () { setState(() => _selectedDate = date); _loadSlots(); },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 58, margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF1565C0) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isSelected ? const Color(0xFF1565C0) : const Color(0xFFE2E8F0)),
                      ),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text(weekDays[date.weekday - 1], style: TextStyle(fontSize: 10, color: isSelected ? Colors.white70 : const Color(0xFF94A3B8))),
                        Text('${date.day}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : const Color(0xFF1E293B))),
                        Text(months[date.month - 1], style: TextStyle(fontSize: 10, color: isSelected ? Colors.white70 : const Color(0xFF94A3B8))),
                      ]),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Time slots
            const Text('সময় স্লট নির্বাচন করুন', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            const SizedBox(height: 8),
            if (_isLoadingSlots)
              const Center(child: CircularProgressIndicator(color: Color(0xFF1565C0)))
            else if (_slots.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: const Row(children: [
                  Icon(Icons.event_busy_rounded, color: Color(0xFF94A3B8)),
                  SizedBox(width: 10),
                  Text('এই তারিখে কোনো স্লট নেই', style: TextStyle(color: Color(0xFF94A3B8))),
                ]),
              )
            else
              Wrap(
                spacing: 10, runSpacing: 10,
                children: _slots.map((slot) {
                  final id = slot['id'];
                  final isBooked = slot['isBooked'] == true;
                  final isSelected = id == _selectedSlotId;
                  return GestureDetector(
                    onTap: isBooked ? null : () => setState(() => _selectedSlotId = id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isBooked
                            ? Colors.grey.shade100
                            : isSelected
                                ? const Color(0xFF1565C0)
                                : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isBooked
                              ? Colors.grey.shade200
                              : isSelected
                                  ? const Color(0xFF1565C0)
                                  : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Text(
                        '${TimeUtils.formatAmPm(slot['startTime'])} - ${TimeUtils.formatAmPm(slot['endTime'])}' + (isBooked ? ' (বুকড)' : ''),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isBooked
                              ? Colors.grey.shade400
                              : isSelected
                                  ? Colors.white
                                  : const Color(0xFF1E293B),
                          decoration: isBooked ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 20),

            // Notes
            const Text('অসুস্থতার বিবরণ (ঐচ্ছিক)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'যেমন: গাভীর ৩ দিন ধরে জ্বর ও খাবারে অনীহা...',
                hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                filled: true, fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1565C0))),
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton.icon(
                onPressed: _isBooking ? null : _book,
                icon: _isBooking ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.check_circle_rounded, size: 20),
                label: Text(_isBooking ? 'বুক হচ্ছে...' : 'অ্যাপয়েন্টমেন্ট নিশ্চিত করুন', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0), foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() { _notesController.dispose(); super.dispose(); }
}
