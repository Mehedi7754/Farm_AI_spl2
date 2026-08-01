import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TeleVetScreen extends StatefulWidget {
  const TeleVetScreen({super.key});

  @override
  State<TeleVetScreen> createState() => _TeleVetScreenState();
}

class _TeleVetScreenState extends State<TeleVetScreen> {
  final List<Map<String, dynamic>> _vets = [
    {
      'name': 'ডাঃ মোঃ রফিকুল ইসলাম',
      'title': 'সিনিয়র ভেটেরিনারি সার্জন (BAU)',
      'exp': '১২ বছর অভিজ্ঞতা',
      'fee': '৳৩০০',
      'rating': 4.9,
      'isOnline': true,
      'specialty': 'গবাদিপশু প্রজনন ও দুগ্ধ রোগ বিশেষজ্ঞ',
    },
    {
      'name': 'ডাঃ সুমাইয়া আক্তার',
      'title': 'প্রাণিসম্পদ গবেষণা কর্মকর্তা',
      'exp': '৮ বছর অভিজ্ঞতা',
      'fee': '৳২৫০',
      'rating': 4.8,
      'isOnline': true,
      'specialty': 'ছাগল ও ভেড়ার সংক্রামক ব্যাধি',
    },
    {
      'name': 'ডাঃ কামরুল হাসান',
      'title': 'সার্জন কর্মকর্তা (বিসিএস প্রাণিসম্পদ)',
      'exp': '১৫ বছর অভিজ্ঞতা',
      'fee': '৳৪০০',
      'rating': 4.9,
      'isOnline': false,
      'specialty': 'জরুরি সার্জারি ও পুষ্টি বিশেষজ্ঞ',
    },
  ];

  void _startVideoCall(String vetName) {
    final roomId = 'room_televet_${DateTime.now().millisecondsSinceEpoch}';
    context.push('/video-call/$roomId');
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
            'অনলাইন টেলি-ভেটেরিনারি (TeleVet)',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white),
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. TELEVET HERO BANNER WITH INSTANT CALL TRIGGER
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
                        const Text('সরাসরি ভিডিও কলে ডাক্তারের পরামর্শ নিন', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        const Text('২৪ ঘণ্টা বিশেষজ্ঞ ভেটেরিনারি সার্জনদের সাথে সরাসরি ভিডিও কথা বলুন', style: TextStyle(color: Colors.white70, fontSize: 10)),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () => _startVideoCall('ডাঃ মোঃ রফিকুল ইসলাম'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFDE047),
                            foregroundColor: const Color(0xFF064E3B),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.video_call_rounded, size: 18),
                          label: const Text('জরুরি ভিডিও কল (৳৩০০)', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.medical_services_rounded, color: Colors.white38, size: 60),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 2. ONLINE VET DOCTORS LIST HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('অনলাইন ডাক্তারদের তালিকা', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF0F172A))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(10)),
                  child: const Text('২ জন সক্রিয়', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // 3. VET DOCTORS CARDS
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _vets.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final vet = _vets[index];
                final isOnline = vet['isOnline'] as bool;

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: const Color(0xFFE2E8F0),
                                child: Text(vet['name'].toString().substring(3, 4), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF064E3B))),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: isOnline ? const Color(0xFF059669) : const Color(0xFF94A3B8),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(vet['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
                                Text(vet['title'] as String, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                                Text(vet['specialty'] as String, style: const TextStyle(fontSize: 9, color: Color(0xFF059669), fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(vet['fee'] as String, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF064E3B))),
                              Row(
                                children: [
                                  const Icon(Icons.star_rounded, color: Color(0xFFEAB308), size: 14),
                                  Text('${vet['rating']}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(vet['exp'] as String, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                          ElevatedButton.icon(
                            onPressed: isOnline ? () => _startVideoCall(vet['name'] as String) : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF064E3B),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.videocam_rounded, color: Colors.white, size: 14),
                            label: Text(
                              isOnline ? 'ভিডিও কল করুন' : 'অফলাইন',
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
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
    );
  }
}
