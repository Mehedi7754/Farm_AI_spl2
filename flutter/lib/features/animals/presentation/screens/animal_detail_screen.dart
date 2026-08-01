import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/l10n/strings_bn.dart';
import '../providers/livestock_provider.dart';

class AnimalDetailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? animalData;
  const AnimalDetailScreen({super.key, this.animalData});

  @override
  ConsumerState<AnimalDetailScreen> createState() => _AnimalDetailScreenState();
}

class _AnimalDetailScreenState extends ConsumerState<AnimalDetailScreen> {
  final List<String> _notes = [];

  void _showAddNoteModal(BuildContext context) {
    final noteCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('নতুন স্বাস্থ্য নোট', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 10),
              TextField(
                controller: noteCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'এখানে নোট লিখুন...',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    if (noteCtrl.text.trim().isNotEmpty) {
                      setState(() {
                        _notes.insert(0, noteCtrl.text.trim());
                      });
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('নোট যুক্ত করা হয়েছে 📝'), backgroundColor: Color(0xFF064E3B)),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF064E3B),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('সংরক্ষণ করুন', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, Map<String, dynamic> cow) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('গবাদিপশু মুছে ফেলুন'),
        content: const Text('আপনি কি নিশ্চিত যে আপনি এই গবাদিপশুটি মুছে ফেলতে চান? এটি কলার সংযোগও বিচ্ছিন্ন করবে।'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('না', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(livestockProvider.notifier).deleteLivestock(cow['id'].toString());
              if (context.mounted) {
                context.pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('গবাদিপশুটি সফলভাবে মুছে ফেলা হয়েছে 🗑️'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('হ্যাঁ, মুছুন', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cow = widget.animalData ?? {};
    final milkYield = (cow['dailyMilkYield'] ?? '0').toString();
    // In a real scenario, body temp comes from smart collar data
    final temp = 'স্বাভাবিক'; 

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
            'গবাদিপশুর বিস্তারিত প্রোফাইল',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_forever_rounded, color: Colors.white, size: 22),
              onPressed: () => _confirmDelete(context, cow),
            ),
            IconButton(
              icon: const Icon(Icons.share_rounded, color: Colors.white, size: 20),
              onPressed: () {},
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. CATTLE PROFILE BANNER CARD
            _buildProfileCard(),
            const SizedBox(height: 12),

            // 2. SMART COLLAR TELEMETRY CARD
            _buildSmartCollarButton(context),
            const SizedBox(height: 12),

            // 3. STATS GRID (MILK & BODY TEMP)
            Row(
              children: [
                Expanded(child: _buildDetailStatCard(context, StringsBn.milkProduction, '$milkYield লিটার/দিন', 'গড় উৎপাদন', Icons.water_drop_rounded, const Color(0xFF0284C7))),
                const SizedBox(width: 10),
                Expanded(child: _buildDetailStatCard(context, StringsBn.bodyTemp, temp, 'বর্তমান অবস্থা', Icons.thermostat_rounded, const Color(0xFF059669))),
              ],
            ),
            const SizedBox(height: 12),

            // 4. HEALTH & VACCINATION HISTORY
            _buildHistorySection(context),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddNoteModal(context),
        backgroundColor: const Color(0xFF064E3B),
        icon: const Icon(Icons.edit_note_rounded, color: Colors.white),
        label: const Text('নোট যুক্ত করুন', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildProfileCard() {
    final cow = widget.animalData ?? {};
    final name = (cow['name'] ?? 'অজানা নাম').toString();
    final breed = (cow['breed'] ?? 'অজানা জাত').toString();
    final weight = (cow['weight'] ?? '0').toString();
    final collarId = (cow['collarId'] ?? 'N/A').toString();
    final health = (cow['health'] ?? cow['status'] ?? 'সুস্থ').toString();
    
    // Parse DOB to Age if available
    String ageStr = 'অজানা বয়স';
    if (cow['dateOfBirth'] != null) {
      try {
        final dob = DateTime.parse(cow['dateOfBirth']);
        final days = DateTime.now().difference(dob).inDays;
        final years = (days / 365).toStringAsFixed(1);
        ageStr = '$years বছর';
      } catch (e) {
        // ignore
      }
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCBD5E1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFA7F3D0)),
            ),
            child: const Icon(Icons.pets_rounded, color: Color(0xFF059669), size: 40),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: health.contains('সুস্থ') ? const Color(0xFFECFDF5) : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        health, 
                        style: TextStyle(
                          color: health.contains('সুস্থ') ? const Color(0xFF059669) : const Color(0xFFD97706), 
                          fontSize: 10, 
                          fontWeight: FontWeight.bold
                        )
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'জাত: $breed • বয়স: $ageStr',
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildMiniStat(StringsBn.animalWeight, '$weight কেজি'),
                    const SizedBox(width: 16),
                    _buildMiniStat('স্মার্ট কলার আইডি', collarId),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartCollarButton(BuildContext context) {
    final collarId = widget.animalData?['collarId']?.toString();
    
    return InkWell(
      onTap: () {
        if (collarId != null && collarId.isNotEmpty && collarId != 'N/A') {
          context.push('/animals/collar', extra: collarId);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('এই গবাদিপশুর সাথে কোনো স্মার্ট কলার সংযুক্ত নেই।'), backgroundColor: Color(0xFFDC2626)),
          );
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF064E3B), Color(0xFF047857)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF064E3B).withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.sensors_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'স্মার্ট কলার টেলিমেট্রি ও কন্ট্রোল 📡',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    'লাইভ জিপিএস লোকেশন ও হার্টরেট ট্র্যাকিং',
                    style: TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF064E3B))),
      ],
    );
  }

  Widget _buildDetailStatCard(BuildContext context, String title, String value, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 6),
              Expanded(child: Text(title, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600))),
            ],
          ),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
          const SizedBox(height: 2),
          Text(subtitle, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildHistorySection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'স্বাস্থ্য ও টিকাদানের ইতিহাস',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 8),
        if (_notes.isNotEmpty)
          ..._notes.map((note) => _buildHistoryItem(context, note, 'নতুন নোট (ম্যানুয়াল)', Icons.note_alt_rounded, const Color(0xFFF3E8FF), const Color(0xFF7E22CE))),
        
        _buildHistoryItem(context, 'খুরা রোগ (FMD) ২য় ডোজ সম্পন্ন', '১৫ মে, ২০২৬ • ডাঃ মোঃ আব্দুর রাজ্জাক', Icons.vaccines_rounded, const Color(0xFFECFDF5), const Color(0xFF059669)),
        _buildHistoryItem(context, 'কৃমিনাশক ড্যাশবোর্ড চিকিৎসা', '০২ মে, ২০২৬ • সফল প্রয়োগ', Icons.assignment_turned_in_rounded, const Color(0xFFEFF6FF), const Color(0xFF0284C7)),
      ],
    );
  }

  Widget _buildHistoryItem(BuildContext context, String title, String subtitle, IconData icon, Color bgColor, Color iconColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F172A))),
                Text(subtitle, style: const TextStyle(color: Color(0xFF64748B), fontSize: 10)),
              ],
            ),
          ),
          const Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 18),
        ],
      ),
    );
  }
}
