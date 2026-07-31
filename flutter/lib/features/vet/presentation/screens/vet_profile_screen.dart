import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_client.dart';

class VetProfileScreen extends StatefulWidget {
  const VetProfileScreen({super.key});

  @override
  State<VetProfileScreen> createState() => _VetProfileScreenState();
}

class _VetProfileScreenState extends State<VetProfileScreen> {
  final _licenseCtrl = TextEditingController();
  final _specializationCtrl = TextEditingController();
  final _experienceCtrl = TextEditingController();
  final _feeCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final user = ApiClient.currentUser;
      if (user != null) {
        final profile = await ApiClient.getVetProfile(user['id']);
        if (profile.isNotEmpty) {
          _licenseCtrl.text = profile['licenseNumber'] ?? '';
          _specializationCtrl.text = profile['specialization'] ?? 'সাধারণ গবাদিপশু চিকিৎসা';
          _experienceCtrl.text = (profile['experienceYears'] ?? 5).toString();
          _feeCtrl.text = (profile['consultationFee'] ?? 300.0).toString();
          _bioCtrl.text = profile['bio'] ?? '';
          _districtCtrl.text = profile['district'] ?? 'বগুড়া';
        }
      }
    } catch (_) {
      // Default initial values
      _specializationCtrl.text = 'সাধারণ গবাদিপশু চিকিৎসা (General Vet)';
      _experienceCtrl.text = '5';
      _feeCtrl.text = '300';
      _districtCtrl.text = 'বগুড়া';
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    final user = ApiClient.currentUser;
    if (user == null) return;

    if (_licenseCtrl.text.trim().isEmpty || _specializationCtrl.text.trim().isEmpty) {
      setState(() => _errorMessage = 'লাইসেন্স নম্বর এবং বিশেষত্ব প্রদান করা আবশ্যক');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await ApiClient.createVetProfile(
        userId: user['id'],
        licenseNumber: _licenseCtrl.text.trim(),
        specialization: _specializationCtrl.text.trim(),
        experienceYears: int.tryParse(_experienceCtrl.text.trim()) ?? 3,
        consultationFee: double.tryParse(_feeCtrl.text.trim()) ?? 300.0,
        bio: _bioCtrl.text.trim(),
        district: _districtCtrl.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('চিকিৎসক প্রোফাইল সফলভাবে আপডেট করা হয়েছে'),
            backgroundColor: Color(0xFF059669),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = 'প্রোফাইল আপডেট করতে ব্যর্থ হয়েছে: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ApiClient.currentUser;
    final name = user?['name'] ?? 'ডাঃ মোঃ রফিকুল ইসলাম';
    final email = user?['email'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text('পশু চিকিৎসক প্রোফাইল', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1565C0)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Header Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: const Color(0xFFE0F2FE),
                          child: const Icon(Icons.medical_services_rounded, color: Color(0xFF1565C0), size: 32),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
                              Text(email, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text('নিবন্ধিত পশু চিকিৎসক (Verified Vet)', style: TextStyle(fontSize: 10, color: Color(0xFF15803D), fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFFCA5A5))),
                      child: Text(_errorMessage!, style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12, fontWeight: FontWeight.bold)),
                    ),

                  const Text('পেশাগত তথ্য', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  const SizedBox(height: 10),

                  _field('লাইসেন্স নম্বর (License Number)', _licenseCtrl, Icons.badge_outlined, 'যেমন: VET-BD-8902'),
                  const SizedBox(height: 12),
                  _field('বিশেষত্ব (Specialization)', _specializationCtrl, Icons.medical_information_outlined, 'যেমন: গবাদিপশু সার্জারি ও প্রজনন'),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(child: _field('অভিজ্ঞতা (বছর)', _experienceCtrl, Icons.work_outline_rounded, '5', isNumber: true)),
                      const SizedBox(width: 12),
                      Expanded(child: _field('পরামর্শ ফি (টাকা)', _feeCtrl, Icons.payments_outlined, '300', isNumber: true)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  _field('জেলা / চেম্বার এলাকা', _districtCtrl, Icons.location_on_outlined, 'বগুড়া'),
                  const SizedBox(height: 12),

                  _field('নিজের বিবরণ (Bio / Notes)', _bioCtrl, Icons.notes_rounded, 'বাংলাদেশ কৃষি বিশ্ববিদ্যালয় থেকে ডিগ্রি প্রাপ্ত...', maxLines: 3),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1565C0),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: _isSaving
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                      label: Text(_isSaving ? 'সংরক্ষণ করা হচ্ছে...' : 'প্রোফাইল সংরক্ষণ করুন', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, IconData icon, String hint, {bool isNumber = false, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
            prefixIcon: Icon(icon, size: 20, color: const Color(0xFF1565C0)),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
          ),
        ),
      ],
    );
  }
}
