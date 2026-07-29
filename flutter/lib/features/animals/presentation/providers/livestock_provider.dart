import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class LivestockNotifier extends AsyncNotifier<List<dynamic>> {
  static const String _storageKey = 'farm_ai_persisted_livestock_v2';

  @override
  Future<List<dynamic>> build() async {
    final List<dynamic> localSavedList = await _loadLocalLivestock();

    final user = ref.watch(authProvider).user;
    final farmerId = user?['id'];

    if (farmerId == null) {
      return localSavedList;
    }

    try {
      final remoteData = await ApiClient.getLivestock(farmerId);
      final mergedMap = <String, dynamic>{};

      // Put local saved list first
      for (var item in localSavedList) {
        final key = (item['id'] ?? item['name']).toString();
        mergedMap[key] = item;
      }

      // Merge remote data
      for (var item in remoteData) {
        final key = (item['id'] ?? item['name']).toString();
        mergedMap[key] = item;
      }

      final mergedList = mergedMap.values.toList();
      await _saveLocalLivestock(mergedList);
      return mergedList;
    } catch (e) {
      debugPrint('Remote livestock fetch error: $e. Returning persisted local list.');
      return localSavedList;
    }
  }

  Future<List<dynamic>> _loadLocalLivestock() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(jsonString);
        return decoded;
      }
    } catch (e) {
      debugPrint('Error loading local livestock: $e');
    }
    return [];
  }

  Future<void> _saveLocalLivestock(List<dynamic> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(list));
    } catch (e) {
      debugPrint('Error saving local livestock: $e');
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => build());
  }

  Future<void> addLivestock(Map<String, dynamic> newAnimalData) async {
    final user = ref.read(authProvider).user;
    final farmerId = user?['id'] ?? 'farmer-local-1';

    final newItem = {
      'id': 'cattle-${DateTime.now().millisecondsSinceEpoch}',
      ...newAnimalData,
      'farmerId': farmerId,
      'createdAt': DateTime.now().toIso8601String(),
    };

    final currentList = state.value ?? [];
    final updatedList = [newItem, ...currentList];

    // Optimistically update memory and disk immediately!
    state = AsyncValue.data(updatedList);
    await _saveLocalLivestock(updatedList);

    try {
      await ApiClient.createLivestock(newItem);
    } catch (e) {
      debugPrint('Backend sync error for cattle creation: $e. Kept safely in local database.');
    }
  }

  Future<void> toggleCollarBind(String id, bool currentlyBound) async {
    final currentList = List<Map<String, dynamic>>.from(state.value ?? []);
    final newCollarId = currentlyBound ? null : '#${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}-BD';

    for (var item in currentList) {
      if (item['id'].toString() == id) {
        item['isBound'] = !currentlyBound;
        item['collarId'] = newCollarId;
        break;
      }
    }

    state = AsyncValue.data(currentList);
    await _saveLocalLivestock(currentList);

    try {
      await ApiClient.updateLivestock(id, {
        'isBound': !currentlyBound,
        'collarId': newCollarId,
      });
    } catch (e) {
      debugPrint('Backend collar bind error: $e');
    }
  }

  Future<void> deleteLivestock(String id) async {
    final currentList = List<Map<String, dynamic>>.from(state.value ?? []);
    currentList.removeWhere((item) => item['id'].toString() == id);

    state = AsyncValue.data(currentList);
    await _saveLocalLivestock(currentList);

    try {
      await ApiClient.deleteLivestock(id);
    } catch (e) {
      debugPrint('Backend delete error: $e');
    }
  }
}

final livestockProvider = AsyncNotifierProvider<LivestockNotifier, List<dynamic>>(() {
  return LivestockNotifier();
});

final livestockFilterProvider = StateProvider<String>((ref) => 'সকল');
final livestockSearchProvider = StateProvider<String>((ref) => '');

final filteredLivestockProvider = Provider<AsyncValue<List<dynamic>>>((ref) {
  final asyncLivestock = ref.watch(livestockProvider);
  final filter = ref.watch(livestockFilterProvider);
  final search = ref.watch(livestockSearchProvider).toLowerCase();

  return asyncLivestock.whenData((list) {
    return list.where((cow) {
      final name = (cow['name'] ?? '').toString().toLowerCase();
      final breed = (cow['breed'] ?? '').toString().toLowerCase();
      final type = (cow['type'] ?? cow['species'] ?? '').toString().toLowerCase();
      final health = (cow['health'] ?? cow['status'] ?? 'সুস্থ').toString().toLowerCase();
      final isBound = cow['isBound'] == true;

      final matchesSearch = name.contains(search) || breed.contains(search) || type.contains(search);

      if (filter == 'গাভী') return matchesSearch && (type.contains('গাভী') || type.contains('cattle') || type.contains('cow'));
      if (filter == 'Beef') return matchesSearch && (type.contains('beef') || type.contains('মাংস'));
      if (filter == 'ছাগল/ভেড়া') return matchesSearch && (type.contains('ছাগল') || type.contains('goat') || type.contains('sheep') || type.contains('ভেড়া'));
      if (filter == 'সুস্থ') return matchesSearch && (health.contains('সুস্থ') || health.contains('healthy'));
      if (filter == 'পর্যবেক্ষণে') return matchesSearch && health.contains('পর্যবেক্ষণে');
      if (filter == 'কলার সংযুক্ত') return matchesSearch && isBound;

      return matchesSearch;
    }).toList();
  });
});
