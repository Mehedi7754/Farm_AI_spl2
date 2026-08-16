import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/chat_notification_sync_service.dart';
import '../../../../core/services/consultation_manager.dart';

class VetDashboardScreen extends StatefulWidget {
  const VetDashboardScreen({super.key});

  @override
  State<VetDashboardScreen> createState() => _VetDashboardScreenState();
}

class _VetDashboardScreenState extends State<VetDashboardScreen> {
  List<Map<String, dynamic>> _consultations = [];
  bool _isLoading = true;
  bool _isAvailable = true;

  @override
  void initState() {
    super.initState();
    _load();
    ChatNotificationSyncService.syncUnreadMessages();
  }

  Future<void> _load() async {
    try {
      final user = ApiClient.currentUser;
      if (user == null) return;
      final data = await ApiClient.getMyConsultations(userId: user['id'] as String, role: 'VET');
      final filtered = await ConsultationManager.filterConsultations(data);
      if (mounted) {
        setState(() {
          _consultations = filtered;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _upcoming => _consultations
      .where((c) => c['status'] == 'CONFIRMED' || c['status'] == 'PENDING')
      .toList();

  List<Map<String, dynamic>> get _today {
    final now = DateTime.now();
    return _upcoming.where((c) {
      try {
        final slotDateStr = c['slot']?['date'] ?? c['scheduledTime'] ?? '';
        if (slotDateStr.isEmpty) return false;
        final t = DateTime.parse(slotDateStr).toLocal();
        return t.year == now.year && t.month == now.month && t.day == now.day;
      } catch (_) {
        return false;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final user = ApiClient.currentUser;
    final name = user?['name'] ?? 'ডাক্তার';

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Colors.white24,
              child: Icon(Icons.medical_services_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Dr. $name', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                  const Text('ভেটেরিনারি সার্জন', style: TextStyle(color: Colors.white70, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              Switch(
                value: _isAvailable,
                onChanged: (v) => setState(() => _isAvailable = v),
                activeColor: Colors.greenAccent,
                inactiveThumbColor: Colors.grey.shade400,
              ),
              Text(_isAvailable ? 'অনলাইন' : 'অফলাইন',
                  style: TextStyle(color: _isAvailable ? Colors.greenAccent : Colors.white60, fontSize: 10, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 20),
            onPressed: () => context.push('/chat-list'),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 20),
            onPressed: () {
              ApiClient.logout();
              context.go('/login');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: const Color(0xFF1565C0),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stat Cards Row
              Row(
                children: [
                  _statPill('আজকের কল', '${_today.length}', Icons.today_rounded, const Color(0xFF1565C0)),
                  const SizedBox(width: 10),
                  _statPill('অপেক্ষমাণ', '${_upcoming.length}', Icons.pending_actions_rounded, const Color(0xFFD97706)),
                  const SizedBox(width: 10),
                  _statPill('সম্পন্ন', '${_consultations.where((c) => c['status'] == 'COMPLETED').length}', Icons.check_circle_rounded, const Color(0xFF059669)),
                ],
              ),
              const SizedBox(height: 20),

              // Quick Actions Grid
              const Text('দ্রুত অ্যাকশন (Quick Actions)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              const SizedBox(height: 12),
              Row(
                children: [
                  _QuickAction(
                    icon: Icons.calendar_month_rounded,
                    label: 'অ্যাপয়েন্টমেন্ট',
                    color: const Color(0xFF1565C0),
                    onTap: () => context.push('/vet-appointments'),
                  ),
                  const SizedBox(width: 10),
                  _QuickAction(
                    icon: Icons.schedule_rounded,
                    label: 'সময়সূচি সেট',
                    color: const Color(0xFF00796B),
                    onTap: () => context.push('/vet-slots'),
                  ),
                  const SizedBox(width: 10),
                  _QuickAction(
                    icon: Icons.forum_rounded,
                    label: 'কমিউনিটি',
                    color: const Color(0xFF6A1B9A),
                    onTap: () => context.go('/community'),
                  ),
                  const SizedBox(width: 10),
                  _QuickAction(
                    icon: Icons.person_rounded,
                    label: 'প্রোফাইল',
                    color: const Color(0xFFE65100),
                    onTap: () => context.push('/vet-profile'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Today's Appointments Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('আজকের অ্যাপয়েন্টমেন্ট', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  TextButton(
                    onPressed: () => context.push('/vet-appointments'),
                    child: const Text('সব দেখুন', style: TextStyle(color: Color(0xFF1565C0), fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (_isLoading)
                const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: Color(0xFF1565C0))))
              else if (_today.isEmpty)
                _EmptyState(message: 'আজ কোনো নির্ধারিত অ্যাপয়েন্টমেন্ট নেই।')
              else
                ..._today.map((c) => _AppointmentCard(consultation: c, isVet: true, onRefresh: _load)),

              const SizedBox(height: 20),

              // Pending / Upcoming Requests
              const Text('নতুন পরামর্শের অনুরোধ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              const SizedBox(height: 10),

              if (_upcoming.isEmpty && !_isLoading)
                _EmptyState(message: 'কোনো নতুন অনুরোধ নেই।')
              else
                ..._upcoming.take(5).map((c) => _AppointmentCard(consultation: c, isVet: true, onRefresh: _load)),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        backgroundColor: Colors.white,
        elevation: 8,
        onDestinationSelected: (i) {
          switch (i) {
            case 0:
              break;
            case 1:
              context.push('/vet-appointments');
              break;
            case 2:
              context.go('/community');
              break;
            case 3:
              context.push('/vet-profile');
              break;
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_rounded, color: Color(0xFF1565C0)), label: 'ড্যাশবোর্ড'),
          NavigationDestination(icon: Icon(Icons.calendar_month_rounded), label: 'অ্যাপয়েন্টমেন্ট'),
          NavigationDestination(icon: Icon(Icons.forum_rounded), label: 'কমিউনিটি'),
          NavigationDestination(icon: Icon(Icons.person_rounded), label: 'প্রোফাইল'),
        ],
      ),
    );
  }

  Widget _statPill(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 18)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox_rounded, color: Color(0xFF94A3B8), size: 24),
            const SizedBox(width: 10),
            Text(message, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      );
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [BoxShadow(color: color.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 3))],
            ),
            child: Column(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(height: 6),
                Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color), textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      );
}

class _AppointmentCard extends StatelessWidget {
  final Map<String, dynamic> consultation;
  final bool isVet;
  final VoidCallback onRefresh;
  const _AppointmentCard({required this.consultation, required this.isVet, required this.onRefresh});

  String _formatDateTime() {
    try {
      final slot = consultation['slot'] as Map<String, dynamic>?;
      final dateStr = slot?['date'] ?? consultation['scheduledTime'] ?? '';
      if (dateStr.isEmpty) return '';
      final dt = DateTime.parse(dateStr).toLocal();
      final dayStr = '${dt.day}/${dt.month}/${dt.year}';
      if (slot != null && slot['startTime'] != null) {
        return '$dayStr (${slot['startTime']} - ${slot['endTime'] ?? ""})';
      }
      return dayStr;
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = consultation['status'] ?? 'PENDING';
    final farmerName = consultation['farmer']?['name'] ?? 'কৃষক';
    final farmerPhone = consultation['farmer']?['phoneNumber'];
    final vetName = consultation['vet']?['name'] ?? 'ডাক্তার';
    final roomId = consultation['roomId'];
    final timeStr = _formatDateTime();

    Color statusColor;
    String statusLabel;
    switch (status) {
      case 'CONFIRMED':
        statusColor = const Color(0xFF059669);
        statusLabel = 'নিশ্চিত';
        break;
      case 'PENDING':
        statusColor = const Color(0xFFD97706);
        statusLabel = 'অপেক্ষায়';
        break;
      case 'COMPLETED':
        statusColor = const Color(0xFF6366F1);
        statusLabel = 'সম্পন্ন';
        break;
      case 'CANCELLED':
        statusColor = const Color(0xFFDC2626);
        statusLabel = 'বাতিল';
        break;
      default:
        statusColor = Colors.grey;
        statusLabel = status;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: const Color(0xFF1565C0).withOpacity(0.1),
                    child: const Icon(Icons.person_rounded, size: 18, color: Color(0xFF1565C0)),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(isVet ? farmerName : 'Dr. $vetName', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
                      if (isVet && farmerPhone != null && farmerPhone.toString().isNotEmpty)
                        Text(farmerPhone.toString(), style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          if (timeStr.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.schedule_rounded, size: 13, color: Color(0xFF1565C0)),
                  const SizedBox(width: 5),
                  Text(timeStr, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                ],
              ),
            ),
          ],
          if (consultation['notes'] != null && consultation['notes'].toString().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(consultation['notes'].toString(), style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              if (status == 'PENDING' && isVet) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      await ApiClient.acceptConsultation(consultation['id']);
                      onRefresh();
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF059669)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('গ্রহণ করুন', style: TextStyle(color: Color(0xFF059669), fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      await ApiClient.rejectConsultation(consultation['id']);
                      onRefresh();
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFDC2626)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('প্রত্যাখ্যান', style: TextStyle(color: Color(0xFFDC2626), fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
              if (status == 'CONFIRMED' && roomId != null)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => context.push('/video-call/$roomId'),
                    icon: const Icon(Icons.video_call_rounded, size: 18),
                    label: const Text('ভিডিও কল শুরু করুন', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
