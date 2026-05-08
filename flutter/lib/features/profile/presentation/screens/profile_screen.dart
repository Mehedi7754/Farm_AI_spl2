import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBF9),
      appBar: AppBar(
        title: const Text('প্রোফাইল', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF1B5E20),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF1B5E20),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
              ),
              padding: const EdgeInsets.only(bottom: 40, top: 10),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person_rounded, size: 60, color: Color(0xFF2E7D32)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'মোঃ আব্দুর রহমান',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '+৮৮০ ১৭০০-০০০০০০',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            _buildProfileSection(context, 'আমার তথ্য', [
              _buildProfileItem(Icons.person_outline_rounded, 'ব্যক্তিগত তথ্য'),
              _buildProfileItem(Icons.location_on_outlined, 'ঠিকানা'),
            ]),
            
            _buildProfileSection(context, 'সেটিংস', [
              _buildProfileItem(Icons.notifications_none_rounded, 'নোটিফিকেশন'),
              _buildProfileItem(Icons.language_rounded, 'ভাষা'),
              _buildProfileItem(Icons.security_rounded, 'নিরাপত্তা'),
            ]),
            
            _buildProfileSection(context, 'সহায়তা', [
              _buildProfileItem(Icons.help_outline_rounded, 'হেল্প সেন্টার'),
              _buildProfileItem(Icons.info_outline_rounded, 'আমাদের সম্পর্কে'),
            ]),
            
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.red,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('লগ আউট করুন', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 32),
            const Text('ভার্সন ২.৪.০', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            const Text('© ২০২৪ FarmAI. সর্বস্বত্ব সংরক্ষিত', style: TextStyle(color: Colors.grey, fontSize: 11)),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context, String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          child: Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20), letterSpacing: 0.5),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF0F4F7)),
          ),
          child: Column(
            children: items,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileItem(IconData icon, String label) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F8E9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFF2E7D32), size: 20),
      ),
      title: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF2C3E50))),
      trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFFBDC3C7)),
      onTap: () {},
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}
