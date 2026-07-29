import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/l10n/strings_bn.dart';

class AnimalDetailScreen extends StatelessWidget {
  const AnimalDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                Expanded(child: _buildDetailStatCard(context, StringsBn.milkProduction, '১৮.৫ লিটার/দিন', '+০.৫ লিটার (বৃদ্ধি)', Icons.water_drop_rounded, const Color(0xFF0284C7))),
                const SizedBox(width: 10),
                Expanded(child: _buildDetailStatCard(context, StringsBn.bodyTemp, '১০২.৪° F', 'স্বাভাবিক তাপমাত্রা ✓', Icons.thermostat_rounded, const Color(0xFF059669))),
              ],
            ),
            const SizedBox(height: 12),

            // 4. HEALTH & VACCINATION HISTORY
            _buildHistorySection(context),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('গবাদিপশুর স্বাস্থ্য নোট তৈরি করা হয়েছে 📝'),
              backgroundColor: Color(0xFF064E3B),
            ),
          );
        },
        backgroundColor: const Color(0xFF064E3B),
        icon: const Icon(Icons.edit_note_rounded, color: Colors.white),
        label: const Text('নোট যুক্ত করুন', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildProfileCard() {
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
                    const Text(
                      'লালমনি (গাভী নং ১)',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('সুস্থ (৯৮%)', style: TextStyle(color: Color(0xFF059669), fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'জাত: হোলস্টাইন ফ্রিজিয়ান • বয়স: ৩.৫ বছর',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildMiniStat(StringsBn.animalWeight, '৩৮০ কেজি'),
                    const SizedBox(width: 16),
                    _buildMiniStat('স্মার্ট কলার আইডি', '#101-BD'),
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
    return InkWell(
      onTap: () => context.push('/animals/collar'),
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
