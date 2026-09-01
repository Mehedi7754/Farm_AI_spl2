import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class LivestockNotifier extends AsyncNotifier<List<dynamic>> {
  static const String _storageKey = 'farm_ai_persisted_livestock_v3';

  @override
  Future<List<dynamic>> build() async {
    final List<dynamic> localSavedList = await _loadLocalLivestock();

    final user = ref.watch(authProvider).user;
    final farmerId = user?['id'];

    if (farmerId == null) {
      return localSavedList;
    }

    // Auto-sync local offline-created cows to backend
    final List<dynamic> syncedLocalList = List.from(localSavedList);
    bool needSave = false;

    for (int i = 0; i < syncedLocalList.length; i++) {
      try {
        final item = Map<String, dynamic>.from(syncedLocalList[i]);
        final id = item['id'].toString();
        if (id.startsWith('cattle-')) {
          final collarDeviceCode = item['collarId'] ?? item['smartCollar']?['deviceCode'];
          final Map<String, dynamic> postData = Map.from(item)
            ..remove('id')
            ..remove('collarId')
            ..remove('smartCollar')
            ..remove('isBound');

          final created = await ApiClient.createLivestock({
            ...postData,
            'farmerId': farmerId,
          });

          if (created['id'] != null) {
            item['id'] = created['id'];
            needSave = true;

            if (collarDeviceCode != null) {
              final collarInfo = await ApiClient.getDeviceLocation(collarDeviceCode);
              if (collarInfo != null && collarInfo['id'] != null) {
                await ApiClient.updateCollar(collarInfo['id'], {
                  'livestockId': created['id'],
                });
              }
            }
          }
          syncedLocalList[i] = item;
        }
      } catch (e) {
        debugPrint('Error syncing local cow: $e');
      }
    }

    if (needSave) {
      await _saveLocalLivestock(syncedLocalList);
    }

    try {
      final remoteData = await ApiClient.getLivestock(farmerId);
      final List<dynamic> resultList = [];

      // Map remote items and merge local names / device codes
      for (var rawRemote in remoteData) {
        final remoteItem = Map<String, dynamic>.from(rawRemote);
        final remoteCollar = remoteItem['smartCollar'] as Map<String, dynamic>?;
        final deviceCode = remoteCollar?['deviceCode'];

        // Find matching local item by ID or collar code to preserve user-assigned name
        Map<String, dynamic>? localMatch;
        for (var l in syncedLocalList) {
          if (l is Map) {
            if (l['id'] == remoteItem['id'] || (deviceCode != null && (l['collarId'] == deviceCode || l['smartCollar']?['deviceCode'] == deviceCode))) {
              localMatch = Map<String, dynamic>.from(l);
              break;
            }
          }
        }

        if (localMatch != null && localMatch['name'] != null && localMatch['name'].toString().isNotEmpty) {
          remoteItem['name'] = localMatch['name'];
        }

        // If smartCollar GPS is 0.0 or null, attempt device location fetch
        final lat = (remoteCollar?['lastLatitude'] as num?)?.toDouble() ?? 0.0;
        final lng = (remoteCollar?['lastLongitude'] as num?)?.toDouble() ?? 0.0;
        if ((lat == 0.0 || lng == 0.0) && deviceCode != null) {
          try {
            final loc = await ApiClient.getDeviceLocation(deviceCode.toString());
            if (loc != null && (loc['latitude'] as num?)?.toDouble() != 0.0) {
              remoteItem['smartCollar'] = {
                ...?remoteCollar,
                'lastLatitude': (loc['latitude'] as num?)?.toDouble(),
                'lastLongitude': (loc['longitude'] as num?)?.toDouble(),
                'isOnline': loc['isOnline'] == true,
              };
            }
          } catch (_) {}
        }

        resultList.add(remoteItem);
      }

      // Add any unsynced local-only cattle (IDs starting with cattle-) that aren't in remote
      for (var l in syncedLocalList) {
        if (l is Map && l['id']?.toString().startsWith('cattle-') == true) {
          final lItem = Map<String, dynamic>.from(l);
          final collarCode = lItem['collarId'] ?? lItem['smartCollar']?['deviceCode'];
          if (collarCode != null) {
            try {
              final loc = await ApiClient.getDeviceLocation(collarCode.toString());
              if (loc != null) {
                lItem['smartCollar'] = {
                  'deviceCode': collarCode,
                  'lastLatitude': (loc['latitude'] as num?)?.toDouble(),
                  'lastLongitude': (loc['longitude'] as num?)?.toDouble(),
                  'isOnline': loc['isOnline'] == true,
                };
              }
            } catch (_) {}
          }
          resultList.add(lItem);
        }
      }

      await _saveLocalLivestock(resultList);
      return resultList;
    } catch (e) {
      debugPrint('Remote livestock fetch error: $e. Returning persisted local list.');
      return syncedLocalList;
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

    final collarDeviceCode = newAnimalData['collarId'];
    final Map<String, dynamic> postData = Map.from(newAnimalData)..remove('collarId');

    // Fetch live device location immediately if collar code is given
    Map<String, dynamic>? initialCollar;
    if (collarDeviceCode != null) {
      double lat = 0.0;
      double lng = 0.0;
      bool isOnline = true;
      try {
        final collarInfo = await ApiClient.getDeviceLocation(collarDeviceCode.toString());
        if (collarInfo != null) {
          lat = (collarInfo['latitude'] as num?)?.toDouble() ?? 0.0;
          lng = (collarInfo['longitude'] as num?)?.toDouble() ?? 0.0;
          isOnline = collarInfo['isOnline'] == true;
        }
      } catch (_) {}

      initialCollar = {
        'deviceCode': collarDeviceCode,
        'isOnline': isOnline,
        'lastLatitude': lat,
        'lastLongitude': lng,
      };
    }

    final newItem = {
      'id': 'cattle-${DateTime.now().millisecondsSinceEpoch}',
      ...postData,
      'farmerId': farmerId,
      'createdAt': DateTime.now().toIso8601String(),
      if (initialCollar != null) 'smartCollar': initialCollar,
    };

    final currentList = state.value ?? [];
    final updatedList = [newItem, ...currentList];

    state = AsyncValue.data(updatedList);
    await _saveLocalLivestock(updatedList);

    try {
      final created = await ApiClient.createLivestock({
        ...postData,
        'farmerId': farmerId,
      });

      if (collarDeviceCode != null && created['id'] != null) {
        final collarInfo = await ApiClient.getDeviceLocation(collarDeviceCode.toString());
        if (collarInfo != null && collarInfo['id'] != null) {
          await ApiClient.updateCollar(collarInfo['id'], {
            'livestockId': created['id'],
          });
        }
      }

      await refresh();
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
