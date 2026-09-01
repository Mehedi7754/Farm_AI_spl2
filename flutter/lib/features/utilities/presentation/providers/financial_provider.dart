import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/network/api_client.dart';

class FinancialNotifier extends AsyncNotifier<List<Map<String, dynamic>>> {
  static const String _storageKey = 'farm_ai_persisted_financial_records_v2';

  @override
  Future<List<Map<String, dynamic>>> build() async {
    final localSaved = await _loadLocalTransactions();

    try {
      final records = await ApiClient.getFinancialRecords();
      if (records.isNotEmpty) {
        final parsedRemote = records.map((r) {
          final raw = r as Map<String, dynamic>;
          final titleVal = raw['description'] ?? raw['title'] ?? 'হিসাব বিবরণ';
          final typeVal = raw['type'] ?? (raw['isIncome'] == true ? 'INCOME' : 'EXPENSE');
          final isInc = typeVal == 'INCOME' || raw['isIncome'] == true;
          final dtStr = raw['date'] ?? raw['createdAt'];
          final dt = dtStr != null ? DateTime.tryParse(dtStr.toString()) ?? DateTime.now() : DateTime.now();

          return {
            'id': raw['id']?.toString() ?? 'tx-${DateTime.now().millisecondsSinceEpoch}',
            'title': titleVal.toString(),
            'category': raw['category']?.toString() ?? (isInc ? 'দুধ বিক্রি' : 'খাদ্য ক্রয়'),
            'amount': (raw['amount'] as num?)?.toInt() ?? 0,
            'isIncome': isInc,
            'date': '${dt.day}/${dt.month}/${dt.year}',
            'cattle': raw['category']?.toString() ?? '',
            'timestamp': dt.toIso8601String(),
          };
        }).toList();

        // Merge remote records with local
        final Map<String, Map<String, dynamic>> mergedMap = {};
        for (var item in localSaved) {
          mergedMap[item['id'].toString()] = item;
        }
        for (var item in parsedRemote) {
          mergedMap[item['id'].toString()] = item;
        }

        final mergedList = mergedMap.values.toList();
        mergedList.sort((a, b) {
          final dtA = DateTime.tryParse(a['timestamp'].toString()) ?? DateTime.now();
          final dtB = DateTime.tryParse(b['timestamp'].toString()) ?? DateTime.now();
          return dtB.compareTo(dtA);
        });

        await _saveLocalTransactions(mergedList);
        return mergedList;
      }
    } catch (e) {
      debugPrint('Error fetching financial records: $e');
    }

    return localSaved;
  }

  Future<List<Map<String, dynamic>>> _loadLocalTransactions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedStr = prefs.getString(_storageKey);
      if (savedStr != null && savedStr.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(savedStr);
        return decoded.map((r) => Map<String, dynamic>.from(r as Map)).toList();
      }
    } catch (e) {
      debugPrint('Error loading local financial records: $e');
    }
    return [];
  }

  Future<void> _saveLocalTransactions(List<Map<String, dynamic>> records) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(records));
    } catch (e) {
      debugPrint('Error saving local financial records: $e');
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => build());
  }

  Future<void> addOrUpdateTransaction(Map<String, dynamic> record) async {
    final currentList = List<Map<String, dynamic>>.from(state.value ?? []);
    final idx = currentList.indexWhere((t) => t['id'] == record['id']);

    if (idx != -1) {
      currentList[idx] = record;
    } else {
      currentList.insert(0, record);
    }

    state = AsyncValue.data(currentList);
    await _saveLocalTransactions(currentList);

    // Sync with backend API in background
    try {
      final result = await ApiClient.createFinancialRecord(
        title: record['title'].toString(),
        amount: record['amount'] as int,
        isIncome: record['isIncome'] as bool,
        category: record['category'].toString(),
      );
      if (result != null && result['id'] != null) {
        // Update the temporary ID with real backend ID
        final updatedList = List<Map<String, dynamic>>.from(state.value ?? []);
        final tempIdx = updatedList.indexWhere((t) => t['id'] == record['id']);
        if (tempIdx != -1) {
          updatedList[tempIdx]['id'] = result['id'].toString();
          state = AsyncValue.data(updatedList);
          await _saveLocalTransactions(updatedList);
        }
      }
    } catch (e) {
      debugPrint('Backend sync error for financial record: $e');
    }
  }

  Future<void> deleteTransaction(String id) async {
    final currentList = List<Map<String, dynamic>>.from(state.value ?? []);
    currentList.removeWhere((t) => t['id'].toString() == id.toString());

    state = AsyncValue.data(currentList);
    await _saveLocalTransactions(currentList);

    // Sync deletion with backend in background
    try {
      await ApiClient.deleteFinancialRecord(id);
    } catch (e) {
      debugPrint('Backend delete error for financial record $id: $e');
    }
  }
}

final financialProvider = AsyncNotifierProvider<FinancialNotifier, List<Map<String, dynamic>>>(() {
  return FinancialNotifier();
});
