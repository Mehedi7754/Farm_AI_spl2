import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/time_utils.dart';

class FindVetScreen extends StatefulWidget {
  const FindVetScreen({super.key});

  @override
  State<FindVetScreen> createState() => _FindVetScreenState();
}

class _FindVetScreenState extends State<FindVetScreen> {
  List<Map<String, dynamic>> _vets = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;
  String _selectedSpec = 'সব';
  String _search = '';

  int _selectedTab = 0; // 0: Find Vet, 1: My Bookings
  List<Map<String, dynamic>> _myBookings = [];
  bool _isLoadingBookings = false;

  static const _specs = ['সব', 'গরু ও ছাগল', 'পোল্ট্রি', 'ভেড়া ও মহিষ', 'সাধারণ পশু চিকিৎসা', 'সার্জারি ও অস্ত্রোপচার'];

  @override
  void initState() {
    super.initState();
    _loadVets();
  }

  Future<void> _loadVets() async {
    try {
      final data = await ApiClient.getVets();
      if (mounted) {
        setState(() {
          _vets = List<Map<String, dynamic>>.from(data);
          _applyFilter();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  static final Set<String> _deletedBookingIds = {};

  Future<void> _loadMyBookings() async {
    setState(() => _isLoadingBookings = true);
    try {
      final user = ApiClient.currentUser;
      if (user != null) {
        final data = await ApiClient.getMyConsultations(userId: user['id'] as String, role: 'FARMER');
        if (mounted) {
          setState(() {
            _myBookings = List<Map<String, dynamic>>.from(data)
                .where((b) => !_deletedBookingIds.contains(b['id']))
                .toList();
            _isLoadingBookings = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingBookings = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingBookings = false);
    }
  }

  void _applyFilter() {
    setState(() {
      _filtered = _vets.where((v) {
        final spec = v['specialization']?.toString() ?? '';
        final name = (v['user']?['name'] ?? '').toString().toLowerCase();
        final district = (v['district'] ?? '').toString();
        final matchSpec = _selectedSpec == 'সব' || spec == _selectedSpec;
        final matchSearch = _search.isEmpty || name.contains(_search.toLowerCase()) || district.contains(_search);
        return matchSpec && matchSearch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('পশু চিকিৎসা', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // ── Segmented Tab Bar ────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFF1565C0),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTab = 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _selectedTab == 0 ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'ডাক্তার খুঁজুন',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: _selectedTab == 0 ? const Color(0xFF1565C0) : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedTab = 1);
                        _loadMyBookings();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _selectedTab == 1 ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'আমার বুকিং',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: _selectedTab == 1 ? const Color(0xFF1565C0) : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Main Body based on selected tab ──────────────────────
          Expanded(
            child: _selectedTab == 0
                ? _buildFindVetTab()
                : _buildMyBookingsTab(),
          ),
        ],
      ),
    );
  }

  Widget _buildFindVetTab() {
    return Column(
      children: [
        // ── Search bar ───────────────────────────────────────────────
        Container(
          color: const Color(0xFF1565C0),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: TextField(
            onChanged: (v) { _search = v; _applyFilter(); },
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'নাম বা জেলা দিয়ে খুঁজুন...',
              hintStyle: const TextStyle(color: Colors.white60),
              prefixIcon: const Icon(Icons.search_rounded, color: Colors.white70),
              filled: true,
              fillColor: Colors.white.withOpacity(0.15),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),

        // ── Spec filter chips ────────────────────────────────────────
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            itemCount: _specs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final sel = _specs[i] == _selectedSpec;
              return GestureDetector(
                onTap: () { setState(() => _selectedSpec = _specs[i]); _applyFilter(); },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: sel ? const Color(0xFF1565C0) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: sel ? const Color(0xFF1565C0) : const Color(0xFFE2E8F0)),
                  ),
                  child: Text(_specs[i], style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: sel ? Colors.white : const Color(0xFF475569))),
                ),
              );
            },
          ),
        ),

        // ── Vet List ─────────────────────────────────────────────────
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF1565C0)))
              : _filtered.isEmpty
                  ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.search_off_rounded, size: 64, color: Color(0xFFCBD5E1)),
                      SizedBox(height: 12),
                      Text('কোনো চিকিৎসক পাওয়া যায়নি', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14)),
                    ]))
                  : RefreshIndicator(
                      onRefresh: _loadVets,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(14),
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) => _VetCard(vet: _filtered[i]),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildMyBookingsTab() {
    if (_isLoadingBookings) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF1565C0)));
    }
    if (_myBookings.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today_rounded, size: 64, color: Color(0xFFCBD5E1)),
            SizedBox(height: 12),
            Text('আপনার কোনো বুকিং পাওয়া যায়নি', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadMyBookings,
      child: ListView.builder(
        padding: const EdgeInsets.all(14),
        itemCount: _myBookings.length,
        itemBuilder: (_, i) => _BookingCard(booking: _myBookings[i], onRefresh: _loadMyBookings),
      ),
    );
  }
}

class _VetCard extends StatelessWidget {
  final Map<String, dynamic> vet;
  const _VetCard({required this.vet});

  @override
  Widget build(BuildContext context) {
    final user = vet['user'] as Map<String, dynamic>? ?? {};
    final name = user['name'] ?? 'ডাক্তার';
    final spec = vet['specialization'] ?? '';
    final district = vet['district'] ?? '';
    final fee = (vet['consultationFee'] ?? 0).toDouble();
    final rating = (vet['rating'] ?? 0).toDouble();
    final reviews = vet['totalReviews'] ?? 0;
    final isVerified = vet['isVerified'] == true;
    final isAvailable = vet['isAvailable'] != false;
    final profileImg = vet['profileImageUrl'];
    final userId = user['id'];

    return GestureDetector(
      onTap: () => context.push('/vet-detail/$userId', extra: vet),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Avatar
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: const Color(0xFFE3F2FD),
                        backgroundImage: profileImg != null ? NetworkImage(profileImg) : null,
                        child: profileImg == null ? Text(name[0], style: const TextStyle(color: Color(0xFF1565C0), fontSize: 20, fontWeight: FontWeight.bold)) : null,
                      ),
                      if (isAvailable)
                        Positioned(bottom: 0, right: 0, child: Container(
                          width: 12, height: 12,
                          decoration: BoxDecoration(color: const Color(0xFF22C55E), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                        )),
                    ],
                  ),
                  const SizedBox(width: 12),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Text('Dr. $name', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
                          if (isVerified) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.verified_rounded, color: Color(0xFF1565C0), size: 14),
                          ],
                        ]),
                        Text(spec, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        if (district.isNotEmpty) Row(children: [
                          const Icon(Icons.location_on_outlined, size: 11, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 2),
                          Text(district, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                        ]),
                      ],
                    ),
                  ),

                  // Rating + fee
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(children: [
                        const Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 14),
                        const SizedBox(width: 2),
                        Text(rating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Text(' ($reviews)', style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                      ]),
                      const SizedBox(height: 4),
                      Text('৳${fee.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF059669))),
                      const Text('পরামর্শ ফি', style: TextStyle(fontSize: 9, color: Color(0xFF94A3B8))),
                    ],
                  ),
                ],
              ),
            ),

            // Action buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: OutlinedButton(
                        onPressed: () => context.push('/chat/$userId?name=${Uri.encodeComponent('Dr. $name')}'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF1565C0)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('চ্যাট', style: TextStyle(color: Color(0xFF1565C0), fontSize: 13, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: ElevatedButton(
                        onPressed: () => context.push('/book-appointment/$userId', extra: vet),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isAvailable ? const Color(0xFF1565C0) : const Color(0xFFCBD5E1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        child: Text(
                          isAvailable ? 'বুক করুন' : 'অনুপলব্ধ',
                          style: TextStyle(color: isAvailable ? Colors.white : const Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Map<String, dynamic> booking;
  final VoidCallback onRefresh;

  const _BookingCard({required this.booking, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final vet = booking['vet'] as Map<String, dynamic>? ?? {};
    final name = vet['name'] ?? 'চিকিৎসক';
    final notes = booking['notes'] ?? '';
    final status = booking['status'] ?? 'PENDING';
    final scheduledTime = booking['scheduledTime'];
    final slot = booking['slot'] as Map<String, dynamic>?;

    String dateStr = '';
    String timeStr = '';

    if (slot != null) {
      try {
        final date = DateTime.parse(slot['date']);
        dateStr = '${date.day}-${date.month}-${date.year}';
        timeStr = '${TimeUtils.formatAmPm(slot['startTime'])} - ${TimeUtils.formatAmPm(slot['endTime'])}';
      } catch (_) {
        dateStr = scheduledTime?.toString() ?? '';
      }
    } else if (scheduledTime != null) {
      try {
        final date = DateTime.parse(scheduledTime);
        dateStr = '${date.day}-${date.month}-${date.year}';
        final hour = date.hour;
        final minute = date.minute.toString().padLeft(2, '0');
        final ampm = hour >= 12 ? 'PM' : 'AM';
        final formattedHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
        timeStr = '$formattedHour:$minute $ampm';
      } catch (_) {
        dateStr = scheduledTime.toString();
      }
    }

    Color statusColor;
    String statusLabel;
    switch (status) {
      case 'CONFIRMED':
        statusColor = const Color(0xFF059669);
        statusLabel = 'নিশ্চিত';
        break;
      case 'PENDING':
        statusColor = const Color(0xFFD97706);
        statusLabel = 'অপেক্ষমান';
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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Dr. $name', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                    child: Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('রেকর্ড মুছে ফেলবেন?'),
                          content: const Text('আপনি কি নিশ্চিত যে এই অ্যাপয়েন্টমেন্টটি তালিকা থেকে স্থায়ীভাবে মুছে ফেলতে চান?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('না')),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: TextButton.styleFrom(foregroundColor: const Color(0xFFDC2626)),
                              child: const Text('মুছে ফেলুন'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        _FindVetScreenState._deletedBookingIds.add(booking['id']);
                        onRefresh();
                        await ApiClient.deleteConsultation(booking['id']);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('অ্যাপয়েন্টমেন্ট মুছে ফেলা হয়েছে')),
                          );
                        }
                      }
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(Icons.delete_outline_rounded, size: 18, color: Colors.grey.shade400),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, size: 12, color: Color(0xFF64748B)),
              const SizedBox(width: 6),
              Text(dateStr, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              if (timeStr.isNotEmpty) ...[
                const SizedBox(width: 14),
                const Icon(Icons.access_time_rounded, size: 12, color: Color(0xFF64748B)),
                const SizedBox(width: 6),
                Text(timeStr, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              ]
            ],
          ),
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text('বিবরণ: $notes', style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      final vetId = booking['vetId'];
                      context.push('/chat/$vetId?name=${Uri.encodeComponent('Dr. $name')}');
                    },
                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                    label: const Text('চ্যাট', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF047857)),
                      foregroundColor: const Color(0xFF047857),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              if (status == 'PENDING' || status == 'CONFIRMED') ...[
                Expanded(
                  child: SizedBox(
                    height: 38,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('অ্যাপয়েন্টমেন্ট বাতিল করবেন?'),
                            content: const Text('আপনি কি নিশ্চিত যে এই অ্যাপয়েন্টমেন্টটি বাতিল করতে চান?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('না')),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                style: TextButton.styleFrom(foregroundColor: const Color(0xFFDC2626)),
                                child: const Text('হ্যাঁ, বাতিল করুন'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          final currentUserId = ApiClient.currentUser?['id'];
                          await ApiClient.cancelConsultation(booking['id'], cancelledBy: currentUserId);
                          onRefresh();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('অ্যাপয়েন্টমেন্ট বাতিল করা হয়েছে')),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.cancel_outlined, size: 16, color: Color(0xFFDC2626)),
                      label: const Text('বাতিল করুন', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFDC2626)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ),
              ] else ...[
                Expanded(
                  child: SizedBox(
                    height: 38,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('রেকর্ড মুছে ফেলবেন?'),
                            content: const Text('আপনি কি নিশ্চিত যে এই রেকর্ডটি তালিকা থেকে স্থায়ীভাবে মুছে ফেলতে চান?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('না')),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                style: TextButton.styleFrom(foregroundColor: const Color(0xFFDC2626)),
                                child: const Text('মুছে ফেলুন'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          _FindVetScreenState._deletedBookingIds.add(booking['id']);
                          onRefresh();
                          await ApiClient.deleteConsultation(booking['id']);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('রেকর্ড মুছে ফেলা হয়েছে')),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFF64748B)),
                      label: const Text('মুছে ফেলুন', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          )
        ],
      ),
    );
  }
}
