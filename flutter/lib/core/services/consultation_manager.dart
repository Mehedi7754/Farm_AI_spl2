import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../network/api_client.dart';

class ConsultationManager {
  static const String _prefKey = 'farm_deleted_consultation_ids';
  static Set<String> _cachedDeletedIds = {};
  static bool _isLoaded = false;

  /// Ensure deleted IDs are loaded into memory from SharedPreferences
  static Future<void> _ensureLoaded() async {
    if (!_isLoaded) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final list = prefs.getStringList(_prefKey) ?? [];
        _cachedDeletedIds = list.toSet();
      } catch (_) {}
      _isLoaded = true;
    }
  }

  /// Filter out locally deleted consultations
  static Future<List<Map<String, dynamic>>> filterConsultations(List<dynamic> raw) async {
    await _ensureLoaded();
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .where((c) => !_cachedDeletedIds.contains(c['id']?.toString()))
        .toList();
  }

  /// Check if a specific ID is deleted
  static bool isDeleted(String id) => _cachedDeletedIds.contains(id);

  /// Perform instant local & remote deletion
  static Future<bool> deleteConsultation({
    required BuildContext context,
    required String consultationId,
    required VoidCallback onOptimisticUpdate,
  }) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: Color(0xFFDC2626), size: 24),
            SizedBox(width: 8),
            Text('রেকর্ড মুছে ফেলবেন?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'আপনি কি নিশ্চিত যে এই অ্যাপয়েন্টমেন্ট রেকর্ডটি আপনার তালিকা থেকে স্থায়ীভাবে মুছে ফেলতে চান?',
          style: TextStyle(fontSize: 13, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('না, রাখুন', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('হ্যাঁ, মুছে ফেলুন'),
          ),
        ],
      ),
    );

    if (confirm != true) return false;

    // 1. Optimistic removal & persist
    _cachedDeletedIds.add(consultationId);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefKey, _cachedDeletedIds.toList());
    } catch (_) {}

    onOptimisticUpdate();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('অ্যাপয়েন্টমেন্ট রেকর্ডটি মুছে ফেলা হয়েছে'),
          backgroundColor: Color(0xFF0F172A),
          duration: Duration(seconds: 2),
        ),
      );
    }

    // 2. Background API call
    try {
      await ApiClient.deleteConsultation(consultationId);
    } catch (_) {}

    return true;
  }

  /// Perform cancel booking
  static Future<bool> cancelConsultation({
    required BuildContext context,
    required String consultationId,
    required VoidCallback onOptimisticUpdate,
  }) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.cancel_outlined, color: Color(0xFFDC2626), size: 24),
            SizedBox(width: 8),
            Text('অ্যাপয়েন্টমেন্ট বাতিল করবেন?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'আপনি কি নিশ্চিত যে এই অ্যাপয়েন্টমেন্টটি বাতিল করতে চান? বুকিং স্লটটি উন্মুক্ত হয়ে যাবে।',
          style: TextStyle(fontSize: 13, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('না, ফিরে যান', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('হ্যাঁ, বাতিল করুন'),
          ),
        ],
      ),
    );

    if (confirm != true) return false;

    onOptimisticUpdate();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('অ্যাপয়েন্টমেন্ট সফলভাবে বাতিল করা হয়েছে'),
          backgroundColor: Color(0xFFDC2626),
          duration: Duration(seconds: 2),
        ),
      );
    }

    try {
      final currentUserId = ApiClient.currentUser?['id'];
      await ApiClient.cancelConsultation(consultationId, cancelledBy: currentUserId);
    } catch (_) {}

    return true;
  }
}
