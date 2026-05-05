import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/l10n/strings_bn.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCombinedNewsWeather(),
                  const SizedBox(height: 32),
                  const Text(
                    'আপনার জন্য সেবা',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildImageFeatureGrid(context),
                  const SizedBox(height: 120), // Extra space for custom nav
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 100.0,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFF003300),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        centerTitle: false,
        title: Row(
          children: [
            const Icon(Icons.agriculture_rounded, color: Colors.white, size: 24),
            const SizedBox(width: 10),
            Text(
              StringsBn.appName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF003300), Color(0xFF004D40)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
          onPressed: () {},
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildCombinedNewsWeather() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B5E20).withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Icon(
              Icons.cloud_queue_rounded,
              size: 120,
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'খামার সংবাদ',
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.wb_sunny_rounded, color: Colors.orangeAccent, size: 16),
                        const SizedBox(width: 6),
                        const Text(
                          '৩২°সে',
                          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'বগুড়ায় গরুর উন্নত জাত নিয়ে\nনতুন কৃষি প্রচারণা শুরু',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text(
                      'বিস্তারিত জানুন',
                      style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded, color: Colors.white.withValues(alpha: 0.7), size: 14),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildImageFeatureGrid(BuildContext context) {
    final features = [
      {'icon': Icons.health_and_safety_rounded, 'label': StringsBn.aiSymptom, 'color': const Color(0xFFE3F2FD), 'iconColor': const Color(0xFF1976D2), 'route': '/ai/symptom'},
      {'icon': Icons.mic_rounded, 'label': StringsBn.voiceChat, 'color': const Color(0xFFF3E5F5), 'iconColor': const Color(0xFF7B1FA2), 'route': '/ai/voice'},
      {'icon': Icons.local_hospital_rounded, 'label': StringsBn.hospitalFinder, 'color': const Color(0xFFFFEBEE), 'iconColor': const Color(0xFFD32F2F), 'route': '/hospital'},
      {'icon': Icons.notifications_active_rounded, 'label': StringsBn.vaccineReminder, 'color': const Color(0xFFE8F5E9), 'iconColor': const Color(0xFF388E3C), 'route': '/reminders'},
      {'icon': Icons.medical_services_rounded, 'label': StringsBn.medicine, 'color': const Color(0xFFFFF3E0), 'iconColor': const Color(0xFFF57C00), 'route': '/medicine'},
      {'icon': Icons.wb_sunny_rounded, 'label': StringsBn.weather, 'color': const Color(0xFFE0F7FA), 'iconColor': const Color(0xFF0097A7), 'route': '/weather'},
      {'icon': Icons.account_balance_wallet_rounded, 'label': StringsBn.accounting, 'color': const Color(0xFFF1F8E9), 'iconColor': const Color(0xFF689F38), 'route': '/accounting'},
      {'icon': Icons.video_call_rounded, 'label': StringsBn.teleVet, 'color': const Color(0xFFEFEBE9), 'iconColor': const Color(0xFF5D4037), 'route': '/televet'},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: features.length,
      itemBuilder: (context, index) {
        final feature = features[index];
        return _buildFeatureCard(
          context,
          feature['icon'] as IconData,
          feature['label'] as String,
          feature['color'] as Color,
          feature['iconColor'] as Color,
          feature['route'] as String,
          index,
        );
      },
    );
  }

  Widget _buildFeatureCard(BuildContext context, IconData icon, String label, Color bgColor, Color iconColor, String route, int index) {
    return GestureDetector(
      onTap: () => context.push(route),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(color: const Color(0xFFF0F4F7), width: 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Positioned(
                right: -15,
                bottom: -15,
                child: Icon(
                  icon,
                  size: 80,
                  color: iconColor.withValues(alpha: 0.05),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        icon,
                        color: iconColor,
                        size: 24,
                      ),
                    ),
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 500.ms, delay: (index * 60).ms).slideY(begin: 0.1, end: 0);
  }
}
