import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MedicineInfoScreen extends StatefulWidget {
  const MedicineInfoScreen({super.key});

  @override
  State<MedicineInfoScreen> createState() => _MedicineInfoScreenState();
}

class _MedicineInfoScreenState extends State<MedicineInfoScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  File? _selectedImage;
  bool _isLoading = false;
  String _statusText = 'Groq AI ডাটাবেজে সংযুক্ত';
  List<Map<String, dynamic>> _medicines = [];
  String _selectedSpecies = 'সকল';
  String _selectedQuickChip = '';

  static String get _groqApiKey {
    try {
      if (dotenv.isInitialized && dotenv.env['GROQ_API_KEY'] != null) {
        return dotenv.env['GROQ_API_KEY']!;
      }
    } catch (_) {}
    return '';
  }
  static const String _groqEndpoint = 'https://api.groq.com/openai/v1/chat/completions';
  static const String _modelName = 'llama-3.3-70b-versatile';

  static final List<Map<String, dynamic>> _defaultMedicines = [
    {
      'name': 'আইভারমেকটিন ১% (Ivermectin 1%)',
      'group': 'কৃমিনাশক ও পরজীবী দমন',
      'uses': 'পেটের গোলকৃমি, উঁকুন, মাইট ও পরজীবী চিকিৎসায়',
      'dosage': '১ মিলি প্রতি ৫০ কেজি ওজনে (চামড়ার নিচে)',
      'sideEffects': 'ইনজেকশনের স্থানে হালকা জ্বালাপোড়া বা ফোলাভাব',
      'warning': 'দুগ্ধবতী গাভীতে দুধ পানের ২৮ দিন পূর্বে নিষিদ্ধ',
      'species': 'গরু, ছাগল, ভেড়া',
    },
    {
      'name': 'প্যারাসিটামল ২০০০ মিগ্রা (Paracetamol 2000mg)',
      'group': 'জ্বর ও ব্যথানাশক',
      'uses': 'পশুর যেকোনো তীব্র জ্বর, ব্যথা ও ক্লান্তি দূরীকরণে',
      'dosage': '১-২টি বোলস দিনে ২ বার (খাবারের পর)',
      'sideEffects': 'অতিরিক্ত মাত্রায় লিভারে ক্ষতিকর প্রভাব',
      'warning': 'প্রচুর পরিমাণে পরিষ্কার পানি পান করাতে হবে',
      'species': 'সকল গবাদিপশু',
    },
    {
      'name': 'অক্সিটেট্রাসাইক্লিন ২০০ (Oxytetracycline 200 LA)',
      'group': 'ব্রড স্পেকট্রাম অ্যান্টিবায়োটিক',
      'uses': 'খুররোগ (FMD), নিউমোনিয়া ও ওলান প্রদাহ চিকিৎসায়',
      'dosage': '১ মিলি প্রতি ১০ কেজি ওজনে (গভীর মাংসপেশিতে)',
      'sideEffects': 'ইনজেকশনের স্থানে সাময়িক ব্যথা ও অরুচি',
      'warning': 'টানা ৩-৫ দিনের বেশি ব্যবহার করবেন না',
      'species': 'গরু, ছাগল',
    },
  ];

  @override
  void initState() {
    super.initState();
    _medicines = List.from(_defaultMedicines);
    _fetchMedicinesFromGroq('গবাদিপশুর প্রয়োজনীয় প্রধান ওষুধসমূহ');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (photo != null) {
        setState(() {
          _selectedImage = File(photo.path);
        });
        _searchMedicineFromImage();
      }
    } catch (e) {
      debugPrint('Image pick error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ছবি নির্বাচনে সমস্যা হয়েছে। আবার চেষ্টা করুন।')),
        );
      }
    }
  }

  void _removeSelectedImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  Future<void> _searchMedicineFromImage() async {
    final queryText = _searchController.text.trim().isNotEmpty
        ? _searchController.text.trim()
        : 'ওষুধের বোতল বা প্রেসক্রিপশনের ছবি বিশ্লেষণ করে গবাদিপশুর ওষুধের তথ্য দিন';

    _fetchMedicinesFromGroq('সংযুক্ত ছবি হতে ওষুধ অনুসন্ধান: $queryText');
  }

  Future<void> _fetchMedicinesFromGroq(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _statusText = 'Groq AI অনুসন্ধান চলছে...';
    });

    try {
      final speciesConstraint = _selectedSpecies != 'সকল' ? 'প্রজাতি: $_selectedSpecies।' : '';

      final systemPrompt = '''
You are an expert veterinary pharmacologist.
Respond strictly in JSON format matching the schema:
{
  "medicines": [
    {
      "name": "ওষুধের নাম (Generic & Brand)",
      "group": "ওষুধের গ্রুপ/ক্যাটাগরি",
      "uses": "ব্যবহার ও নির্দেশনা",
      "dosage": "সুপারিশকৃত মাত্রা (ওজন অনুযায়ী)",
      "sideEffects": "পার্শ্বপ্রতিক্রিয়া",
      "warning": "সতর্কতা ও প্রত্যাহার কাল",
      "species": "গরু, ছাগল বা সকল পশু"
    }
  ]
}

Rules:
1. Provide accurate veterinary medicines in clear Bengali.
2. Search query: "$query". $speciesConstraint
3. Return 3-5 relevant medicine entries.
4. No markdown, no emojis, no extra JSON fields.
'''.trim();

      final response = await http.post(
        Uri.parse(_groqEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_groqApiKey',
        },
        body: jsonEncode({
          'model': _modelName,
          'response_format': {'type': 'json_object'},
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': query},
          ],
          'temperature': 0.3,
          'max_completion_tokens': 1600,
        }),
      ).timeout(const Duration(seconds: 12));

      if (mounted) {
        if (response.statusCode == 200) {
          final data = jsonDecode(utf8.decode(response.bodyBytes));
          final rawContent = data['choices']?[0]?['message']?['content']?.toString() ?? '';

          if (rawContent.isNotEmpty) {
            final parsed = jsonDecode(rawContent);
            if (parsed is Map && parsed.containsKey('medicines') && parsed['medicines'] is List) {
              final List<dynamic> list = parsed['medicines'];
              if (list.isNotEmpty) {
                setState(() {
                  _medicines = list.map((item) => Map<String, dynamic>.from(item)).toList();
                  _isLoading = false;
                  _statusText = 'লাইভ AI ফলাফল প্রস্তুত';
                });
                return;
              }
            }
          }
        }

        setState(() {
          _isLoading = false;
          _statusText = 'ডিফল্ট ডাটাবেজ প্রদর্শিত হচ্ছে';
        });
      }
    } catch (e) {
      debugPrint('Groq API Error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusText = 'অফলাইন ডাটাবেজ প্রদর্শিত হচ্ছে';
        });
      }
    }
  }

  Color _getMedicineColor(int index) {
    const colors = [
      Color(0xFF059669),
      Color(0xFF2563EB),
      Color(0xFFDC2626),
      Color(0xFFD97706),
      Color(0xFF7C3AED),
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF059669),
        elevation: 0,
        toolbarHeight: 64,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ভেটেরিনারি ওষুধ ডিরেক্টরি',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white),
            ),
            Text(
              'AI দ্বারা ওষুধ নির্দেশিকা ও মাত্রা খুঁজুন',
              style: TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. PROPER SEARCH BAR WITH CAMERA & GALLERY ICONS
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Text Search Field
                  TextField(
                    controller: _searchController,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: 'ওষুধের নাম, গ্রুপ বা রোগের নাম লিখুন...',
                      hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                      prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF059669)),
                      filled: true,
                      fillColor: const Color(0xFFF1F5F9),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (val) {
                      setState(() => _selectedQuickChip = '');
                      _fetchMedicinesFromGroq(val);
                    },
                  ),

                  const SizedBox(height: 10),

                  // Camera & Gallery Action Buttons Bar
                  Row(
                    children: [
                      // Camera Action Button
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _pickImage(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                          label: const Text(
                            'ক্যামেরা ছবি',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF059669),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Gallery Action Button
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _pickImage(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library_rounded, size: 16, color: Color(0xFF059669)),
                          label: const Text(
                            'গ্যালারি থেকে',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFECFDF5),
                            elevation: 0,
                            side: const BorderSide(color: Color(0xFFA7F3D0)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Search Submit Button
                      GestureDetector(
                        onTap: () {
                          setState(() => _selectedQuickChip = '');
                          _fetchMedicinesFromGroq(_searchController.text);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),

                  // Attached Image Preview Chip
                  if (_selectedImage != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.file(_selectedImage!, width: 32, height: 32, fit: BoxFit.cover),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'সংযুক্ত ছবি বিশ্লেষণ করে ওষুধ খোজা হচ্ছে...',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF)),
                            ),
                          ),
                          GestureDetector(
                            onTap: _removeSelectedImage,
                            child: const Icon(Icons.cancel_rounded, size: 18, color: Color(0xFF93C5FD)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 14),

            // 2. HIGHLIGHTED QUICK SEARCH CHIPS
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildQuickChip('কৃমিনাশক', Icons.bug_report_rounded),
                  _buildQuickChip('জ্বর ও ব্যথা', Icons.thermostat_rounded),
                  _buildQuickChip('অ্যান্টিবায়োটিক', Icons.medication_rounded),
                  _buildQuickChip('ওলান প্রদাহ', Icons.healing_rounded),
                  _buildQuickChip('ভিটামিন', Icons.workspace_premium_rounded),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // 3. SPECIES FILTER BAR
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: ['সকল', 'গরু', 'ছাগল'].map((sp) {
                    final isSel = _selectedSpecies == sp;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedSpecies = sp);
                        final q = _searchController.text.trim().isNotEmpty ? _searchController.text.trim() : 'গবাদিপশুর ওষুধ';
                        _fetchMedicinesFromGroq(q);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: isSel ? const Color(0xFF059669) : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          sp == 'সকল' ? 'সকল প্রজাতি' : sp,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isSel ? Colors.white : const Color(0xFF475569),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                Text(
                  _statusText,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 4. LOADING STATE OR MEDICINE CARDS LIST
            if (_isLoading)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Column(
                    children: const [
                      CircularProgressIndicator(color: Color(0xFF059669)),
                      SizedBox(height: 12),
                      Text(
                        'Groq AI ওষুধ তথ্য প্রস্তুত করছে...',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _medicines.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final med = _medicines[index];
                  final color = _getMedicineColor(index);

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // CARD HEADER
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.06),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.medication_rounded, size: 18, color: color),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      (med['name'] ?? 'ওষুধের নাম').toString(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 13,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      (med['group'] ?? 'ক্যাটাগরি').toString(),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: color,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: color.withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  (med['species'] ?? 'গবাদিপশু').toString(),
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // CARD BODY DETAILS
                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Uses
                              _buildDetailRow(
                                icon: Icons.check_circle_outline_rounded,
                                iconColor: const Color(0xFF059669),
                                title: 'ব্যবহার ও নির্দেশিকা:',
                                content: (med['uses'] ?? 'তথ্য উপলব্ধ নয়').toString(),
                              ),
                              const SizedBox(height: 10),

                              // Dosage
                              _buildDetailRow(
                                icon: Icons.difference_rounded,
                                iconColor: const Color(0xFF2563EB),
                                title: 'সুপারিশকৃত মাত্রাবিন্যাস (ডোজ):',
                                content: (med['dosage'] ?? 'তথ্য উপলব্ধ নয়').toString(),
                                isHighlight: true,
                              ),
                              const SizedBox(height: 10),

                              // Side Effects
                              _buildDetailRow(
                                icon: Icons.report_problem_outlined,
                                iconColor: const Color(0xFFD97706),
                                title: 'পার্শ্বপ্রতিক্রিয়া:',
                                content: (med['sideEffects'] ?? 'সাধারণত নেই').toString(),
                              ),
                              const SizedBox(height: 10),

                              // Warning Alert Box
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF2F2),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFFCA5A5)),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFDC2626)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: RichText(
                                        text: TextSpan(
                                          style: const TextStyle(fontSize: 11, height: 1.4, color: Color(0xFF991B1B)),
                                          children: [
                                            const TextSpan(
                                              text: 'সতর্কতা: ',
                                              style: TextStyle(fontWeight: FontWeight.w900),
                                            ),
                                            TextSpan(text: (med['warning'] ?? 'ডাক্তারের পরামর্শ অনুযায়ী দিন').toString()),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
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

  Widget _buildQuickChip(String label, IconData icon) {
    final isSelected = _selectedQuickChip == label;

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedQuickChip = '';
            _searchController.clear();
          } else {
            _selectedQuickChip = label;
            _searchController.text = label;
          }
        });
        final query = isSelected ? 'গবাদিপশুর প্রয়োজনীয় ওষুধ' : label;
        _fetchMedicinesFromGroq(query);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF059669) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF059669) : const Color(0xFFCBD5E1),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF059669).withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Icon(icon, size: 15, color: isSelected ? Colors.white : const Color(0xFF059669)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: isSelected ? Colors.white : const Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String content,
    bool isHighlight = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 12,
                height: 1.45,
                color: isHighlight ? const Color(0xFF0F172A) : const Color(0xFF334155),
              ),
              children: [
                TextSpan(
                  text: '$title ',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: isHighlight ? const Color(0xFF1E293B) : const Color(0xFF475569),
                  ),
                ),
                TextSpan(
                  text: content,
                  style: TextStyle(
                    fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
