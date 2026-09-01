import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/l10n/strings_bn.dart';
import '../../../../core/network/api_client.dart';
import '../widgets/auth_background.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();

  // Vet-specific
  final _licenseController = TextEditingController();
  final _feeController = TextEditingController();
  final _bioController = TextEditingController();

  String _selectedRole = 'FARMER';
  String _selectedSpecialization = 'গরু ও ছাগল';
  String _selectedDistrict = 'ঢাকা';
  bool _isLoading = false;
  String? _errorMessage;

  static const _specializations = [
    'গরু ও ছাগল',
    'পোল্ট্রি',
    'ভেড়া ও মহিষ',
    'সাধারণ পশু চিকিৎসা',
    'সার্জারি ও অস্ত্রোপচার',
  ];

  static const _districts = [
    'ঢাকা', 'চট্টগ্রাম', 'রাজশাহী', 'খুলনা', 'সিলেট',
    'বরিশাল', 'ময়মনসিংহ', 'রংপুর', 'কুমিল্লা', 'গাজীপুর',
    'বগুড়া', 'নারায়ণগঞ্জ', 'যশোর', 'পাবনা', 'ফরিদপুর',
  ];

  Future<void> _handleRegister() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'অনুগ্রহ করে নাম, ইমেইল এবং পাসওয়ার্ড প্রদান করুন।');
      return;
    }
    if (password.length < 6) {
      setState(() => _errorMessage = 'পাসওয়ার্ড অন্তত ৬ অক্ষরের হতে হবে।');
      return;
    }
    if (_selectedRole == 'VET' && _licenseController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'পশু চিকিৎসকের লাইসেন্স নম্বর প্রদান করুন।');
      return;
    }

    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      final res = await ApiClient.register(
        name: name,
        email: email,
        password: password,
        phone: phone.isEmpty ? null : phone,
        role: _selectedRole,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      final token = res['token'];
      final user = res['user'];

      if (token != null && user != null) {
        ApiClient.setAuthData(token as String, user as Map<String, dynamic>);

        // Create vet profile if VET
        if (_selectedRole == 'VET') {
          try {
            await ApiClient.createVetProfile(
              userId: user['id'] as String,
              licenseNumber: _licenseController.text.trim(),
              specialization: _selectedSpecialization,
              consultationFee: double.tryParse(_feeController.text.trim()) ?? 0,
              bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
              district: _selectedDistrict,
            );
          } catch (_) {}
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${res['message'] ?? "নিবন্ধন সফল হয়েছে!"}'),
            backgroundColor: const Color(0xFF2E7D32),
          ),
        );

        // Role-aware routing
        if (_selectedRole == 'VET') {
          context.go('/vet-dashboard');
        } else {
          context.go('/home');
        }
      } else {
        setState(() => _errorMessage = res['message'] ?? 'নিবন্ধন ব্যর্থ হয়েছে।');
      }
    } on ApiException catch (e) {
      if (mounted) setState(() { _isLoading = false; _errorMessage = e.message; });
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; _errorMessage = 'নেটওয়ার্ক সমস্যা। সংযোগ পরীক্ষা করুন।'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuthBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.97),
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 30, offset: const Offset(0, 15)),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset('assets/images/logo.png', height: 60),
                        const SizedBox(height: 12),
                        const Text(
                          'নিবন্ধন করুন',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                        ),
                        const SizedBox(height: 20),

                        // ── Role Selector ────────────────────────────────
                        _RoleSelector(
                          selected: _selectedRole,
                          onChanged: (r) => setState(() => _selectedRole = r),
                        ),
                        const SizedBox(height: 18),

                        // ── Error ────────────────────────────────────────
                        if (_errorMessage != null)
                          Container(
                            padding: const EdgeInsets.all(10),
                            margin: const EdgeInsets.only(bottom: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFFCA5A5)),
                            ),
                            child: Row(children: [
                              const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 18),
                              const SizedBox(width: 8),
                              Expanded(child: Text(_errorMessage!, style: const TextStyle(color: Color(0xFF991B1B), fontSize: 12, fontWeight: FontWeight.bold))),
                            ]),
                          ),

                        // ── Common Fields ────────────────────────────────
                        _buildTextField(controller: _nameController, label: StringsBn.nameLabel, icon: Icons.person_outline_rounded),
                        const SizedBox(height: 12),
                        _buildTextField(controller: _emailController, label: StringsBn.emailLabel, icon: Icons.email_outlined),
                        const SizedBox(height: 12),
                        _buildTextField(controller: _phoneController, label: 'মোবাইল নম্বর (ঐচ্ছিক)', icon: Icons.phone_outlined),
                        const SizedBox(height: 12),
                        _buildTextField(controller: _passwordController, label: StringsBn.passwordLabel, icon: Icons.lock_outline_rounded, isPassword: true),

                        // ── Vet-Specific Fields ──────────────────────────
                        if (_selectedRole == 'VET') ...[
                          const SizedBox(height: 18),
                          const Divider(color: Color(0xFFE0E6ED)),
                          const SizedBox(height: 10),
                          Row(children: const [
                            Icon(Icons.medical_services_rounded, color: Color(0xFF1565C0), size: 18),
                            SizedBox(width: 6),
                            Text('পশু চিকিৎসক তথ্য', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1565C0), fontSize: 13)),
                          ]),
                          const SizedBox(height: 12),
                          _buildTextField(controller: _licenseController, label: 'লাইসেন্স নম্বর *', icon: Icons.badge_outlined),
                          const SizedBox(height: 12),
                          _buildDropdown(
                            value: _selectedSpecialization,
                            label: 'বিশেষজ্ঞতা',
                            icon: Icons.biotech_rounded,
                            items: _specializations,
                            onChanged: (v) => setState(() => _selectedSpecialization = v!),
                          ),
                          const SizedBox(height: 12),
                          _buildDropdown(
                            value: _selectedDistrict,
                            label: 'জেলা',
                            icon: Icons.location_on_outlined,
                            items: _districts,
                            onChanged: (v) => setState(() => _selectedDistrict = v!),
                          ),
                          const SizedBox(height: 12),
                          _buildTextField(controller: _feeController, label: 'পরামর্শ ফি (টাকা)', icon: Icons.payments_outlined, keyboardType: TextInputType.number),
                          const SizedBox(height: 12),
                          _buildTextField(controller: _bioController, label: 'সংক্ষিপ্ত পরিচয় (ঐচ্ছিক)', icon: Icons.notes_rounded, maxLines: 2),
                        ],

                        const SizedBox(height: 22),

                        ElevatedButton(
                          onPressed: _isLoading ? null : _handleRegister,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _selectedRole == 'VET' ? const Color(0xFF1565C0) : const Color(0xFF2E7D32),
                            minimumSize: const Size(double.infinity, 52),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Text(
                                  _selectedRole == 'VET' ? 'ভেটেরিনারি অ্যাকাউন্ট তৈরি করুন' : StringsBn.registerButton,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                        ),
                        const SizedBox(height: 16),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(StringsBn.haveAccount, style: TextStyle(color: Color(0xFF7F8C8D))),
                            TextButton(
                              onPressed: () => context.go('/login'),
                              child: const Text(StringsBn.loginButton, style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF7F8C8D), fontSize: 13),
        prefixIcon: Icon(icon, color: const Color(0xFF2E7D32), size: 20),
        filled: true,
        fillColor: const Color(0xFFF8F9FA),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE0E6ED), width: 1)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required String label,
    required IconData icon,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF7F8C8D), fontSize: 13),
        prefixIcon: Icon(icon, color: const Color(0xFF2E7D32), size: 20),
        filled: true,
        fillColor: const Color(0xFFF8F9FA),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE0E6ED), width: 1)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      ),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _licenseController.dispose();
    _feeController.dispose();
    _bioController.dispose();
    super.dispose();
  }
}

// ── Role Selector Widget ─────────────────────────────────────────────────────

class _RoleSelector extends StatelessWidget {
  final String selected;
  final void Function(String) onChanged;

  const _RoleSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _roleTab('FARMER', 'কৃষক', Icons.agriculture_rounded, const Color(0xFF2E7D32)),
          _roleTab('VET', 'পশু চিকিৎসক', Icons.local_hospital_rounded, const Color(0xFF1565C0)),
        ],
      ),
    );
  }

  Widget _roleTab(String role, String label, IconData icon, Color activeColor) {
    final isActive = selected == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(role),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: isActive
                ? [BoxShadow(color: activeColor.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 3))]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isActive ? Colors.white : const Color(0xFF64748B)),
              const SizedBox(width: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isActive ? Colors.white : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
