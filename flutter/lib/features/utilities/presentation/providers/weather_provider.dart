import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../../../core/network/api_client.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/notification_store.dart';

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

      // ── Push notification triggers ────────────────────────────────────────
      final isStorm = liveWeather['isStormWarning'] as bool? ?? false;
      final isHeat = liveWeather['isHeatStress'] as bool? ?? false;
      final advice = liveWeather['agriculturalAdvice'] as String? ?? '';
      final temp = (liveWeather['currentTemperature'] as num?)?.toDouble() ?? 30.0;
      final humidity = (liveWeather['humidity'] as num?)?.toInt() ?? 65;
      final notifSvc = NotificationService();
      final store = NotificationStore();

      // Get today's precipitation from forecast
      final forecastList = liveWeather['forecast'] as List<dynamic>? ?? [];
      final todayPrecip = forecastList.isNotEmpty
          ? (forecastList[0]['precipitation'] as num?)?.toDouble() ?? 0.0
          : 0.0;

      if (isStorm) {
        final t = '⛈️ ঝড়ের সতর্কতা — $resolvedName';
        final b = advice.isNotEmpty
            ? advice
            : 'তাপমাত্রা ${temp.round()}°C। ঝড়ের সম্ভাবনা। পশুকে নিরাপদ স্থানে রাখুন।';
        await notifSvc.showWeatherAlert(title: t, body: b, payload: 'WEATHER_STORM');
        await store.push(id: 'weather_storm_${DateTime.now().millisecondsSinceEpoch}', type: 'weather', title: t, body: b);
      } else if (isHeat) {
        final t = '🌡️ তাপ চাপ সতর্কতা — ${temp.round()}°C';
        final b = advice.isNotEmpty
            ? advice
            : 'তাপমাত্রা ${temp.round()}°C, আর্দ্রতা $humidity%। পশুদের ছায়ায় রাখুন ও পানি দিন।';
        await notifSvc.showWeatherAlert(title: t, body: b, payload: 'WEATHER_HEAT');
        await store.push(id: 'weather_heat_${DateTime.now().millisecondsSinceEpoch}', type: 'weather', title: t, body: b);
      } else if (todayPrecip > 10) {
        final t = '🌧️ ভারী বৃষ্টিপাতের সতর্কতা — $resolvedName';
        final b = 'আজ ${todayPrecip.toStringAsFixed(1)} মিমি বৃষ্টির সম্ভাবনা। তাপমাত্রা ${temp.round()}°C। পশুকে শেডে রাখুন।';
        await notifSvc.showWeatherAlert(title: t, body: b, payload: 'WEATHER_RAIN');
        await store.push(id: 'weather_rain_${DateTime.now().millisecondsSinceEpoch}', type: 'weather', title: t, body: b);
      }

      // Schedule tomorrow's forecast notification at 06:30 AM
      if (forecastList.length > 1) {
        final tomorrow = forecastList[1];
        final tMaxTemp = (tomorrow['tempMax'] as num?)?.toDouble() ?? temp;
        final tMinTemp = (tomorrow['tempMin'] as num?)?.toDouble() ?? (temp - 5);
        final tPrecip = (tomorrow['precipitation'] as num?)?.toDouble() ?? 0.0;
        final tSummary =
            'আগামীকাল তাপমাত্রা ${tMaxTemp.round()}°/${tMinTemp.round()}°C'
            '${tPrecip > 2 ? ', বৃষ্টির সম্ভাবনা ${tPrecip.toStringAsFixed(1)} মিমি।' : '।'}';
        await notifSvc.scheduleTomorrowWeatherForecast(
          weatherSummary: tSummary,
          location: resolvedName,
          hour: 6,
          minute: 30,
        );
      }
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
