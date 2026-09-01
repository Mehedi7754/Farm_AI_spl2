import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/network/api_client.dart';
import '../../../vet/presentation/screens/vet_profile_screen.dart';

final notificationSettingProvider = StateProvider<bool>((ref) => true);
final selectedLanguageProvider = StateProvider<String>((ref) => 'বাংলা (Bangla)');

final districtsProvider = FutureProvider<List<String>>((ref) async {
  return ApiClient.getDistricts();
});

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _showEditProfileModal(BuildContext context, WidgetRef ref, Map<String, dynamic>? user) {
    final nameCtrl = TextEditingController(text: user?['name']?.toString() ?? '');
    final phoneCtrl = TextEditingController(text: user?['phoneNumber']?.toString() ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, child) {
            final districtsAsync = ref.watch(districtsProvider);
            return districtsAsync.when(
              loading: () => const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, stack) => const SizedBox(
                height: 200,
                child: Center(child: Text('জেলা তালিকা লোড করা যায়নি।')),
              ),
              data: (districts) {
                if (districts.isEmpty) {
                  return const SizedBox(
                    height: 200,
                    child: Center(child: Text('কোনো জেলা তালিকা পাওয়া যায়নি।')),
                  );
                }

                String selectedDistrict = districts.contains(user?['location']?.toString())
                    ? user!['location'].toString()
                    : districts[0];
                String selectedFarmDistrict = districts.contains(user?['farmLocation']?.toString())
                    ? user!['farmLocation'].toString()
                    : selectedDistrict;

                return StatefulBuilder(
                  builder: (context, setModalState) {
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                        top: 20,
                        left: 20,
                        right: 20,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('ব্যক্তিগত তথ্য আপডেট করুন', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: nameCtrl,
                            decoration: const InputDecoration(labelText: 'নাম (Name)', border: OutlineInputBorder()),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: phoneCtrl,
                            decoration: const InputDecoration(labelText: 'ফোন নম্বর (Phone Number)', border: OutlineInputBorder()),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: selectedDistrict,
                            isExpanded: true,
                            decoration: const InputDecoration(labelText: 'ঠিকানা/জেলা (District)', border: OutlineInputBorder()),
                            items: districts.map((district) {
                              return DropdownMenuItem<String>(
                                value: district,
                                child: Text(district, style: const TextStyle(fontSize: 14)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setModalState(() {
                                  selectedDistrict = val;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: selectedFarmDistrict,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: '📍 খামারের অবস্থান (Farm Location for Weather)',
                              helperText: 'এই জেলার আবহাওয়া ও সেবা দেখাবে',
                              border: OutlineInputBorder(),
                            ),
                            items: districts.map((district) {
                              return DropdownMenuItem<String>(
                                value: district,
                                child: Text(district, style: const TextStyle(fontSize: 14)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setModalState(() {
                                  selectedFarmDistrict = val;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: () async {
                                Navigator.pop(ctx);
                                final updates = {
                                  if (nameCtrl.text.trim().isNotEmpty) 'name': nameCtrl.text.trim(),
                                  if (phoneCtrl.text.trim().isNotEmpty) 'phoneNumber': phoneCtrl.text.trim(),
                                  'location': selectedDistrict,
                                  'farmLocation': selectedFarmDistrict,
                                };

                                final ok = await ref.read(authProvider.notifier).updateProfile(updates);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(ok ? 'তথ্য সফলভাবে আপডেট করা হয়েছে।' : 'আপডেট ব্যর্থ হয়েছে।'),
                                      backgroundColor: ok ? const Color(0xFF1B5E20) : Colors.red,
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20)),
                              child: const Text('সংরক্ষণ করুন', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  void _showLanguageModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        final currentLang = ref.watch(selectedLanguageProvider);
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('ভাষা পরিবর্তন (Select Language)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 14),
              ListTile(
                title: const Text('বাংলা (Bangla)'),
                leading: Radio<String>(
                  value: 'বাংলা (Bangla)',
                  groupValue: currentLang,
                  onChanged: (val) {
                    if (val != null) {
                      ref.read(selectedLanguageProvider.notifier).state = val;
                      Navigator.pop(ctx);
                    }
                  },
                ),
                onTap: () {
                  ref.read(selectedLanguageProvider.notifier).state = 'বাংলা (Bangla)';
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                title: const Text('English'),
                leading: Radio<String>(
                  value: 'English',
                  groupValue: currentLang,
                  onChanged: (val) {
                    if (val != null) {
                      ref.read(selectedLanguageProvider.notifier).state = val;
                      Navigator.pop(ctx);
                    }
                  },
                ),
                onTap: () {
                  ref.read(selectedLanguageProvider.notifier).state = 'English';
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showRoleSwitchDialog(BuildContext context, WidgetRef ref, Map<String, dynamic>? user) {
    final currentRole = (user?['role'] ?? '').toString().toUpperCase();
    final targetRole = currentRole == 'VET' ? 'FARMER' : 'VET';
    final targetRoleName = targetRole == 'VET' ? 'পশু চিকিৎসক (Vet Doctor)' : 'কৃষক (Farmer)';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.swap_horiz_rounded, color: Color(0xFF1B5E20)),
            SizedBox(width: 8),
            Text('ভূমিকা পরিবর্তন', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'আপনি কি আপনার অ্যাকাউন্ট ভূমিকা "$targetRoleName"-এ পরিবর্তন করতে চান?',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('না', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20)),
            onPressed: () async {
              Navigator.pop(ctx);
              final userId = user?['id'];
              if (userId == null) return;
              try {
                final ok = await ref.read(authProvider.notifier).updateProfile({'role': targetRole});
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(ok ? 'অ্যাকাউন্ট ভূমিকা "$targetRoleName"-এ পরিবর্তন করা হয়েছে।' : 'পরিবর্তন ব্যর্থ হয়েছে।'),
                      backgroundColor: ok ? const Color(0xFF1B5E20) : Colors.red,
                    ),
                  );
                  if (ok && targetRole == 'VET') {
                    context.go('/vet-dashboard');
                  } else if (ok) {
                    context.go('/home');
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('ভূমিকা পরিবর্তন করা সম্ভব হয়নি।'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('হ্যাঁ, পরিবর্তন করুন', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final isNotiEnabled = ref.watch(notificationSettingProvider);
    final currentLang = ref.watch(selectedLanguageProvider);
    final user = authState.user;

    final userRole = (user?['role'] ?? '').toString().toUpperCase();
    if (userRole == 'VET') {
      return const VetProfileScreen();
    }

    final userName = user?['name']?.toString() ?? 'খামারি ভাই';
    final userPhone = user?['phoneNumber']?.toString() ?? user?['email']?.toString() ?? 'যোগাযোগের তথ্য পাওয়া যায়নি';
    final userLocation = user?['location']?.toString() ?? 'বাংলাদেশ';

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
              padding: const EdgeInsets.only(bottom: 30, top: 10),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: 46,
                      backgroundColor: Colors.white,
                      child: Text(
                        userName.length >= 2 ? userName.substring(0, 2).toUpperCase() : 'KB',
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: Colors.white70, size: 18),
                        onPressed: () => _showEditProfileModal(context, ref, user),
                      ),
                    ],
                  ),
                  Text(
                    userPhone,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            _buildProfileSection(context, 'আমার তথ্য', [
              _buildProfileItem(
                Icons.person_outline_rounded,
                'ব্যক্তিগত তথ্য',
                subtitle: '$userName ($userRole)',
                onTap: () => _showEditProfileModal(context, ref, user),
              ),
              _buildProfileItem(
                Icons.medical_services_outlined,
                'অ্যাকাউন্ট ভূমিকা/রোল পরিবর্তন',
                subtitle: userRole == 'VET' ? 'বর্তমান: পশু চিকিৎসক (Vet Doctor)' : 'বর্তমান: কৃষক (Farmer)',
                onTap: () => _showRoleSwitchDialog(context, ref, user),
              ),
              _buildProfileItem(
                Icons.location_on_outlined,
                'ঠিকানা (জেলা)',
                subtitle: userLocation,
                onTap: () => _showEditProfileModal(context, ref, user),
              ),
            ]),
            
            _buildProfileSection(context, 'সেটিংস', [
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F8E9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.notifications_none_rounded, color: Color(0xFF2E7D32), size: 20),
                ),
                title: const Text('নোটিফিকেশন', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF2C3E50))),
                subtitle: Text(isNotiEnabled ? 'চালু রয়েছে (Enabled)' : 'বন্ধ রয়েছে (Disabled)', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                trailing: Switch(
                  value: isNotiEnabled,
                  activeTrackColor: const Color(0xFF1B5E20),
                  onChanged: (val) {
                    ref.read(notificationSettingProvider.notifier).state = val;
                  },
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              ),
              _buildProfileItem(
                Icons.language_rounded,
                'ভাষা',
                subtitle: currentLang,
                onTap: () => _showLanguageModal(context, ref),
              ),
              _buildProfileItem(
                Icons.security_rounded,
                'নিরাপত্তা ও গোপনীয়তা',
                subtitle: 'পাসওয়ার্ড এবং সেশন সংরক্ষিত',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('আপনার তথ্য এন্ড-টু-এন্ড সুরক্ষিত রয়েছে।'), backgroundColor: Color(0xFF1B5E20)),
                  );
                },
              ),
            ]),
            
            _buildProfileSection(context, 'সহায়তা', [
              _buildProfileItem(
                Icons.help_outline_rounded,
                'হেল্প সেন্টার',
                subtitle: '২৪/৭ সাপোর্ট লাইন: ১৬৬৪৭',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('হেল্প হটলাইন: ১৬৬৪৭ কল করুন'), backgroundColor: Color(0xFF1B5E20)),
                  );
                },
              ),
              _buildProfileItem(
                Icons.info_outline_rounded,
                'আমাদের সম্পর্কে',
                subtitle: 'FarmAI v2.4 (EC2 Database Online)',
                onTap: () {},
              ),
            ]),
            
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ElevatedButton.icon(
                onPressed: () {
                  ref.read(authProvider.notifier).logout();
                  context.go('/login');
                },
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('লগ আউট করুন', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.red.shade700,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('ভার্সন ২.৪.০ (Live API Linked)', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            const Text('© ২০২৪ FarmAI. সর্বস্বত্ব সংরক্ষিত', style: TextStyle(color: Colors.grey, fontSize: 10)),
            const SizedBox(height: 30),
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
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 8),
          child: Text(
            title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20), letterSpacing: 0.5),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFF0F4F7)),
          ),
          child: Column(
            children: items,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileItem(IconData icon, String label, {String? subtitle, VoidCallback? onTap}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F8E9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFF2E7D32), size: 20),
      ),
      title: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF2C3E50))),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))) : null,
      trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFFBDC3C7)),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    );
  }
}
