import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/network/api_client.dart';

final communityCategoryFilterProvider = StateProvider<String>((ref) => 'সবগুলো');

class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen> {
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;
  List<Map<String, dynamic>> _posts = [
    {
      'id': '1',
      'title': 'গাভীর দুধের শর্করা ও প্রোটিন বৃদ্ধির ঘরোয়া উপায়',
      'content': 'আপনার খামারের দুগ্ধজাত গাভীর দুধের পরিমাণ ও ফ্যাটের ঘনত্ব বাড়াতে প্রতিদিন ঘাসের সাথে ১.৫ কেজি দানাদার খাদ্য ও খৈল মেশান। এতে দুধের মান আশাতীত বৃদ্ধি পায়।',
      'category': 'টিপস',
      'authorName': 'ফারমার রহিম উল্লাহ',
      'authorLocation': 'বগুড়া সদর খামার',
      'isVerified': true,
      'likes': 24,
      'isLiked': false,
      'comments': [
        {'id': 'c1', 'authorName': 'ডাঃ সালাহউদ্দিন (ভেটেরিনারি)', 'content': 'খুবই উপকারী উপদেশ! পাশাপাশি পর্যাপ্ত পরিষ্কার পানি নিশ্চিত করতে হবে।'},
        {'id': 'c2', 'authorName': 'মোঃ খলিল', 'content': 'আমি এই ফর্মুলা ব্যবহার করে দিনে ৩ লিটার দুধ বেশি পাচ্ছি।'},
      ],
      'imageUrl': null,
      'createdAt': '২ ঘণ্টা আগে',
    },
    {
      'id': '2',
      'title': 'বর্ষাকালে খুরা রোগ (FMD) প্রতিরোধে খামারিদের করণীয়',
      'content': 'বর্ষা মৌসুমে খামারের মেঝেসহ শেড শুকনো রাখুন। নিয়মিত ব্লিচিং পাউডার স্প্রে করুন এবং ভ্যাকসিনের ১ম ও ২য় ডোজ সঠিক সময়ে সম্পন্ন করুন।',
      'category': 'স্বাস্থ্য',
      'authorName': 'ডাঃ তানজিল হোসেন',
      'authorLocation': 'পশু চিকিৎসক',
      'isVerified': true,
      'likes': 42,
      'isLiked': true,
      'comments': [
        {'id': 'c3', 'authorName': 'আব্দুল জলিল', 'content': 'আমাদের এলাকায় এখন খুরা রোগের প্রাদুর্ভাব চলছে, সবাই সচেতন থাকুন।'},
      ],
      'imageUrl': null,
      'createdAt': '৫ ঘণ্টা আগে',
    },
    {
      'id': '3',
      'title': 'ব্ল্যাক বেঙ্গল ছাগলের নতুন বাচ্চার খামার ব্যবস্থাপনা',
      'content': 'আজ সকালে ছাগল দুটি সুস্থ বাচ্চা প্রসব করেছে। মা ও বাচ্চা দুটোই সুস্থ আছে। প্রথম কয়েক দিন কোলস্ট্রাম শালদুধ খাওয়ানো অত্যন্ত জরুরি।',
      'category': 'গল্প',
      'authorName': 'নাসিমা বেগম',
      'authorLocation': 'পাবনা ডেইরি খামার',
      'isVerified': false,
      'likes': 68,
      'isLiked': false,
      'comments': [
        {'id': 'c4', 'authorName': 'মাশরাফি', 'content': 'উৎকৃষ্ট ব্যবস্থাপনা! অভিনন্দন।'},
      ],
      'imageUrl': null,
      'createdAt': '১ দিন আগে',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadApiPosts();
  }

  int _parseLikesCount(dynamic likes) {
    if (likes == null) return 0;
    if (likes is int) return likes;
    if (likes is num) return likes.toInt();
    if (likes is List) return likes.length;
    return 0;
  }

  List<Map<String, dynamic>> _parseCommentsList(dynamic comments) {
    if (comments == null) return [];
    if (comments is List) {
      return comments.map<Map<String, dynamic>>((c) {
        if (c is Map) return Map<String, dynamic>.from(c);
        return {'content': c.toString(), 'authorName': 'খামারি সদস্য'};
      }).toList();
    }
    return [];
  }

  Future<void> _loadApiPosts() async {
    setState(() => _isLoading = true);
    try {
      final fetched = await ApiClient.getCommunityPosts();
      if (fetched.isNotEmpty) {
        setState(() {
          for (final p in fetched) {
            final id = p['id']?.toString() ?? UniqueKey().toString();
            // Prevent duplicate insertion
            if (_posts.any((item) => item['id'] == id)) continue;

            final rawLikes = p['likes'] ?? p['likesCount'];
            final rawComments = p['comments'];

            _posts.add({
              'id': id,
              'title': p['title']?.toString() ?? 'খামারি আপডেট',
              'content': p['content']?.toString() ?? '',
              'category': p['category']?.toString() ?? 'টিপস',
              'authorName': p['author']?['name']?.toString() ?? p['authorName']?.toString() ?? 'খামারি সদস্য',
              'authorLocation': p['author']?['location']?.toString() ?? 'ফার্ম এআই খামার',
              'isVerified': p['author']?['isDoctor'] == true,
              'likes': _parseLikesCount(rawLikes),
              'isLiked': p['isLiked'] == true,
              'comments': _parseCommentsList(rawComments),
              'imageUrl': p['imageUrl']?.toString(),
              'createdAt': 'সাম্প্রতিক পোস্ট',
            });
          }
        });
      }
    } catch (e) {
      debugPrint('Community API fetch fallback: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showCreatePostModal() {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    String selectedCategory = 'টিপস';
    File? selectedImageFile;
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> pickImage(ImageSource source) async {
              try {
                final picked = await _picker.pickImage(source: source);
                if (picked != null) {
                  setModalState(() {
                    selectedImageFile = File(picked.path);
                  });
                }
              } catch (e) {
                debugPrint('Image pick error: $e');
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                top: 16,
                left: 20,
                right: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.edit_note_rounded, color: Color(0xFF047857), size: 24),
                            SizedBox(width: 8),
                            Text(
                              'কমিউনিটিতে নতুন পোস্ট লিখুন',
                              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Color(0xFF0F172A)),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 22, color: Color(0xFF64748B)),
                          onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    const Text('ক্যাটাগরি নির্বাচন করুন', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                    const SizedBox(height: 8),
                    Row(
                      children: ['টিপস', 'স্বাস্থ্য', 'প্রশ্ন', 'গল্প'].map((cat) {
                        final isSel = selectedCategory == cat;
                        return GestureDetector(
                          onTap: isSubmitting ? null : () => setModalState(() => selectedCategory = cat),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSel ? const Color(0xFF047857) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: isSel
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF047857).withValues(alpha: 0.25),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Text(
                              cat,
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isSel ? Colors.white : const Color(0xFF475569)),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),

                    _buildInputField('পোস্টের শিরোনাম', titleCtrl, 'যেমন: ছাগলের ভ্যাকসিন নিয়ে অভিজ্ঞতা', enabled: !isSubmitting),
                    const SizedBox(height: 12),
                    _buildInputField('বিস্তারিত বিবরণ', contentCtrl, 'আপনার অভিজ্ঞতা বা প্রশ্ন বিস্তারিত লিখুন...', maxLines: 4, enabled: !isSubmitting),
                    const SizedBox(height: 14),

                    const Text('ছবি যুক্ত করুন (S3 CDN Supported)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: isSubmitting ? null : () => pickImage(ImageSource.camera),
                            icon: const Icon(Icons.camera_alt_rounded, color: Color(0xFF047857), size: 20),
                            label: const Text('ক্যামেরা', style: TextStyle(color: Color(0xFF047857), fontWeight: FontWeight.bold, fontSize: 13)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: const BorderSide(color: Color(0xFF047857), width: 1.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: isSubmitting ? null : () => pickImage(ImageSource.gallery),
                            icon: const Icon(Icons.photo_library_rounded, color: Color(0xFF2563EB), size: 20),
                            label: const Text('গ্যালারি', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 13)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (selectedImageFile != null) ...[
                      const SizedBox(height: 12),
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.file(
                              selectedImageFile!,
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: isSubmitting ? null : () => setModalState(() => selectedImageFile = null),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, color: Colors.white, size: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 20),

                    // PUBLISH BUTTON WITH PROPER LOADING ANIMATION & DUPLICATE PREVENTION
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isSubmitting
                                ? [const Color(0xFF94A3B8), const Color(0xFF64748B)]
                                : [const Color(0xFF047857), const Color(0xFF065F46)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF047857).withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: isSubmitting
                              ? null
                              : () async {
                                  if (titleCtrl.text.trim().isEmpty || contentCtrl.text.trim().isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('শিরোনাম ও বিবরণ অবশ্যই পূরণ করুন'),
                                        backgroundColor: Color(0xFFDC2626),
                                      ),
                                    );
                                    return;
                                  }

                                  // 1. Prevent duplicate submission
                                  setModalState(() => isSubmitting = true);

                                  String? uploadedUrl;
                                  if (selectedImageFile != null) {
                                    try {
                                      uploadedUrl = await ApiClient.uploadImage(selectedImageFile!.path);
                                    } catch (_) {}
                                  }

                                  final postId = DateTime.now().millisecondsSinceEpoch.toString();

                                  final newPost = {
                                    'id': postId,
                                    'title': titleCtrl.text.trim(),
                                    'content': contentCtrl.text.trim(),
                                    'category': selectedCategory,
                                    'authorName': 'আমার খামার',
                                    'authorLocation': 'রেজিস্টার্ড ফারমার',
                                    'isVerified': true,
                                    'likes': 0,
                                    'isLiked': false,
                                    'comments': <Map<String, dynamic>>[],
                                    'imageFile': selectedImageFile,
                                    'imageUrl': uploadedUrl,
                                    'createdAt': 'মাত্র প্রকাশিত',
                                  };

                                  // Duplicate check before adding
                                  setState(() {
                                    if (!_posts.any((p) => p['id'] == postId)) {
                                      _posts.insert(0, newPost);
                                    }
                                  });

                                  try {
                                    await ApiClient.createCommunityPost(
                                      title: titleCtrl.text.trim(),
                                      content: contentCtrl.text.trim(),
                                      category: selectedCategory,
                                      imageUrl: uploadedUrl,
                                    );
                                  } catch (_) {}

                                  if (ctx.mounted) Navigator.pop(ctx);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('আপনার পোস্টটি সফলভাবে কমিউনিটিতে প্রকাশ করা হয়েছে'),
                                        backgroundColor: Color(0xFF047857),
                                      ),
                                    );
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: isSubmitting
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                    ),
                                    SizedBox(width: 12),
                                    Text('S3 CDN এ ছবি আপলোড ও পোস্ট হচ্ছে...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                  ],
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.send_rounded, color: Colors.white, size: 20),
                                    SizedBox(width: 8),
                                    Text('পোস্ট প্রকাশ করুন', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showImageLightbox(dynamic imageSource) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: imageSource is File
                    ? Image.file(imageSource, fit: BoxFit.contain)
                    : Image.network(imageSource as String, fit: BoxFit.contain),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showCommentsModal(Map<String, dynamic> post) {
    final commentCtrl = TextEditingController();
    final List<Map<String, dynamic>> comments = _parseCommentsList(post['comments']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                top: 16,
                left: 20,
                right: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.chat_bubble_outline_rounded, size: 20, color: Color(0xFF047857)),
                          const SizedBox(width: 8),
                          Text(
                            'মতামত ও মন্তব্য (${comments.length})',
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 22, color: Color(0xFF64748B)),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 12),

                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 280),
                    child: comments.isEmpty
                        ? const Center(
                            child: Text(
                              'এখনো কোনো মন্তব্য করা হয়নি। আপনার গুরুত্বপূর্ণ বক্তব্য শেয়ার করুন।',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            itemCount: comments.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final c = comments[index];
                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      c['authorName']?.toString() ?? 'খামারি সদস্য',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF047857)),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      c['content']?.toString() ?? '',
                                      style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B), height: 1.3),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),

                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: commentCtrl,
                          style: const TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'আপনার মন্তব্য লিখুন...',
                            hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                            filled: true,
                            fillColor: const Color(0xFFF1F5F9),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFF047857),
                          padding: const EdgeInsets.all(12),
                        ),
                        icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                        onPressed: () {
                          if (commentCtrl.text.isNotEmpty) {
                            final newComment = {
                              'id': DateTime.now().millisecondsSinceEpoch.toString(),
                              'authorName': 'আমার খামার',
                              'content': commentCtrl.text,
                            };
                            setModalState(() {
                              comments.add(newComment);
                            });
                            setState(() {
                              post['comments'] = comments;
                            });

                            try {
                              ApiClient.addPostComment(post['id'], commentCtrl.text);
                            } catch (_) {}

                            commentCtrl.clear();
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, String hint, {int maxLines = 1, bool enabled = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          enabled: enabled,
          style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF047857), width: 1.5)),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedCategoryFilter = ref.watch(communityCategoryFilterProvider);

    final filteredPosts = _posts.where((p) {
      if (selectedCategoryFilter == 'সবগুলো') return true;
      return p['category'] == selectedCategoryFilter;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF047857),
        elevation: 0,
        toolbarHeight: 68,
        automaticallyImplyLeading: false,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ফার্ম এআই খামারি কমিউনিটি',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Colors.white, letterSpacing: -0.3),
            ),
            SizedBox(height: 2),
            Text(
              'অভিজ্ঞতা, চিকিৎসা টিপস ও ছবি শেয়ারিং হাব',
              style: TextStyle(fontSize: 11, color: Color(0xFFA7F3D0), fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.add_photo_alternate_rounded, color: Colors.white, size: 22),
              onPressed: _showCreatePostModal,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. TOP CATEGORY FILTER BAR
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: ['সবগুলো', 'টিপস', 'স্বাস্থ্য', 'প্রশ্ন', 'গল্প'].map((cat) {
                  final isSel = selectedCategoryFilter == cat;
                  return GestureDetector(
                    onTap: () => ref.read(communityCategoryFilterProvider.notifier).state = cat,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSel ? const Color(0xFF047857) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: isSel ? const Color(0xFF047857) : const Color(0xFFE2E8F0)),
                        boxShadow: isSel
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF047857).withValues(alpha: 0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSel ? Colors.white : const Color(0xFF475569),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // 2. COMMUNITY POSTS FEED
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF047857)))
                : filteredPosts.isEmpty
                    ? const Center(
                        child: Text(
                          'এই ক্যাটাগরিতে কোনো পোস্ট নেই',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadApiPosts,
                        color: const Color(0xFF047857),
                        child: ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredPosts.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            final post = filteredPosts[index];
                            final isLiked = post['isLiked'] == true;
                            final likesCount = _parseLikesCount(post['likes']);
                            final commentsList = _parseCommentsList(post['comments']);
                            final isVerified = post['isVerified'] == true;

                            final authorName = (post['authorName'] as String).isNotEmpty ? post['authorName'] as String : 'ফার্ম সদস্য';
                            final firstInitial = authorName.substring(0, 1);

                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0x0A0F172A),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Post Header
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 42,
                                          height: 42,
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [Color(0xFF10B981), Color(0xFF047857)],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFF047857).withValues(alpha: 0.2),
                                                blurRadius: 6,
                                              ),
                                            ],
                                          ),
                                          child: Center(
                                            child: Text(
                                              firstInitial,
                                              style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 16),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Flexible(
                                                    child: Text(
                                                      authorName,
                                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  if (isVerified) ...[
                                                    const SizedBox(width: 4),
                                                    const Icon(Icons.verified_rounded, color: Color(0xFF2563EB), size: 16),
                                                  ],
                                                ],
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                '${post['authorLocation']} • ${post['createdAt']}',
                                                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFECFDF5),
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: const Color(0xFFA7F3D0)),
                                          ),
                                          child: Text(
                                            post['category'] as String,
                                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF047857)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Post Title & Content
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          post['title'] as String,
                                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.2),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          post['content'] as String,
                                          style: const TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.45),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // Post Image Attachment (Lightbox Enabled)
                                  if (post['imageFile'] != null)
                                    GestureDetector(
                                      onTap: () => _showImageLightbox(post['imageFile']),
                                      child: ClipRRect(
                                        child: Image.file(
                                          post['imageFile'] as File,
                                          width: double.infinity,
                                          height: 210,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    )
                                  else if (post['imageUrl'] != null)
                                    GestureDetector(
                                      onTap: () => _showImageLightbox(post['imageUrl']),
                                      child: ClipRRect(
                                        child: Image.network(
                                          post['imageUrl'] as String,
                                          width: double.infinity,
                                          height: 210,
                                          fit: BoxFit.cover,
                                          errorBuilder: (ctx, err, stack) => const SizedBox(),
                                        ),
                                      ),
                                    ),

                                  const Divider(height: 1, color: Color(0xFFF1F5F9)),

                                  // Post Actions Bar (Likes, Comments, Share)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        InkWell(
                                          borderRadius: BorderRadius.circular(20),
                                          onTap: () {
                                            setState(() {
                                              post['isLiked'] = !isLiked;
                                              post['likes'] = isLiked ? (likesCount > 0 ? likesCount - 1 : 0) : likesCount + 1;
                                            });
                                            try {
                                              ApiClient.togglePostLike(post['id']);
                                            } catch (_) {}
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                                  color: isLiked ? const Color(0xFFEF4444) : const Color(0xFF64748B),
                                                  size: 22,
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  '$likesCount লাইক',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: isLiked ? const Color(0xFFEF4444) : const Color(0xFF64748B),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),

                                        InkWell(
                                          borderRadius: BorderRadius.circular(20),
                                          onTap: () => _showCommentsModal(post),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            child: Row(
                                              children: [
                                                const Icon(Icons.mode_comment_outlined, color: Color(0xFF2563EB), size: 20),
                                                const SizedBox(width: 6),
                                                Text(
                                                  '${commentsList.length} মন্তব্য',
                                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),

                                        InkWell(
                                          borderRadius: BorderRadius.circular(20),
                                          onTap: () {
                                            Clipboard.setData(ClipboardData(text: '${post['title']}\n${post['content']}'));
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('পোস্টের লেখাটি কপি করা হয়েছে'),
                                                backgroundColor: Color(0xFF047857),
                                              ),
                                            );
                                          },
                                          child: const Padding(
                                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            child: Row(
                                              children: [
                                                Icon(Icons.share_rounded, color: Color(0xFF64748B), size: 18),
                                                SizedBox(width: 4),
                                                Text(
                                                  'শেয়ার',
                                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                                                ),
                                              ],
                                            ),
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
                      ),
          ),
        ],
      ),
    );
  }
}
