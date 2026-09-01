import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';
import 'notification_store.dart';

/// Fetches real weather data on app cold start and sends a real push notification
/// to the OS notification panel using live data (temperature, rain, etc.)
class WeatherStartupService {
  static final WeatherStartupService _instance = WeatherStartupService._internal();
  factory WeatherStartupService() => _instance;
  WeatherStartupService._internal();

  static const _lastNotifKey = 'weather_startup_last_notif_ts';
  // Only fire once every 30 minutes to avoid spam
  static const _minIntervalMinutes = 30;

  /// Call this from main() after NotificationService is initialized.
  /// Fetches real weather from the backend and fires a notification.
  Future<void> fireOnColdStart() async {
    try {
      // Throttle: don't fire more than once per 30 minutes
      final prefs = await SharedPreferences.getInstance();
      final lastTs = prefs.getInt(_lastNotifKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - lastTs < _minIntervalMinutes * 60 * 1000) {
        debugPrint('[WeatherStartupService] Skipped (throttled)');
        return;
      }

      // Get cached location or use default (Bogura, Bangladesh)
      double lat = 24.8481;
      double lng = 89.3730;
      String locationName = 'বগুড়া, বাংলাদেশ';
      try {
        final cachedLoc = prefs.getString('cached_weather_location_name');
        if (cachedLoc != null && cachedLoc.isNotEmpty) locationName = cachedLoc;
        // Try reading cached lat/lng
        final cachedWeather = prefs.getString('cached_weather_data_v2');
        if (cachedWeather != null) {
          final cached = jsonDecode(cachedWeather) as Map<String, dynamic>;
          lat = (cached['lat'] as num?)?.toDouble() ?? lat;
          lng = (cached['lng'] as num?)?.toDouble() ?? lng;
        }
      } catch (_) {}

      // Fetch real weather from backend
      final apiBase = _getApiBase(prefs);
      final uri = Uri.parse('$apiBase/weather?lat=$lat&lng=$lng');
      final response = await http.get(uri, headers: {
        'Authorization': 'Bearer ${_getToken(prefs)}',
      }).timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return;

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      final temp = (data['currentTemperature'] as num?)?.toDouble() ?? 30.0;
      final humidity = (data['humidity'] as num?)?.toInt() ?? 65;
      final windSpeed = (data['windSpeed'] as num?)?.toDouble() ?? 0.0;
      final weatherCode = (data['weatherCode'] as num?)?.toInt() ?? 0;
      final isHeatStress = data['isHeatStress'] as bool? ?? false;
      final isStorm = data['isStormWarning'] as bool? ?? false;
      final advice = data['agriculturalAdvice'] as String? ?? '';
      final forecast = data['forecast'] as List<dynamic>? ?? [];

      // Build real notification title & body
      final weatherStatus = _weatherStatus(weatherCode);
      final todayPrecip = forecast.isNotEmpty
          ? (forecast[0]['precipitation'] as num?)?.toDouble() ?? 0.0
          : 0.0;

      String title;
      String body;

      if (isStorm) {
        title = '⛈️ ঝড়ের সতর্কতা — $locationName';
        body = advice.isNotEmpty
            ? advice
            : 'তাপমাত্রা ${temp.round()}°C। ঝড়ের সম্ভাবনা। পশুকে নিরাপদ স্থানে রাখুন।';
      } else if (isHeatStress) {
        title = '🌡️ তাপ চাপ — ${temp.round()}°C ($locationName)';
        body = advice.isNotEmpty
            ? advice
            : 'তাপমাত্রা ${temp.round()}°C, আর্দ্রতা $humidity%। পশুদের ছায়ায় রাখুন ও পানি দিন।';
      } else if (todayPrecip > 5) {
        title = '🌧️ বৃষ্টির পূর্বাভাস — $locationName';
        body =
            'আজ ${todayPrecip.toStringAsFixed(1)} মিমি বৃষ্টির সম্ভাবনা। তাপমাত্রা ${temp.round()}°C। পশুকে শেডে রাখুন।';
      } else {
        title = '🌤️ আজকের আবহাওয়া — $locationName';
        body =
            'তাপমাত্রা ${temp.round()}°C, আর্দ্রতা $humidity%, বাতাস ${windSpeed.round()}km/h। আবহাওয়া: $weatherStatus।';
      }

      // Show the OS-level notification
      await NotificationService().showColdStartWeatherNotification(
        title: title,
        body: body,
      );

      // Also store in in-app notification center
      await NotificationStore().push(
        id: 'weather_startup',
        type: 'weather',
        title: title,
        body: body,
      );

      // Schedule tomorrow's forecast if 2+ days available
      if (forecast.length > 1) {
        final tomorrow = forecast[1] as Map<String, dynamic>;
        final tMax = (tomorrow['tempMax'] as num?)?.toDouble() ?? temp;
        final tMin = (tomorrow['tempMin'] as num?)?.toDouble() ?? (temp - 5);
        final tPrecip = (tomorrow['precipitation'] as num?)?.toDouble() ?? 0.0;
        final tSummary =
            'আগামীকাল তাপমাত্রা ${tMax.round()}°/${tMin.round()}°C'
            '${tPrecip > 2 ? ', বৃষ্টি ${tPrecip.toStringAsFixed(1)} মিমি।' : ', পরিষ্কার আকাশ।'}';
        await NotificationService().scheduleTomorrowWeatherForecast(
          weatherSummary: tSummary,
          location: locationName,
          hour: 6,
          minute: 30,
        );
      }

      // Record timestamp
      await prefs.setInt(_lastNotifKey, now);
      debugPrint('[WeatherStartupService] Cold-start notification fired: $title');
    } catch (e) {
      debugPrint('[WeatherStartupService] Error: $e');
    }
  }

  String _getApiBase(SharedPreferences prefs) {
    return 'http://farm-ai-backend.163.227.239.97.sslip.io';
  }

  String _getToken(SharedPreferences prefs) {
    return prefs.getString('auth_token') ?? '';
  }

  String _weatherStatus(int code) {
    if (code == 0) return 'পরিষ্কার আকাশ';
    if (code >= 1 && code <= 3) return 'আংশিক মেঘলা';
    if (code >= 45 && code <= 48) return 'কুয়াশাচ্ছন্ন';
    if (code >= 51 && code <= 67) return 'বৃষ্টিপাত';
    if (code >= 71 && code <= 77) return 'তুষারপাত';
    if (code >= 80 && code <= 82) return 'ভারী বৃষ্টি';
    if (code >= 95 && code <= 99) return 'বজ্রঝড়';
    return 'মেঘলা';
  }
}
