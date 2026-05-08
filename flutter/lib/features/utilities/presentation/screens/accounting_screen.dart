import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AccountingScreen extends StatelessWidget {
  const AccountingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBF9),
      appBar: AppBar(
        title: const Text(
          'হিসাব-নিকাশ',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1A1A1A)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFD32F2F)),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('পিডিএফ রিপোর্ট তৈরি হচ্ছে...')),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBalanceSummaryCard(),
            const SizedBox(height: 32),
            _buildSectionTitle('ব্যয়ের বিশ্লেষণ'),
            const SizedBox(height: 16),
            _buildFinancialChart(),
            const SizedBox(height: 32),
            _buildSectionTitle('সাম্প্রতিক লেনদেন'),
            const SizedBox(height: 16),
            _buildTransactionList(),
            const SizedBox(height: 40),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: const Color(0xFF004D40),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('নতুন এন্ট্রি', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ).animate().scale(delay: 400.ms, duration: 400.ms),
    );
  }

  Widget _buildBalanceSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          colors: [Color(0xFF004D40), Color(0xFF00796B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF004D40).withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'মোট ব্যালেন্স',
            style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          const Text(
            '৳ ৪২,৫০০',
            style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold, letterSpacing: -1),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              _buildSummaryItem('আয়', '৳ ৬০,০০০', Icons.arrow_upward_rounded, const Color(0xFF81C784)),
              const SizedBox(width: 32),
              _buildSummaryItem('ব্যয়', '৳ ১৭,৫০০', Icons.arrow_downward_rounded, const Color(0xFFFF8A80)),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildSummaryItem(String label, String amount, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 4),
        Text(amount, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A), letterSpacing: -0.5),
    );
  }

  Widget _buildFinancialChart() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFF0F4F7)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildChartBar('খাদ্য', 0.8, const Color(0xFF004D40)),
              _buildChartBar('ওষুধ', 0.4, const Color(0xFF2E7D32)),
              _buildChartBar('শ্রম', 0.6, const Color(0xFF00796B)),
              _buildChartBar('অন্যান্য', 0.2, const Color(0xFF81C784)),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.trending_up_rounded, color: Color(0xFF2E7D32), size: 16),
              const SizedBox(width: 8),
              Text(
                'গত মাসের তুলনায় ১২% ব্যয় কমেছে',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartBar(String label, double heightFactor, Color color) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 120 * heightFactor,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              colors: [color, color.withValues(alpha: 0.7)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ).animate().scaleY(begin: 0, end: 1, duration: 800.ms, curve: Curves.easeOutBack),
        const SizedBox(height: 12),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF7F8C8D))),
      ],
    );
  }

  Widget _buildTransactionList() {
    return Column(
      children: [
        _buildTransactionItem('গরুর খাদ্য ক্রয়', 'ওপেন ফিড লিমিটেড', '৳ ৮,০০০', 'ব্যয়', true),
        _buildTransactionItem('দুধ বিক্রয়', 'লোকাল মার্কেট', '৳ ১২,৫০০', 'আয়', false),
        _buildTransactionItem('ভ্যাকসিন খরচ', 'পশু সম্পদ হাসপাতাল', '৳ ২,২০০', 'ব্যয়', true),
      ],
    );
  }

  Widget _buildTransactionItem(String title, String subtitle, String amount, String type, bool isExpense) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF0F4F7)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isExpense ? const Color(0xFFFFEBEE) : const Color(0xFFE8F5E9),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isExpense ? Icons.remove_rounded : Icons.add_rounded,
              color: isExpense ? const Color(0xFFD32F2F) : const Color(0xFF2E7D32),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1A1A1A))),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: isExpense ? const Color(0xFFD32F2F) : const Color(0xFF2E7D32),
            ),
          ),
        ],
      ),
    );
  }
}
