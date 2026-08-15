import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../../../core/network/api_client.dart';

class VetAppointmentsScreen extends StatefulWidget {
  const VetAppointmentsScreen({super.key});

  @override
  State<VetAppointmentsScreen> createState() => _VetAppointmentsScreenState();
}

class _VetAppointmentsScreenState extends State<VetAppointmentsScreen> {
  List<Map<String, dynamic>> _consultations = [];
  bool _isLoading = true;
  String _selectedFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _load();
  }

  static final Set<String> _deletedConsultationIds = {};

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final user = ApiClient.currentUser;
      if (user != null) {
        final data = await ApiClient.getMyConsultations(userId: user['id'], role: 'VET');
        if (mounted) {
          setState(() {
            _consultations = List<Map<String, dynamic>>.from(data)
                .where((c) => !_deletedConsultationIds.contains(c['id']))
                .toList();
            _isLoading = false;
          });
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredList {
    if (_selectedFilter == 'ALL') return _consultations;
    return _consultations.where((c) => c['status'] == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text('অ্যাপয়েন্টমেন্ট তালিকা', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _load,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter tabs
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip('ALL', 'সকল'),
                  _filterChip('PENDING', 'পেন্ডিং'),
                  _filterChip('CONFIRMED', 'নিশ্চিত'),
                  _filterChip('COMPLETED', 'সম্পন্ন'),
                  _filterChip('CANCELLED', 'বাতিল'),
                ],
              ),
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF1565C0)))
                : RefreshIndicator(
                    onRefresh: _load,
                    child: _filteredList.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: Text('কোনো অ্যাপয়েন্টমেন্ট পাওয়া যায়নি।', style: TextStyle(color: Color(0xFF64748B))),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(14),
                            itemCount: _filteredList.length,
                            itemBuilder: (context, index) {
                              final item = _filteredList[index];
                              return _AppointmentCard(
                                consultation: item,
                                onRefresh: _load,
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String key, String label) {
    final isSel = _selectedFilter == key;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = key),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSel ? const Color(0xFF1565C0) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSel ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}

class _AppointmentCard extends StatefulWidget {
  final Map<String, dynamic> consultation;
  final VoidCallback onRefresh;
  const _AppointmentCard({required this.consultation, required this.onRefresh});

  @override
  State<_AppointmentCard> createState() => _AppointmentCardState();
}

class _AppointmentCardState extends State<_AppointmentCard> {
  bool _isInitiating = false;

  Future<void> _initiateAndJoinCall() async {
    final consultation = widget.consultation;
    final roomId = consultation['roomId'] as String?;
    final farmerId = consultation['farmerId'] as String?;
    final vetName = ApiClient.currentUser?['name'] ?? 'ভেট';
    final consultationId = consultation['id'] as String?;

    if (roomId == null || farmerId == null) return;
    if (!mounted) return;

    setState(() => _isInitiating = true);

    final wsUrl = ApiClient.baseUrl
        .replaceFirst('/api', '')
        .replaceFirst('http', 'ws');

    final socket = io.io(
      '$wsUrl/webrtc',
      io.OptionBuilder().setTransports(['websocket']).disableAutoConnect().build(),
    );

    bool navigated = false;

    void doNavigate() {
      if (!navigated && mounted) {
        navigated = true;
        setState(() => _isInitiating = false);
        context.push('/video-call/$roomId');
      }
    }

    socket.connect();

    socket.onConnect((_) {
      socket.emit('initiate-call', {
        'consultationId': consultationId ?? '',
        'callerName': vetName,
        'roomId': roomId,
        'targetUserId': farmerId,
      });
      Future.delayed(const Duration(milliseconds: 800), () {
        socket.disconnect();
        doNavigate();
      });
    });

    // Fallback: navigate anyway after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      socket.dispose();
      doNavigate();
    });
  }

  @override
  Widget build(BuildContext context) {
    final consultation = widget.consultation;
    final status = consultation['status'] ?? 'PENDING';
    final farmer = consultation['farmer'] ?? {};
    final farmerName = farmer['name'] ?? 'কৃষক';
    final farmerPhone = farmer['phoneNumber'] ?? 'উপলব্ধ নয়';
    final farmerLocation = farmer['location'] ?? 'বগুড়া';
    final notes = consultation['notes'];
    final roomId = consultation['roomId'];

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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(farmerName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A))),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(statusLabel,
                        style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('রেকর্ড মুছে ফেলবেন?'),
                          content: const Text('আপনি কি নিশ্চিত যে এই অ্যাপয়েন্টমেন্ট রেকর্ডটি তালিকা থেকে স্থায়ীভাবে মুছে ফেলতে চান?'),
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
                        _VetAppointmentsScreenState._deletedConsultationIds.add(consultation['id']);
                        widget.onRefresh();
                        await ApiClient.deleteConsultation(consultation['id']);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('রেকর্ড মুছে ফেলা হয়েছে')),
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
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF64748B)),
              const SizedBox(width: 4),
              Text(farmerLocation, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              const SizedBox(width: 12),
              const Icon(Icons.phone_outlined, size: 14, color: Color(0xFF64748B)),
              const SizedBox(width: 4),
              Text(farmerPhone, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            ],
          ),
          if (notes != null && notes.toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('নোট: $notes',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF334155))),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              if (status == 'PENDING') ...[
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await ApiClient.acceptConsultation(consultation['id']);
                      widget.onRefresh();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('গ্রহণ করুন',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      await ApiClient.rejectConsultation(consultation['id']);
                      widget.onRefresh();
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFDC2626)),
                    ),
                    child: const Text('প্রত্যাখ্যান',
                        style: TextStyle(color: Color(0xFFDC2626), fontSize: 12)),
                  ),
                ),
              ],
              if (status == 'CONFIRMED' && roomId != null) ...[
                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    onPressed: _isInitiating ? null : _initiateAndJoinCall,
                    icon: _isInitiating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.video_call_rounded, size: 20),
                    label: Text(
                      _isInitiating ? 'কল শুরু হচ্ছে...' : 'ভিডিও কল শুরু করুন',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF047857),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('অ্যাপয়েন্টমেন্ট বাতিল করবেন?'),
                        content: const Text('আপনি কি নিশ্চিত যে এই অ্যাপয়েন্টমেন্টটি বাতিল করতে চান? খামারিকে নোটিফিকেশন পাঠানো হবে।'),
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
                      await ApiClient.cancelConsultation(consultation['id'], cancelledBy: currentUserId);
                      widget.onRefresh();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('অ্যাপয়েন্টমেন্ট বাতিল করা হয়েছে')),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.cancel_outlined, color: Color(0xFFDC2626)),
                  tooltip: 'বাতিল করুন',
                ),
              ],
              if (status == 'CANCELLED' || status == 'COMPLETED') ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('রেকর্ড মুছে ফেলবেন?'),
                          content: const Text('আপনি কি নিশ্চিত যে এই অ্যাপয়েন্টমেন্ট রেকর্ডটি তালিকা থেকে মুছে ফেলতে চান?'),
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
                        await ApiClient.deleteConsultation(consultation['id']);
                        widget.onRefresh();
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
              ],
            ],
          ),
        ],
      ),
    );
  }
}
