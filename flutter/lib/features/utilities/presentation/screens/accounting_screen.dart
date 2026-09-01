import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/network/api_client.dart';
import '../providers/financial_provider.dart';

class AccountingScreen extends ConsumerStatefulWidget {
  const AccountingScreen({super.key});

  @override
  ConsumerState<AccountingScreen> createState() => _AccountingScreenState();
}

class _AccountingScreenState extends ConsumerState<AccountingScreen> {
  String _selectedCategory = 'সকল';
  String _selectedDateRange = 'সকল';

  @override
  void initState() {
    super.initState();
    // Fetch latest in background if needed
    Future.microtask(() => ref.read(financialProvider.notifier).refresh());
  }

  void _showAddOrEditTransactionModal({Map<String, dynamic>? existingTx}) {
    final titleCtrl = TextEditingController(text: existingTx?['title'] ?? '');
    final amountCtrl = TextEditingController(text: existingTx != null ? existingTx['amount'].toString() : '');
    bool isIncome = existingTx?['isIncome'] ?? true;
    String category = existingTx?['category'] ?? (isIncome ? 'দুধ বিক্রি' : 'খাদ্য ক্রয়');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                top: 20,
                left: 18,
                right: 18,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        existingTx != null ? 'হিসেব পরিবর্তন করুন (Alter)' : 'নতুন হিসেব যুক্ত করুন',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          selected: isIncome,
                          label: const Text('আয় (দুধ বিক্রি)', style: TextStyle(fontWeight: FontWeight.bold)),
                          selectedColor: const Color(0xFF059669),
                          labelStyle: TextStyle(color: isIncome ? Colors.white : const Color(0xFF0F172A)),
                          onSelected: (val) => setModalState(() {
                            isIncome = true;
                            category = 'দুধ বিক্রি';
                          }),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          selected: !isIncome,
                          label: const Text('ব্যয় (খাদ্য/চিকিৎসা)', style: TextStyle(fontWeight: FontWeight.bold)),
                          selectedColor: const Color(0xFFDC2626),
                          labelStyle: TextStyle(color: !isIncome ? Colors.white : const Color(0xFF0F172A)),
                          onSelected: (val) => setModalState(() {
                            isIncome = false;
                            category = 'খাদ্য ক্রয়';
                          }),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  _buildInputField('বিবরণ', titleCtrl, 'যেমন: ২০ লিটার দুধ বিক্রি'),
                  const SizedBox(height: 10),
                  _buildInputField('টাকার পরিমাণ (৳)', amountCtrl, 'যেমন: ১৪০০', isNumber: true),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        if (titleCtrl.text.trim().isNotEmpty && amountCtrl.text.trim().isNotEmpty) {
                          final parsedAmount = int.tryParse(amountCtrl.text.replaceAll(',', '')) ?? 0;
                          final now = DateTime.now();
                          
                          final newRecord = {
                            'id': existingTx?['id'] ?? 'tx-${now.millisecondsSinceEpoch}',
                            'title': titleCtrl.text.trim(),
                            'amount': parsedAmount,
                            'isIncome': isIncome,
                            'category': category,
                            'date': '${now.day}/${now.month}/${now.year}',
                            'cattle': category,
                            'timestamp': now.toIso8601String(),
                          };

                          Navigator.pop(ctx);

                          await ref.read(financialProvider.notifier).addOrUpdateTransaction(newRecord);

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('নতুন হিসাব সফলভাবে সংরক্ষণ হয়েছে 📝'),
                                backgroundColor: Color(0xFF059669),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                      label: Text(existingTx != null ? 'পরিবর্তন হালনাগাদ করুন' : 'সংরক্ষণ করুন', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _deleteTransaction(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('হিসেব মুছে ফেলা', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        content: const Text('আপনি কি নিশ্চিতভাবে এই লেনদেনের হিসেবটি মুছে ফেলতে চান?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('বাতিল', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              
              await ref.read(financialProvider.notifier).deleteTransaction(id);
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('হিসেবটি সফলভাবে মুছে ফেলা হয়েছে 🗑️'),
                    backgroundColor: Color(0xFF059669),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            child: const Text('মুছে ফেলুন', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, String hint, {bool isNumber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final financialState = ref.watch(financialProvider);
    final _transactions = financialState.value ?? [];

    if (financialState.isLoading && _transactions.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: const Color(0xFF059669),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          title: const Text('খামারের হিসাব খাতা', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        body: const Center(child: CircularProgressIndicator(color: Color(0xFF059669))),
      );
    }

    final now = DateTime.now();

    final filteredByDate = _transactions.where((t) {
      final tsRaw = t['timestamp'];
      final ts = tsRaw is DateTime ? tsRaw : (tsRaw != null ? DateTime.tryParse(tsRaw.toString()) : null);
      if (ts == null) return true;

      if (_selectedDateRange == 'আজ') {
        return ts.year == now.year && ts.month == now.month && ts.day == now.day;
      } else if (_selectedDateRange == 'এই সপ্তাহ') {
        final weekAgo = now.subtract(const Duration(days: 7));
        return ts.isAfter(weekAgo);
      } else if (_selectedDateRange == 'এই মাস') {
        return ts.year == now.year && ts.month == now.month;
      }
      return true;
    }).toList();

    final filtered = filteredByDate.where((t) {
      if (_selectedCategory == 'দুধ বিক্রি') return t['isIncome'] == true;
      if (_selectedCategory == 'খরচ') return t['isIncome'] == false;
      return true;
    }).toList();

    int totalIncome = 0;
    int totalExpense = 0;

    for (var t in filtered) {
      final amount = (t['amount'] as num).toInt();
      if (t['isIncome'] == true) {
        totalIncome += amount;
      } else {
        totalExpense += amount;
      }
    }

    final netProfit = totalIncome - totalExpense;
    final totalFlow = totalIncome + totalExpense;
    final incomeRatio = totalFlow == 0 ? 0.0 : totalIncome / totalFlow;

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
              'খামারের হিসাব খাতা',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white),
            ),
            Text(
              'তারিখ, সপ্তাহ ও মাস অনুযায়ী ফিল্টার ও এডিট',
              style: TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_rounded, color: Colors.white, size: 24),
            onPressed: () => _showAddOrEditTransactionModal(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. DATE RANGE FILTER CHIPS (আজ, এই সপ্তাহ, এই মাস, সকল)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.calendar_month_rounded, size: 16, color: Color(0xFF059669)),
                      SizedBox(width: 6),
                      Text('সময়সীমা নির্বাচন করুন (Date Filter):', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: ['আজ', 'এই সপ্তাহ', 'এই মাস', 'সকল'].map((range) {
                      final isSel = _selectedDateRange == range;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedDateRange = range),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            padding: const EdgeInsets.symmetric(vertical: 7),
                            decoration: BoxDecoration(
                              color: isSel ? const Color(0xFF059669) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              range,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isSel ? Colors.white : const Color(0xFF475569),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // 2. MAIN HERO KPI NET PROFIT CARD
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [Color(0xFF059669), Color(0xFF047857)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF059669).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('নিট লাভ (Net Profit KPI - $_selectedDateRange)', style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(
                    '৳${netProfit > 0 ? '+' : ''}$netProfit',
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSummaryPill('মোট আয় (দুধ বিক্রি)', '৳$totalIncome', Icons.trending_up_rounded, Colors.white),
                      Container(width: 1, height: 26, color: Colors.white24),
                      _buildSummaryPill('মোট খরচ (খাদ্য/ওষুধ)', '৳$totalExpense', Icons.trending_down_rounded, const Color(0xFFFDE047)),
                    ],
                  ),
                  const SizedBox(height: 14),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('আয়ের অনুপাত: ${(incomeRatio * 100).toStringAsFixed(0)}%', style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                          Text('ব্যয়ের অনুপাত: ${((1 - incomeRatio) * 100).toStringAsFixed(0)}%', style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: incomeRatio,
                          minHeight: 6,
                          backgroundColor: const Color(0xFFDC2626),
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // 3. CATEGORY FILTERS ROW
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: ['সকল', 'দুধ বিক্রি', 'খরচ'].map((cat) {
                    final isSel = _selectedCategory == cat;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedCategory = cat),
                      child: Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSel ? const Color(0xFF059669) : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: isSel ? const Color(0xFF059669) : const Color(0xFFCBD5E1)),
                        ),
                        child: Text(
                          cat,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isSel ? Colors.white : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                Text('${filtered.length}টি লেনদেন', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
              ],
            ),

            const SizedBox(height: 10),

            // 4. TRANSACTIONS LIST WITH EDIT (ALTER) AND DELETE OPTIONS
            filtered.isEmpty
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.receipt_long_rounded, size: 40, color: Color(0xFFCBD5E1)),
                        SizedBox(height: 10),
                        Text(
                          'নির্বাচিত সময়ে কোনো হিসাব পাওয়া যায়নি',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final t = filtered[index];
                      final isInc = t['isIncome'] as bool;
                      final amount = t['amount'];

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isInc ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isInc ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                                color: isInc ? const Color(0xFF059669) : const Color(0xFFDC2626),
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    t['title'] as String,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${t['cattle']} • ${t['date']}',
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${isInc ? '+' : '-'}৳$amount',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: isInc ? const Color(0xFF059669) : const Color(0xFFDC2626),
                              ),
                            ),
                            const SizedBox(width: 4),

                            // Edit Action Button (Alter)
                            IconButton(
                              icon: const Icon(Icons.edit_note_rounded, color: Color(0xFF2563EB), size: 20),
                              onPressed: () => _showAddOrEditTransactionModal(existingTx: t),
                            ),

                            // Delete Action Button
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 18),
                              onPressed: () => _deleteTransaction(t['id'] as String),
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

  Widget _buildSummaryPill(String label, String val, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
            Text(val, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }
}
