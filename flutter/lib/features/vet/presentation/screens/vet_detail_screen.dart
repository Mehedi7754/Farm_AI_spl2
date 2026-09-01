import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class VetDetailScreen extends StatelessWidget {
  final String vetId;
  final Map<String, dynamic>? vetData;
  const VetDetailScreen({super.key, required this.vetId, this.vetData});

  @override
  Widget build(BuildContext context) {
    final vet = vetData ?? {};
    final user = vet['user'] as Map<String, dynamic>? ?? {};
    final name = user['name'] ?? 'ডাক্তার';
    final spec = vet['specialization'] ?? '';
    final bio = vet['bio'] ?? 'কোনো বায়ো দেওয়া হয়নি।';
    final district = vet['district'] ?? '';
    final fee = (vet['consultationFee'] ?? 0).toDouble();
    final exp = vet['experienceYears'] ?? 0;
    final rating = (vet['rating'] ?? 0).toDouble();
    final reviews = vet['totalReviews'] ?? 0;
    final isAvailable = vet['isAvailable'] != false;
    final profileImg = vet['profileImageUrl'];

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('ডাক্তার প্রোফাইল', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Profile Image & Basic Info
            CircleAvatar(
              radius: 50,
              backgroundColor: const Color(0xFFE3F2FD),
              backgroundImage: profileImg != null ? NetworkImage(profileImg) : null,
              child: profileImg == null ? Text(name[0], style: const TextStyle(color: Color(0xFF1565C0), fontSize: 36, fontWeight: FontWeight.bold)) : null,
            ),
            const SizedBox(height: 16),
            Text('Dr. $name', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            const SizedBox(height: 4),
            Text(spec, style: const TextStyle(fontSize: 14, color: Color(0xFF64748B))),
            if (district.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_on, size: 14, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 4),
                  Text(district, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                ],
              ),
            ],
            const SizedBox(height: 20),

            // Stats Row
            Row(
              children: [
                _StatBox(label: 'অভিজ্ঞতা', value: '$exp বছর', icon: Icons.work_outline_rounded),
                const SizedBox(width: 10),
                _StatBox(label: 'রেটিং', value: rating.toStringAsFixed(1), subValue: '($reviews)', icon: Icons.star_border_rounded),
                const SizedBox(width: 10),
                _StatBox(label: 'ফি', value: '৳${fee.toInt()}', icon: Icons.payments_outlined),
              ],
            ),
            const SizedBox(height: 24),

            // Bio
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('পরিচিতি', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  const SizedBox(height: 8),
                  Text(bio, style: const TextStyle(fontSize: 14, color: Color(0xFF475569), height: 1.5)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      context.push('/chat/$vetId?name=${Uri.encodeComponent('Dr. $name')}');
                    },
                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
                    label: const Text('চ্যাট করুন', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      foregroundColor: const Color(0xFF1565C0),
                      side: const BorderSide(color: Color(0xFF1565C0)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (isAvailable) {
                        context.push('/book-appointment/$vetId', extra: vet);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('চিকিৎসক বর্তমানে অনুপলব্ধ')));
                      }
                    },
                    icon: const Icon(Icons.calendar_month_rounded, size: 20),
                    label: const Text('বুক করুন', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: isAvailable ? const Color(0xFF1565C0) : const Color(0xFF94A3B8),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final String? subValue;
  final IconData icon;

  const _StatBox({required this.label, required this.value, this.subValue, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF1565C0), size: 22),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
                if (subValue != null) ...[
                  const SizedBox(width: 2),
                  Text(subValue!, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                ],
              ],
            ),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          ],
        ),
      ),
    );
  }
}
