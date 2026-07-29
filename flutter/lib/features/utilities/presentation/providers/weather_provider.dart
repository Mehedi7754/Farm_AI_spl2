import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../../../core/network/api_client.dart';
import '../../../../core/services/location_service.dart';

class WeatherState {
  final Map<String, dynamic>? data;
  final String locationName;
  final bool isLoading;
  final String? error;

  const WeatherState({
    this.data,
    this.locationName = 'Dhaka, Bangladesh',
    this.isLoading = false,
    this.error,
  });

  WeatherState copyWith({
    Map<String, dynamic>? data,
    String? locationName,
    bool? isLoading,
    String? error,
  }) {
    return WeatherState(
      data: data ?? this.data,
      locationName: locationName ?? this.locationName,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class WeatherNotifier extends StateNotifier<WeatherState> {
  static const _cacheKey = 'cached_weather_data_v2';
  static const _locKey = 'cached_weather_location_name';

  WeatherNotifier() : super(const WeatherState(isLoading: true)) {
    _initAndFetch();
  }

  Future<void> _initAndFetch() async {
    // 1. Instantly load disk cache into memory state (0ms delay)
    final prefs = await SharedPreferences.getInstance();
    final cachedStr = prefs.getString(_cacheKey);
    final cachedLoc = prefs.getString(_locKey) ?? 'Dhaka, Bangladesh';

    if (cachedStr != null) {
      try {
        final Map<String, dynamic> cachedMap = jsonDecode(cachedStr);
        state = state.copyWith(
          data: cachedMap,
          locationName: cachedLoc,
          isLoading: false,
        );
      } catch (_) {}
    }

    // 2. Fetch fresh live location & weather in background silently
    await refreshWeather(silent: state.data != null);
  }

  Future<void> refreshWeather({bool silent = true}) async {
    if (!silent && state.data == null) {
      state = state.copyWith(isLoading: true);
    }

    try {
      double lat = 23.8103;
      double lng = 90.4125;
      try {
        final locMap = await LocationService.getStrictRealLocation();
        lat = locMap['lat']!;
        lng = locMap['lng']!;
      } catch (_) {}

      String resolvedName = 'Location: ${lat.toStringAsFixed(2)}°, ${lng.toStringAsFixed(2)}°';
      try {
        final uri = Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&zoom=10');
        final response = await http.get(uri, headers: {'User-Agent': 'FarmAI_App/1.0'}).timeout(const Duration(seconds: 4));
        if (response.statusCode == 200) {
          final resData = jsonDecode(response.body);
          final addr = resData['address'];
          if (addr != null) {
            final city = addr['city'] ?? addr['town'] ?? addr['village'] ?? addr['state_district'] ?? addr['county'];
            final country = addr['country'];
            if (city != null && country != null) {
              resolvedName = '$city, $country';
            } else if (resData['display_name'] != null) {
              final parts = (resData['display_name'] as String).split(', ');
              if (parts.length >= 2) {
                resolvedName = '${parts[0]}, ${parts.last}';
              }
            }
          }
        }
      } catch (e) {
        // Fallback to coordinates if network lookup fails
      }

      final liveWeather = await ApiClient.getWeather(lat: lat, lng: lng);
      liveWeather['lat'] = lat;
      liveWeather['lng'] = lng;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode(liveWeather));
      await prefs.setString(_locKey, resolvedName);

      state = state.copyWith(
        data: liveWeather,
        locationName: resolvedName,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      if (state.data == null) {
        state = state.copyWith(isLoading: false, error: e.toString());
      }
    }
  }
}

final weatherProvider = StateNotifierProvider<WeatherNotifier, WeatherState>((ref) {
  return WeatherNotifier();
});
