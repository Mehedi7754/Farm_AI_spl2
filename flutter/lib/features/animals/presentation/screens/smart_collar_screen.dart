import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/l10n/strings_bn.dart';

class SmartCollarScreen extends StatelessWidget {
  const SmartCollarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text('Smart Collar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Map Top Section
            _buildTopMapSection(),
            
            // Content Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  _buildActivityGrid(),
                  const SizedBox(height: 32),
                  
                  // Motion Tracking Chart
                  _buildMotionChart(context),
                  const SizedBox(height: 24),
                  
                  // Vaccination Reminder
                  _buildVaccinationAlert(),
                  const SizedBox(height: 24),
                  
                  // Vitals Row
                  Row(
                    children: [
                      Expanded(child: _buildVitalBox('তাপমাত্রা', '৩৮.৫°C', Icons.thermostat_rounded, 'স্বাভাবিক', Colors.orange)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildVitalBox('হার্ট রেট', '৬৫ bpm', Icons.favorite_rounded, 'উত্তম', Colors.redAccent)),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  // Detailed Button
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.history_toggle_off_rounded, color: Colors.white),
                    label: const Text(StringsBn.detailedTracking, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF004D40),
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 2,
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopMapSection() {
    return Container(
      height: 420,
      width: double.infinity,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: NetworkImage('https://images.unsplash.com/photo-1500382017468-9049fee74a62?q=80&w=1000&auto=format&fit=crop'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.7),
              Colors.transparent,
              const Color(0xFFF4F7F6),
            ],
          ),
        ),
        child: Column(
          children: [
            const Spacer(),
            // GPS Card Overlay
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.location_on_rounded, color: Color(0xFF2E7D32), size: 24),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('লাইভ ট্র্যাকিং', style: TextStyle(fontSize: 10, color: Color(0xFF7F8C8D), fontWeight: FontWeight.bold)),
                        Text('২৩.৮১° N, ৯০.৪১° E • ব্লক-সি', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2C3E50))),
                      ],
                    ),
                  ),
                  const Text('#SC-9921', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE67E22), fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Active Status Paw Icon
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFF004D40),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: const Icon(Icons.pets_rounded, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF2C3E50).withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'গরু #৪০২ • বিশ্রাম নিচ্ছে',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityGrid() {
    return Row(
      children: [
        _buildStatBox('চার্জ', '৮৫%', Icons.bolt_rounded, Colors.orange),
        const SizedBox(width: 12),
        _buildActivityButton(StringsBn.grazing, Icons.grass_rounded, false),
        const SizedBox(width: 12),
        _buildActivityButton(StringsBn.active, Icons.directions_run_rounded, false),
        const SizedBox(width: 12),
        _buildActivityButton(StringsBn.resting, Icons.nightlight_round_rounded, true),
      ],
    );
  }

  Widget _buildStatBox(String label, String value, IconData icon, Color color) {
    return Container(
      width: 85,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE0E6ED)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF95A5A6), fontWeight: FontWeight.bold)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2C3E50))),
        ],
      ),
    );
  }

  Widget _buildActivityButton(String label, IconData icon, bool isActive) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF004D40) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? const Color(0xFF004D40) : const Color(0xFFE0E6ED)),
        ),
        child: Column(
          children: [
            Icon(icon, color: isActive ? Colors.white : const Color(0xFF004D40), size: 20),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 10, color: isActive ? Colors.white : const Color(0xFF2C3E50), fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalBox(String label, String value, IconData icon, String status, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE0E6ED)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(status, style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: color)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF7F8C8D), fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
        ],
      ),
    );
  }

  Widget _buildVaccinationAlert() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade700,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.vaccines_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(StringsBn.vaccinationTime, style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
                Text('পরবর্তী ডোজ ৭২ দিন পর', style: TextStyle(fontSize: 12, color: Color(0xFF1976D2))),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF1976D2), size: 16),
        ],
      ),
    );
  }

  Widget _buildMotionChart(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE0E6ED)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(StringsBn.motionTracking, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2C3E50))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(8)),
                child: const Text('মাঝারি লেভেল', style: TextStyle(fontSize: 10, color: Color(0xFFE67E22), fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const Text('কার্যকলাপের ইতিহাস (আজ)', style: TextStyle(fontSize: 11, color: Color(0xFF95A5A6))),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(8, (index) {
              final heights = [30, 45, 60, 90, 70, 20, 15, 35];
              final colors = [
                const Color(0xFFECF0F1),
                const Color(0xFFECF0F1),
                const Color(0xFF8DB090),
                const Color(0xFF004D40),
                const Color(0xFF8DB090),
                const Color(0xFFECF0F1),
                const Color(0xFFE57373),
                const Color(0xFFECF0F1),
              ];
              return Column(
                children: [
                  Container(
                    width: 24,
                    height: heights[index].toDouble(),
                    decoration: BoxDecoration(
                      color: colors[index],
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (index == 0) const Text('সকাল ৬', style: TextStyle(fontSize: 8, color: Color(0xFF95A5A6))),
                  if (index == 4) const Text('দুপুর ১২', style: TextStyle(fontSize: 8, color: Color(0xFF95A5A6))),
                  if (index == 7) const Text('সন্ধ্যা ৬', style: TextStyle(fontSize: 8, color: Color(0xFF95A5A6))),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}
