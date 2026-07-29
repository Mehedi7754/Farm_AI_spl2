import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';

// Provides lat/lng state, can be updated dynamically via GPS
final locationProvider = StateProvider<Map<String, double>>((ref) {
  return {'lat': 24.8481, 'lng': 89.3730}; // Default to Bogura
});

final weatherProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final location = ref.watch(locationProvider);
  return ApiClient.getWeather(lat: location['lat']!, lng: location['lng']!);
});
