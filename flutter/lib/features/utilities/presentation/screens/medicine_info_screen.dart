import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class MedicineInfoScreen extends StatelessWidget {
  const MedicineInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBF9),
      appBar: AppBar(
        title: const Text(
          'ওষুধের তথ্য',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1A1A1A)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 8)),
                ],
                border: Border.all(color: const Color(0xFFF0F4F7)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, color: Color(0xFF2E7D32), size: 22),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'ওষুধের নাম লিখে খুঁজুন...',
                        hintStyle: TextStyle(color: Color(0xFF95A5A6), fontSize: 14),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(color: Color(0xFFF8FBF9), shape: BoxShape.circle),
                    child: const Icon(Icons.mic_none_rounded, color: Color(0xFF2E7D32), size: 18),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Medicine Detail Section
            _buildMedicineDetailCard(context),
            
            const SizedBox(height: 24),
            
            // Advice Section
            _buildProfessionalAdvice(),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicineDetailCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 10)),
        ],
        border: Border.all(color: const Color(0xFFF0F4F7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'অক্সিটোট্রাসাইক্লিন',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20), letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Oxytetracycline (LA)',
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.medication_rounded, color: Color(0xFF2E7D32), size: 24),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildInfoSection('ব্যবহার ও বর্ণনা', 'এটি একটি ব্রড-স্পেকট্রাম অ্যান্টিবায়োটিক। গবাদি পশুর বিভিন্ন ব্যাকটেরিয়াজনিত রোগ, যেমন- তড়কা, বাদলা, গলাফুলা এবং নিউমোনিয়ার চিকিৎসায় অত্যন্ত কার্যকর। এটি দীর্ঘক্ষণ রক্তে কার্যকারিতা বজায় রাখে।', Icons.info_outline_rounded),
          const SizedBox(height: 32),
          _buildDoseSection(),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideX(begin: 0.1, end: 0);
  }

  Widget _buildInfoSection(String title, String desc, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFF2E7D32), size: 18),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1B5E20))),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          desc,
          style: TextStyle(color: Colors.grey.shade700, fontSize: 14, height: 1.6),
        ),
      ],
    );
  }

  Widget _buildDoseSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.assignment_rounded, color: Color(0xFF2E7D32), size: 18),
            const SizedBox(width: 8),
            Text('মাত্রা ও প্রয়োগবিধি', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1B5E20))),
          ],
        ),
        const SizedBox(height: 16),
        _buildDoseItem('প্রতি ১০ কেজি ওজনের জন্য ১ মিলি ইনজেকশন।'),
        _buildDoseItem('গভীর মাংসপেশীতে প্রয়োগ করতে হবে।'),
        _buildDoseItem('এক স্থানে ১০ মিলির বেশি ইনজেকশন দেবেন না।'),
      ],
    );
  }

  Widget _buildDoseItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(color: Color(0xFF2E7D32), shape: BoxShape.circle),
            child: const Icon(Icons.check, size: 10, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: TextStyle(color: Colors.grey.shade700, fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildProfessionalAdvice() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Color(0xFFFFE0B2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: Color(0xFFE65100), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'সতর্কবার্তা',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFFE65100)),
                ),
                SizedBox(height: 4),
                Text(
                  'এটি সচেতনতামূলক তথ্য, প্রেসক্রিপশন নয়। যে কোনো ওষুধ প্রয়োগের আগে বিশেষজ্ঞ চিকিৎসকের পরামর্শ নিন।',
                  style: TextStyle(fontSize: 12, color: Color(0xFFBF360C), height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
