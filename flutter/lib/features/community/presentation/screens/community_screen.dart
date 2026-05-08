import 'package:flutter/material.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FBF9),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1B5E20),
          elevation: 0,
          title: const Text(
            'কমিউনিটি ফোরাম',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(icon: const Icon(Icons.search_rounded), onPressed: () {}),
            IconButton(icon: const Icon(Icons.notifications_none_rounded), onPressed: () {}),
            const SizedBox(width: 8),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: TabBar(
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: const Color(0xFF1B5E20),
                unselectedLabelColor: Colors.white70,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'সব পোস্ট'),
                  Tab(text: 'আমার পোস্ট'),
                ],
              ),
            ),
          ),
        ),
        body: Column(
          children: [
            _buildCategoryFilter(),
            Expanded(
              child: TabBarView(
                children: [
                  _buildPostList(),
                  _buildMyPosts(),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {},
          backgroundColor: const Color(0xFF2E7D32),
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: const Text('নতুন পোস্ট', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          elevation: 4,
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    final categories = ['সবগুলো', 'রোগ-বালাই', 'গবাদি পশু', 'ক্রয়-বিক্রয়', 'টিপস'];
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final isSelected = index == 0;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF2E7D32) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? const Color(0xFF2E7D32) : const Color(0xFFE0E6ED),
                width: 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFF2E7D32).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : null,
            ),
            child: Text(
              categories[index],
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF7F8C8D),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                fontSize: 13,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPostList() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      children: [
        _buildPostCard(
          author: 'করিম শেখ',
          time: '১০ মিনিট আগে',
          title: 'গরুর খুরা রোগের প্রাথমিক চিকিৎসা কি?',
          content: 'আমার ৩টি গরুর খুরা রোগ দেখা দিয়েছে। গ্রাম্য ডাক্তার দেখানো হয়েছে কিন্তু তেমন উন্নতি হচ্ছে না। কেউ কি ভালো কোনো টিপস দিতে পারেন?',
          tag: 'রোগ-বালাই',
          likes: 24,
          comments: 8,
          authorAvatar: 'KS',
        ),
        const SizedBox(height: 16),
        _buildPostCard(
          author: 'আরিফ আহমেদ',
          time: '২ ঘণ্টা আগে',
          title: 'উন্নত জাতের পালং শাকের বীজ বিক্রয় হবে',
          content: 'খুবই উন্নত মানের শীতকালীন পালং শাকের বীজ আছে। যারা পাইকারি নিতে চান সরাসরি যোগাযোগ করুন। ফলন খুব ভালো হবে।',
          tag: 'ক্রয়-বিক্রয়',
          likes: 15,
          comments: 3,
          authorAvatar: 'AA',
        ),
        const SizedBox(height: 16),
        _buildPostCard(
          author: 'মেহেদী হাসান',
          time: '৫ ঘণ্টা আগে',
          title: 'দুধের উৎপাদন বৃদ্ধির সহজ উপায়',
          content: 'সুষম খাবার এবং সঠিক যত্নের মাধ্যমে গরুর দুধের উৎপাদন ১৫-২০% বৃদ্ধি করা সম্ভব। আমি নিজে এই পদ্ধতি ব্যবহার করে উপকৃত হয়েছি।',
          tag: 'টিপস',
          likes: 42,
          comments: 12,
          authorAvatar: 'MH',
        ),
      ],
    );
  }

  Widget _buildMyPosts() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.post_add_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'আপনার কোনো পোস্ট নেই',
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'নতুন কিছু শেয়ার করতে বা প্রশ্ন করতে\nপোস্ট তৈরি করুন',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard({
    required String author,
    required String time,
    required String title,
    required String content,
    required String tag,
    required int likes,
    required int comments,
    required String authorAvatar,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: const Color(0xFFF0F4F7), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFFE8F5E9),
                      child: Text(
                        authorAvatar,
                        style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(author, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF2C3E50))),
                        Text(time, style: const TextStyle(fontSize: 11, color: Color(0xFF95A5A6))),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2F1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(fontSize: 10, color: Color(0xFF2E7D32), fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  content,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF7F8C8D), fontSize: 14, height: 1.5),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF0F4F7)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _buildPostAction(Icons.thumb_up_alt_outlined, likes.toString()),
                    const SizedBox(width: 8),
                    _buildPostAction(Icons.chat_bubble_outline_rounded, comments.toString()),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.share_outlined, size: 20, color: Color(0xFF95A5A6)),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostAction(IconData icon, String count) {
    return TextButton.icon(
      onPressed: () {},
      icon: Icon(icon, size: 18, color: const Color(0xFF7F8C8D)),
      label: Text(
        count,
        style: const TextStyle(color: Color(0xFF7F8C8D), fontWeight: FontWeight.bold, fontSize: 13),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
