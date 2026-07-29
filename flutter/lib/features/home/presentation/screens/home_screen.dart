import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/l10n/strings_bn.dart';
import '../../../utilities/presentation/providers/weather_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../animals/presentation/providers/livestock_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final weatherState = ref.watch(weatherProvider);
    final authState = ref.watch(authProvider);
    final livestockState = ref.watch(livestockProvider);

    final farmName = authState.user?['name'] != null ? '${authState.user!['name']}-এর খামার' : 'আমার খামার';
    final weatherData = weatherState.data;
    final temp = (weatherData?['currentTemperature'] as num?)?.toDouble() ?? 31.0;
    
    final animalCount = livestockState.maybeWhen(
      data: (list) => list.length,
      orElse: () => 0,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 68,
        titleSpacing: 20,
        surfaceTintColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: const Color(0xFFF1F5F9), height: 1.0),
        ),
        title: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF047857)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(13),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF059669).withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.eco_rounded, color: Colors.white, size: 24),
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    const Text(
                      'FarmAI',
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: const Text(
                        'স্মার্ট খামার',
                        style: TextStyle(color: Color(0xFF047857), fontSize: 10, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  farmName,
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
        actions: [
          GestureDetector(
            onTap: () {
              ref.read(authProvider.notifier).logout();
              context.go('/login');
            },
            child: Container(
              margin: const EdgeInsets.only(right: 20),
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Icon(Icons.logout_rounded, color: Color(0xFF64748B), size: 18),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Premium Hero Voice Assistance Banner Card
            _buildPremiumVoiceCard(context),
            const SizedBox(height: 16),

            // 2. Telemetry KPI Bar
            _buildKpiBar(context, '${temp.round()}°C', '$animalCount টি'),
            const SizedBox(height: 24),

            // 3. Khamaar Seba Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(Icons.grid_view_rounded, color: Color(0xFF047857), size: 22),
                    SizedBox(width: 10),
                    Text(
                      'খামার সেবাসমূহ',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.4,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '৮ টি সেবামূলক মডিউল',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                  ),
                ),
              ],
            ).animate().fadeIn(duration: 350.ms),

            const SizedBox(height: 16),

            // 4. Ultra-Premium Cohesive Module Cards Grid
            _buildPremiumCohesiveServiceGrid(context),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumVoiceCard(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/ai/voice'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF047857), Color(0xFF065F46)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF047857).withValues(alpha: 0.28),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.mic_rounded, color: Color(0xFF047857), size: 24),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'কথা বলে সেবা নিন',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2),
                  Text(
                    'পশুর যে কোনো লক্ষণ বা সমস্যা মুখে বলুন',
                    style: TextStyle(
                      color: Color(0xFFA7F3D0),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Text(
                    'কথা বলুন',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(width: 3),
                  Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 9),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.05, end: 0);
  }

  Widget _buildKpiBar(BuildContext context, String temp, String animalCount) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: const Color(0x0A0F172A),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          _buildKpiTile(
            icon: Icons.wb_sunny_rounded,
            iconColor: const Color(0xFFD97706),
            val: temp,
            label: 'আবহাওয়া',
            onTap: () => context.push('/weather'),
          ),
          _buildKpiDivider(),
          _buildKpiTile(
            icon: Icons.pets_rounded,
            iconColor: const Color(0xFF047857),
            val: animalCount,
            label: 'গবাদিপশু',
            onTap: () => context.push('/animals'),
          ),
          _buildKpiDivider(),
          _buildKpiTile(
            icon: Icons.water_drop_rounded,
            iconColor: const Color(0xFF0284C7),
            val: '-- লি.',
            label: 'দৈনিক দুধ',
            onTap: () => context.push('/accounting'),
          ),
          _buildKpiDivider(),
          _buildKpiTile(
            icon: Icons.trending_up_rounded,
            iconColor: const Color(0xFF16A34A),
            val: '৳--',
            label: 'মাসের লাভ',
            onTap: () => context.push('/accounting'),
          ),
          _buildKpiDivider(),
          _buildKpiTile(
            icon: Icons.sensors_rounded,
            iconColor: const Color(0xFF2563EB),
            val: 'সক্রিয়',
            label: 'স্মার্ট কলার',
            onTap: () => context.push('/collar'),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 450.ms, delay: 100.ms);
  }

  Widget _buildKpiTile({
    required IconData icon,
    required Color iconColor,
    required String val,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(val, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF0F172A))),
                Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiDivider() {
    return Container(margin: const EdgeInsets.symmetric(vertical: 8), width: 1, color: const Color(0xFFF1F5F9));
  }

  Widget _buildPremiumCohesiveServiceGrid(BuildContext context) {
    final list = [
      {
        'title': StringsBn.aiSymptom,
        'sub': 'লক্ষণ ও রোগ বিশ্লেষণ',
        'icon': Icons.biotech_rounded,
        'accentColor': const Color(0xFF047857),
        'badgeBg': const Color(0xFFECFDF5),
        'route': '/ai/symptom',
      },
      {
        'title': StringsBn.cattleManagement,
        'sub': 'পশুর তালিকা ও স্বাস্থ্য',
        'icon': Icons.pets_rounded,
        'accentColor': const Color(0xFF2563EB),
        'badgeBg': const Color(0xFFEFF6FF),
        'route': '/animals',
      },
      {
        'title': StringsBn.hospitalFinder,
        'sub': 'নিকটস্থ হাসপাতাল ম্যাপ',
        'icon': Icons.local_hospital_rounded,
        'accentColor': const Color(0xFFDC2626),
        'badgeBg': const Color(0xFFFEF2F2),
        'route': '/hospital',
      },
      {
        'title': StringsBn.vaccineReminder,
        'sub': 'টিকা ও কৃমিনাশক নোটিশ',
        'icon': Icons.vaccines_rounded,
        'accentColor': const Color(0xFF9333EA),
        'badgeBg': const Color(0xFFFAF5FF),
        'route': '/reminders',
      },
      {
        'title': StringsBn.accounting,
        'sub': 'দুধ বিক্রি ও আয়-ব্যয়',
        'icon': Icons.payments_rounded,
        'accentColor': const Color(0xFFD97706),
        'badgeBg': const Color(0xFFFEFCE8),
        'route': '/accounting',
      },
      {
        'title': StringsBn.weather,
        'sub': 'বৃষ্টি ও আবহাওয়া পূর্বাভাস',
        'icon': Icons.cloud_sync_rounded,
        'accentColor': const Color(0xFF0284C7),
        'badgeBg': const Color(0xFFF0F9FF),
        'route': '/weather',
      },
      {
        'title': StringsBn.teleVet,
        'sub': 'ডাক্তারের সাথে ভিডিও কল',
        'icon': Icons.video_call_rounded,
        'accentColor': const Color(0xFFDB2777),
        'badgeBg': const Color(0xFFFDF2F8),
        'route': '/televet',
      },
      {
        'title': StringsBn.medicine,
        'sub': 'ওষুধের বিবরণ ও মাত্রা',
        'icon': Icons.medication_rounded,
        'accentColor': const Color(0xFFEA580C),
        'badgeBg': const Color(0xFFFFF7ED),
        'route': '/medicine',
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 1.10,
      ),
      itemBuilder: (context, idx) {
        final item = list[idx];
        final accentColor = item['accentColor'] as Color;
        final badgeBg = item['badgeBg'] as Color;

        return GestureDetector(
          onTap: () => context.push(item['route'] as String),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: const Color(0x080F172A),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    item['icon'] as IconData,
                    color: accentColor,
                    size: 25,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['title'] as String,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item['sub'] as String,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ).animate().fadeIn(duration: 400.ms, delay: (idx * 40).ms).slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic);
      },
    );
  }
}
