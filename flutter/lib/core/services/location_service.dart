import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class LocationService {
  /// Fetches the user's real physical location coordinates.
  /// Uses native Geolocator GPS on Mobile/Web, multi-provider IP Geolocation on Desktop/Emulators.
  static Future<Map<String, double>> getStrictRealLocation() async {
    // 1. Try Native Device GPS via Geolocator
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission != LocationPermission.denied && permission != LocationPermission.deniedForever) {
          final pos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: Duration(seconds: 5),
            ),
          );
          return {'lat': pos.latitude, 'lng': pos.longitude};
        }
      }
    } catch (e) {
      debugPrint('Native Geolocator channel not active on this platform: $e');
    }

    // 2. Real Physical Network IP-based GPS Lookup with Multiple Providers (for Emulators / Desktop)
    final providers = [
      'http://ip-api.com/json/',
      'https://ipapi.co/json/',
      'https://ipwho.is/',
    ];

    for (final provider in providers) {
      try {
        final res = await http.get(Uri.parse(provider)).timeout(const Duration(seconds: 4));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          double? lat;
          double? lng;

          if (data['lat'] != null && data['lon'] != null) {
            lat = (data['lat'] as num).toDouble();
            lng = (data['lon'] as num).toDouble();
          } else if (data['latitude'] != null && data['longitude'] != null) {
            lat = (data['latitude'] as num).toDouble();
            lng = (data['longitude'] as num).toDouble();
          }

          if (lat != null && lng != null) {
            debugPrint('✅ IP Geolocation success from $provider: $lat, $lng');
            return {'lat': lat, 'lng': lng};
          }
        }
      } catch (e) {
        debugPrint('IP provider $provider failed: $e');
      }
    }

    // 3. Fallback coordinates for Bangladesh center (Dhaka) if hardware GPS and IP lookups are blocked
    debugPrint('⚠️ Hardware GPS and IP lookups unavailable. Returning default Bangladesh location.');
    return {'lat': 23.8103, 'lng': 90.4125};
  }

  /// Reverse geocodes coordinates to a human-readable area/city name using OpenStreetMap Nominatim API.
  static Future<String> getAreaNameFromCoordinates(double lat, double lng) async {
    try {
      final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&accept-language=bn');
      final res = await http.get(url, headers: {'User-Agent': 'com.example.farm_flutter'}).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final address = data['address'] as Map<String, dynamic>?;

        if (address != null) {
          final parts = [
            address['suburb'] ?? address['neighbourhood'] ?? address['village'] ?? address['town'],
            address['county'] ?? address['city'] ?? address['district'] ?? address['state_district'],
            address['state'] ?? address['country'],
          ].where((e) => e != null && e.toString().isNotEmpty).toList();

          if (parts.isNotEmpty) {
            return parts.take(2).join(', ');
          }
        }
        if (data['display_name'] != null) {
          final String displayName = data['display_name'].toString();
          return displayName.split(', ').take(2).join(', ');
        }
      }
    } catch (e) {
      debugPrint('Reverse geocoding error: $e');
    }
    return 'বগুড়া সদর জোন';
  }
}
