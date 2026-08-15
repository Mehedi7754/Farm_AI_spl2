import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_client.dart';

class TeleVetScreen extends StatefulWidget {
  const TeleVetScreen({super.key});

  @override
  State<TeleVetScreen> createState() => _TeleVetScreenState();
}

class _TeleVetScreenState extends State<TeleVetScreen> {
  List<Map<String, dynamic>> _vets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVets();
  }

  Future<void> _loadVets() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiClient.getVets();
      if (mounted) {
        setState(() {
          _vets = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: AppBar(
          backgroundColor: const Color(0xFF064E3B),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          title: const Text(
            'টেলি-ভেটেরিনারি (TeleVet)',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              onPressed: _loadVets,
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadVets,
        color: const Color(0xFF064E3B),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. TELEVET HERO BANNER
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF064E3B), Color(0xFF047857)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'সরাসরি ডাক্তারের পরামর্শ নিন',
                            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'নিবন্ধিত বিশেষজ্ঞ ভেটেরিনারি ডাক্তারদের সাথে অ্যাপয়েন্টমেন্ট বুকিং ও সরাসরি চ্যাট করুন',
                            style: TextStyle(color: Colors.white70, fontSize: 10),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () => context.push('/find-vet'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFDE047),
                              foregroundColor: const Color(0xFF064E3B),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.calendar_month_rounded, size: 16),
                            label: const Text(
                              'অ্যাপয়েন্টমেন্ট বুক করুন',
                              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.medical_services_rounded, color: Colors.white38, size: 56),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 2. REGISTERED VET DOCTORS LIST HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'নিবন্ধিত পশু চিকিৎসকবৃন্দ',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF0F172A)),
                  ),
                  Text(
                    'মোট ${_vets.length} জন',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // 3. VET DOCTORS LIST
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(color: Color(0xFF064E3B)),
                  ),
                )
              else if (_vets.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(Icons.person_search_rounded, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 10),
                        const Text(
                          'বর্তমানে কোনো নিবন্ধিত ডাক্তার পাওয়া যায়নি',
                          style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _vets.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final profile = _vets[index];
                    final user = profile['user'] as Map<String, dynamic>? ?? {};
                    final name = user['name'] ?? 'চিকিৎসক';
                    final specialization = profile['specialization'] ?? 'সাধারণ চিকিৎসা';
                    final district = profile['district'] ?? '';
                    final fee = profile['consultationFee'] != null ? '৳${profile['consultationFee']}' : '৳২০০';
                    final expYears = profile['experienceYears'] != null ? '${profile['experienceYears']} বছর অভিজ্ঞতা' : 'অভিজ্ঞ চিকিৎসক';
                    final vetUserId = profile['userId'] as String? ?? user['id'] as String? ?? '';

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: const Color(0xFFECFDF5),
                                child: Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : 'V',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF064E3B), fontSize: 16),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Dr. $name',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                                    ),
                                    Text(
                                      specialization,
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF047857), fontWeight: FontWeight.bold),
                                    ),
                                    if (district.isNotEmpty)
                                      Text(
                                        district,
                                        style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                                      ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    fee,
                                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF064E3B)),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    expYears,
                                    style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    if (vetUserId.isNotEmpty) {
                                      context.push('/chat/$vetUserId?name=${Uri.encodeComponent('Dr. $name')}');
                                    }
                                  },
                                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                                  label: const Text('চ্যাট করুন', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Color(0xFF047857)),
                                    foregroundColor: const Color(0xFF047857),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => context.push('/find-vet'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF064E3B),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  icon: const Icon(Icons.calendar_month_rounded, size: 16),
                                  label: const Text('বুকিং দিন', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
