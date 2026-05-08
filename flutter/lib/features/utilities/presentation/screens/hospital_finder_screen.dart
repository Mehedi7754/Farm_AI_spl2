import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HospitalFinderScreen extends StatelessWidget {
  const HospitalFinderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBF9),
      body: Stack(
        children: [
          // Background "Map" Area
          _buildMapBackground(),

          // Search and Filters Area
          _buildSearchAndFilters(context),

          // Bottom List of Hospitals
          _buildHospitalList(context),
        ],
      ),
    );
  }

  Widget _buildMapBackground() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFFE8F5E9),
      ),
      child: Stack(
        children: [
          // Mock Map Illustration (Subtle)
          Center(
            child: Opacity(
              opacity: 0.1,
              child: Icon(Icons.map_rounded, size: 500, color: const Color(0xFF1B5E20)),
            ),
          ),
          // Mock Markers
          Positioned(
            top: 300,
            left: 150,
            child: _buildMapMarker('উপজেলা হাসপাতাল', true),
          ),
          Positioned(
            top: 350,
            right: 40,
            child: _buildMapMarker('', false),
          ),
        ],
      ),
    );
  }

  Widget _buildMapMarker(String label, bool isLarge) {
    return Column(
      children: [
        if (label.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
            ),
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
            ),
          ),
        const SizedBox(height: 4),
        Icon(
          isLarge ? Icons.location_on_rounded : Icons.add_circle_rounded,
          color: isLarge ? const Color(0xFFD32F2F) : const Color(0xFF2E7D32),
          size: isLarge ? 48 : 34,
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters(BuildContext context) {
    return Positioned(
      top: 50,
      left: 20,
      right: 20,
      child: Column(
        children: [
          // Custom Header
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF1B5E20)),
                  onPressed: () => context.pop(),
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'হাসপাতাল খুঁজুন',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Search Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 8)),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, color: Color(0xFF2E7D32), size: 22),
                const SizedBox(width: 12),
                const Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'আমার কাছের পশু হাসপাতাল',
                      hintStyle: TextStyle(color: Color(0xFF95A5A6), fontSize: 14),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: Color(0xFFF1F8E9), shape: BoxShape.circle),
                  child: const Icon(Icons.tune_rounded, color: Color(0xFF2E7D32), size: 18),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Radius Slider
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('খোঁজার ব্যাসার্ধ (কিমি)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
                    Text('২০ কিমি', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                  ],
                ),
                Slider(
                  value: 20,
                  max: 100,
                  divisions: 10,
                  activeColor: const Color(0xFF2E7D32),
                  inactiveColor: const Color(0xFFE8F5E9),
                  onChanged: (value) {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHospitalList(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      minChildSize: 0.15,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFBFBFC),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 30, spreadRadius: 5),
            ],
          ),
          child: Column(
            children: [
              const SizedBox(height: 14),
              Container(width: 50, height: 6, decoration: BoxDecoration(color: const Color(0xFFECF0F1), borderRadius: BorderRadius.circular(3))),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'কাছের হাসপাতালসমূহ',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20), letterSpacing: -0.5),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(10)),
                      child: const Text(
                        '৩টি পাওয়া গেছে',
                        style: TextStyle(fontSize: 12, color: Color(0xFF2E7D32), fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.only(left: 20, right: 20, bottom: 40),
                  children: [
                    _buildHospitalListItem(
                      context,
                      'উপজেলা পশু সম্পদ কেন্দ্র',
                      'পাবনা সদর, বাংলাদেশ',
                      '৩.২ কিমি',
                      Icons.business_rounded,
                    ),
                    const SizedBox(height: 20),
                    _buildHospitalListItem(
                      context,
                      'কৃষক বন্ধু ভেটেরিনারি ক্লিনিক',
                      'ঈশ্বরদী রোড, পাবনা',
                      '৫.৮ কিমি',
                      Icons.local_pharmacy_rounded,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHospitalListItem(BuildContext context, String name, String address, String distance, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 10)),
        ],
        border: Border.all(color: const Color(0xFFF0F4F7), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: const Color(0xFF2E7D32), size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1A1A1A), letterSpacing: -0.5),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded, color: Color(0xFF95A5A6), size: 14),
                          const SizedBox(width: 4),
                          Text(distance, style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(address, style: const TextStyle(color: Color(0xFF7F8C8D), fontSize: 14)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.phone_rounded, color: Colors.white, size: 18),
                    label: const Text('কল করুন', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F8E9),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFF2E7D32).withValues(alpha: 0.1)),
                  ),
                  child: const Icon(Icons.near_me_rounded, color: Color(0xFF2E7D32), size: 22),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
