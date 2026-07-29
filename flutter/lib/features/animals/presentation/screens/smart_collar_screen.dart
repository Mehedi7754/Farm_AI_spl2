import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/l10n/strings_bn.dart';
import '../../../../core/network/api_client.dart';

class SmartCollarScreen extends StatefulWidget {
  const SmartCollarScreen({super.key});

  @override
  State<SmartCollarScreen> createState() => _SmartCollarScreenState();
}

class _SmartCollarScreenState extends State<SmartCollarScreen> {
  bool _isLedActive = false;
  Map<String, dynamic> _collarData = {
    'heartRate': 72,
    'temperature': 38.5,
    'steps': 4200,
    'battery': 88,
  };

  Future<void> _toggleLed() async {
    final newLedState = !_isLedActive;
    setState(() => _isLedActive = newLedState);
    final res = await ApiClient.triggerCollarLed('collar-101');
    if (mounted && res) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newLedState ? 'স্মার্ট কলারের LED সিগন্যাল চালু হয়েছে' : 'LED সিগন্যাল বন্ধ করা হয়েছে'),
          backgroundColor: const Color(0xFF004D40),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(52),
        child: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleSpacing: 12,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF18181B)),
            onPressed: () => context.pop(),
          ),
          title: Text(
            StringsBn.smartCollar,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF09090B)),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(color: const Color(0xFFE4E4E7), height: 1),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            // Status Header Pill (Shadcn Card)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE4E4E7)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(color: Color(0xFF059669), shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'কলার #১০১ (অনলাইন)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF09090B)),
                      ),
                    ],
                  ),
                  Text(
                    'চার্জ: ${_collarData['battery']}%',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 2x2 Compact Telemetry Gauges Grid
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.35,
                children: [
                  _buildGaugeTile('হার্ট রেট', '${_collarData['heartRate']} bpm', Icons.favorite_rounded, const Color(0xFFDC2626)),
                  _buildGaugeTile('শরীরের তাপ', '${_collarData['temperature']}°C', Icons.thermostat_rounded, const Color(0xFFD97706)),
                  _buildGaugeTile('দৈনিক কদম', '${_collarData['steps']}', Icons.directions_walk_rounded, const Color(0xFF2563EB)),
                  _buildGaugeTile('ব্যাটারি ব্যাকআপ', '${_collarData['battery']}%', Icons.battery_charging_full_rounded, const Color(0xFF059669)),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // LED Signal Action Box (Shadcn Button)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _toggleLed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isLedActive ? const Color(0xFFDC2626) : const Color(0xFF004D40),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                icon: Icon(_isLedActive ? Icons.flash_off_rounded : Icons.flash_on_rounded, color: Colors.white, size: 18),
                label: Text(
                  _isLedActive ? 'কলার LED সিগন্যাল বন্ধ করুন' : 'কলারে LED সিগন্যাল লাইট জ্বালান',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGaugeTile(String label, String value, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE4E4E7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: iconColor, size: 20),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(color: Color(0xFF059669), shape: BoxShape.circle),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF09090B)),
              ),
              Text(
                label,
                style: const TextStyle(fontSize: 10, color: Color(0xFF71717A)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
