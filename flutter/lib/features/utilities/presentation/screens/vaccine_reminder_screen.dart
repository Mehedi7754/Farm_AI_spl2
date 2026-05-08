import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/l10n/strings_bn.dart';

class VaccineReminderScreen extends StatelessWidget {
  const VaccineReminderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBF9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF003300),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          StringsBn.vaccineReminder,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF003300), Color(0xFFF8FBF9)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.12],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary Card
              _buildSummaryCard(),
              const SizedBox(height: 36),

              // Today's Tasks
              _buildSectionHeader('আজকের সূচী'),
              const SizedBox(height: 16),
              _buildReminderCard(
                animal: 'লালু (গরু)',
                task: 'খুরারোগের ভ্যাকসিন',
                time: 'সকাল ১০:০০',
                status: 'চলমান',
                icon: Icons.vaccines_rounded,
                color: const Color(0xFF00695C),
              ),
              _buildReminderCard(
                animal: 'মন্টি (ছাগল)',
                task: 'কৃমিনাশক ওষুধ',
                time: 'দুপুর ১২:৩০',
                status: 'অপেক্ষমান',
                icon: Icons.medication_rounded,
                color: const Color(0xFFE67E22),
              ),

              const SizedBox(height: 36),

              // Upcoming Tasks
              _buildSectionHeader('আসন্ন সেবা'),
              const SizedBox(height: 16),
              _buildReminderCard(
                animal: 'দেশি মুরগি (ঝাঁক-এ)',
                task: 'রানিখেত ভ্যাকসিন',
                time: '১৫ অক্টোবর',
                status: 'আগামীকাল',
                icon: Icons.event_note_rounded,
                color: const Color(0xFF2980B9),
              ),
              _buildReminderCard(
                animal: 'বুলু (মহিষ)',
                task: 'পরজীবী নিয়ন্ত্রণ',
                time: '১৮ অক্টোবর',
                status: '৩ দিন পর',
                icon: Icons.bug_report_rounded,
                color: const Color(0xFF8E44AD),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: const Color(0xFF003300),
        elevation: 8,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('নতুন রিমাইন্ডার', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF004D40), Color(0xFF003300)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF003300).withValues(alpha: 0.25),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'আপনার ফার্মের অগ্রগতি',
                      style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      '৮৫% সেবা সম্পন্ন',
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.analytics_rounded, color: Colors.white, size: 32),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Stack(
            children: [
              Container(
                height: 10,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  return Container(
                    height: 10,
                    width: constraints.maxWidth * 0.85,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF4DB6AC), Color(0xFF26A69A)]),
                      borderRadius: BorderRadius.circular(5),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFF26A69A).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2)),
                      ],
                    ),
                  );
                }
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('মোট ২০টি', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12, fontWeight: FontWeight.w500)),
              Text('১৭টি সম্পন্ন', style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50), letterSpacing: -0.5),
        ),
        TextButton(
          onPressed: () {},
          style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
          child: const Text(
            'সবগুলো দেখুন',
            style: TextStyle(fontSize: 13, color: Color(0xFF004D40), fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildReminderCard({
    required String animal,
    required String task,
    required String time,
    required String status,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: const Color(0xFFF0F4F7), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        animal,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A1A1A), letterSpacing: -0.3),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        task,
                        style: TextStyle(color: const Color(0xFF7F8C8D), fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.schedule_rounded, size: 14, color: const Color(0xFFBDC3C7)),
                          const SizedBox(width: 6),
                          Text(
                            time,
                            style: const TextStyle(color: Color(0xFF95A5A6), fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.2),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFECF0F1), size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
