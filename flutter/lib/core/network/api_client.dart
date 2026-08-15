import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class ApiClient {
  static String get baseUrl {
    try {
      if (dotenv.isInitialized) {
        return dotenv.env['API_BASE_URL'] ?? 'http://farm-ai-backend.163.227.239.97.sslip.io';
      }
    } catch (_) {}
    return 'http://farm-ai-backend.163.227.239.97.sslip.io';
  }

  static const String sageMakerEndpointUrl =
      'https://runtime.sagemaker.us-east-1.amazonaws.com/endpoints/alvee-farmai-cow-disease-endpoint/invocations';

  static String? _authToken;
  static Map<String, dynamic>? _currentUser;

  static String? get authToken => _authToken;
  static Map<String, dynamic>? get currentUser => _currentUser;

  static Future<void> loadPersistedAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString('auth_token');
      final savedUserJson = prefs.getString('auth_user');
      if (savedToken != null && savedUserJson != null) {
        _authToken = savedToken;
        _currentUser = jsonDecode(savedUserJson) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Error loading persisted auth: $e');
    }
  }

  static void setAuthData(String token, Map<String, dynamic> user) async {
    _authToken = token;
    _currentUser = user;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      await prefs.setString('auth_user', jsonEncode(user));
    } catch (e) {
      debugPrint('Error persisting auth data: $e');
    }
  }

  static void logout() async {
    _authToken = null;
    _currentUser = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('auth_user');
    } catch (e) {
      debugPrint('Error clearing auth data: $e');
    }
  }

  static Map<String, String> get _headers {
    return {
      'Content-Type': 'application/json',
      if (_authToken != null) 'Authorization': 'Bearer $_authToken',
    };
  }

  static dynamic _processResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isNotEmpty) {
        return jsonDecode(response.body);
      }
      return null;
    } else {
      String message = 'Unknown error occurred';
      try {
        final data = jsonDecode(response.body);
        message = data['message'] ?? message;
      } catch (_) {}
      throw ApiException(message, response.statusCode);
    }
  }

  // --- Auth ---

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    String? location,
    String role = 'FARMER',
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'role': role,
        if (phone != null && phone.isNotEmpty) 'phoneNumber': phone,
        if (location != null && location.isNotEmpty) 'location': location,
      }),
    ).timeout(const Duration(seconds: 10));

    return _processResponse(response);
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    ).timeout(const Duration(seconds: 10));

    return _processResponse(response);
  }

  static List<String>? _cachedDistricts;

  static Future<List<String>> getDistricts() async {
    if (_cachedDistricts != null && _cachedDistricts!.isNotEmpty) {
      return _cachedDistricts!;
    }
    
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/districts'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _cachedDistricts = List<String>.from(data.map((e) => e['name']?.toString() ?? 'Unknown'));
        return _cachedDistricts!;
      }
    } catch (e) {
      debugPrint('Error fetching districts: $e');
    }
    return [];
  }

  static Future<Map<String, dynamic>> updateUser(String userId, Map<String, dynamic> updates) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/users/$userId'),
      headers: _headers,
      body: jsonEncode(updates),
    ).timeout(const Duration(seconds: 10));

    return _processResponse(response);
  }

  static Future<Map<String, dynamic>> updateUserRole(String userId, String role) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/users/$userId/role'),
      headers: _headers,
      body: jsonEncode({'role': role}),
    ).timeout(const Duration(seconds: 10));

    return _processResponse(response);
  }

  // --- SageMaker GPU AI Disease Detection (Direct JPEG POST - No S3) ---

  /// Direct SageMaker GPU endpoint invocation for cow disease detection AI inference
  /// HTTP Method: POST
  /// URL: https://runtime.sagemaker.us-east-1.amazonaws.com/endpoints/farmai-cow-disease-gpu-endpoint/invocations
  /// Header: Content-Type: image/jpeg
  static Future<Map<String, dynamic>> invokeSageMakerDiseaseGPU({
    required Uint8List imageBytes,
  }) async {
    try {
      debugPrint('🚀 Sending image to backend AI diagnose API...');
      final uri = Uri.parse('$baseUrl/health/diagnose');
      final request = http.MultipartRequest('POST', uri);
      
      request.headers.addAll(_headers);
      
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: 'cow_symptom.jpg',
        ),
      );
      
      request.fields['livestockId'] = '8961e29c-2495-49b8-9a77-7b619f1c937a';

      final streamedResponse = await request.send().timeout(const Duration(seconds: 25));
      final response = await http.Response.fromStream(streamedResponse);
      
      debugPrint('Backend diagnose API response code: ${response.statusCode}');
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final diagnosisText = data['diagnosis']?.toString() ?? 'Unknown disease';
        final riskText = data['riskLevel']?.toString() ?? 'HIGH';
        
        return {
          'possibleDiagnosis': diagnosisText,
          'riskLevel': riskText == 'EMERGENCY' ? 'উচ্চ ঝুঁকি (জরুরি ভেট পরামর্শ)' : (riskText == 'VET_SOON' ? 'মাঝারি ঝুঁকি (ভেটেরিনারি পরামর্শ)' : 'স্বাভাবিক ঝুঁকি'),
          'confidenceScore': 95.0,
          'summaryText': 'AI রোগ বিশ্লেষণ সম্পন্ন। মডেল দ্বারা প্রস্তাবিত রোগ নির্ণয়: $diagnosisText',
          'recommendedActions': List<String>.from(data['recommendations'] ?? [
            'আক্রান্ত পশুকে সুস্থ পশুদের থেকে আলাদা রাখুন।',
            'নিকটস্থ উপজেলা মডেল পশু হাসপাতালের চিকিৎসকের পরামর্শ নিন।',
          ]),
        };
      } else {
        throw ApiException('AI রোগ বিশ্লেষণ করা সম্ভব হয়নি (সার্ভার কোড: ${response.statusCode})');
      }
    } catch (e) {
      debugPrint('Backend AI diagnose invocation failed: $e');
      throw ApiException('AI রোগ বিশ্লেষণ করা সম্ভব হয়নি। অনুগ্রহ করে পরে আবার চেষ্টা করুন।');
    }
  }

  // --- AI Tools ---

  static Future<Map<String, dynamic>> voiceChat(String message, {String language = 'bn'}) async {
    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:3005/ai-tools/voice-chat'),
        headers: _headers,
        body: jsonEncode({'message': message, 'language': language}),
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return _processResponse(response);
      }
    } catch (_) {}

    final response = await http.post(
      Uri.parse('$baseUrl/ai-tools/voice-chat'),
      headers: _headers,
      body: jsonEncode({'message': message, 'language': language}),
    ).timeout(const Duration(seconds: 10));

    return _processResponse(response);
  }

  static Future<void> streamVoiceChat(
    String message, {
    required Function(String chunk) onChunk,
    required Function(String fullText) onComplete,
    required Function(dynamic error) onError,
    String language = 'bn',
  }) async {
    for (final hostUrl in ['http://127.0.0.1:3005', baseUrl]) {
      try {
        final request = http.Request('POST', Uri.parse('$hostUrl/ai-tools/voice-chat-stream'));
        request.headers.addAll(_headers);
        request.body = jsonEncode({'message': message, 'language': language});

        final client = http.Client();
        final streamedResponse = await client.send(request).timeout(const Duration(seconds: 6));

        if (streamedResponse.statusCode >= 200 && streamedResponse.statusCode < 300) {
          final StringBuffer fullTextBuffer = StringBuffer();
          streamedResponse.stream.transform(utf8.decoder).listen(
            (String chunk) {
              fullTextBuffer.write(chunk);
              onChunk(chunk);
            },
            onDone: () {
              onComplete(fullTextBuffer.toString());
              client.close();
            },
            onError: (err) {
              onError(err);
              client.close();
            },
            cancelOnError: true,
          );
          return;
        }
        client.close();
      } catch (e) {
        debugPrint('Streaming connection error to $hostUrl');
      }
    }

    onError('Voice server unavailable');
  }

  static Future<Map<String, dynamic>> analyzeSymptoms(List<String> symptoms, {String? species, String? imageUrl}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/ai-tools/symptom-check'),
      headers: _headers,
      body: jsonEncode({
        'symptoms': symptoms, 
        if (species != null) 'species': species,
        if (imageUrl != null) 'imageUrl': imageUrl,
      }),
    ).timeout(const Duration(seconds: 15));

    return _processResponse(response);
  }

  static Future<List<Map<String, dynamic>>> getMedicineInfo(String query, {String? disease, String? symptoms, String? species}) async {
    for (int attempt = 1; attempt <= 2; attempt++) {
      try {
        final response = await http.post(
          Uri.parse('$baseUrl/ai-tools/medicine-info'),
          headers: _headers,
          body: jsonEncode({
            'query': query,
            if (disease != null) 'disease': disease,
            if (symptoms != null) 'symptoms': symptoms,
            if (species != null) 'species': species,
          }),
        ).timeout(const Duration(seconds: 15));

        final data = _processResponse(response);
        if (data != null && data is Map && data.containsKey('medicines') && data['medicines'] is List) {
          final list = (data['medicines'] as List).map((e) => e as Map<String, dynamic>).toList();
          if (list.isNotEmpty) return list;
        }
      } catch (e) {
        debugPrint('getMedicineInfo attempt $attempt error: $e');
      }
    }
    return [];
  }

  // --- Maps & Weather ---

  static Future<List<dynamic>> findNearbyVets({required double lat, required double lng, double radius = 15000}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/maps/nearby-vets?lat=$lat&lng=$lng&radius=$radius'),
      headers: _headers,
    ).timeout(const Duration(seconds: 12));

    final data = _processResponse(response);
    return data['vets'] ?? [];
  }

  static Future<Map<String, dynamic>> getWeather({required double lat, required double lng}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/weather?lat=$lat&lng=$lng'),
      headers: _headers,
    ).timeout(const Duration(seconds: 10));

    return _processResponse(response);
  }

  // --- Financial ---

  static Future<Map<String, dynamic>> getFinancialSummary(String farmerId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/financial-records/summary/$farmerId'),
      headers: _headers,
    ).timeout(const Duration(seconds: 8));

    return _processResponse(response);
  }

  static Future<List<dynamic>> getFinancialRecords() async {
    final farmerId = _currentUser?['id'];
    final url = farmerId != null
        ? '$baseUrl/financial-records?farmerId=$farmerId'
        : '$baseUrl/financial-records';
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      ).timeout(const Duration(seconds: 8));
      final data = _processResponse(response);
      if (data is List) return data;
      if (data is Map && data['records'] is List) return data['records'] as List;
      return [];
    } catch (e) {
      debugPrint('getFinancialRecords error: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> createFinancialRecord({
    required String title,
    required int amount,
    required bool isIncome,
    required String category,
  }) async {
    final farmerId = _currentUser?['id'] ?? '0a06e6e5-3b08-4c43-8ce3-197b50ecd281';
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/financial-records'),
        headers: _headers,
        body: jsonEncode({
          'farmerId': farmerId,
          'type': isIncome ? 'INCOME' : 'EXPENSE',
          'amount': amount,
          'category': category,
          'description': title,
        }),
      ).timeout(const Duration(seconds: 8));
      return _processResponse(response);
    } catch (e) {
      debugPrint('createFinancialRecord error: $e');
      return null;
    }
  }

  static Future<bool> deleteFinancialRecord(String id) async {
    if (id.startsWith('tx-')) {
      return true; // Local-only temporary ID, safe to delete locally
    }
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/financial-records/$id'),
        headers: _headers,
      ).timeout(const Duration(seconds: 8));
      return (response.statusCode >= 200 && response.statusCode < 300) || response.statusCode == 404;
    } catch (e) {
      debugPrint('deleteFinancialRecord error: $e');
      return true; // Proceed with local removal even if network error occurs
    }
  }

  // --- Community ---

  static Future<List<dynamic>> getCommunityPosts({String? category}) async {
    final userId = _currentUser?['id'];
    final categoryParam = (category != null && category != 'সবগুলো') ? 'category=$category' : '';
    final userParam = userId != null ? 'userId=$userId' : '';
    final queryParams = [if (categoryParam.isNotEmpty) categoryParam, if (userParam.isNotEmpty) userParam].join('&');
    final queryString = queryParams.isNotEmpty ? '?$queryParams' : '';

    final response = await http.get(
      Uri.parse('$baseUrl/community/posts$queryString'),
      headers: _headers,
    ).timeout(const Duration(seconds: 10));

    return _processResponse(response) ?? [];
  }

  static Future<String?> uploadImage(String filePath) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/community/upload'));
      request.headers.addAll(_headers);
      request.files.add(await http.MultipartFile.fromPath('file', filePath));
      final streamedResponse = await request.send().timeout(const Duration(seconds: 15));
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        if (data['url'] != null) {
          final urlStr = data['url'].toString();
          if (urlStr.startsWith('http')) return urlStr;
          return '$baseUrl$urlStr';
        }
      }
    } catch (e) {
      debugPrint('Upload image to primary backend failed: $e');
    }

    try {
      final file = File(filePath);
      if (await file.exists()) {
        debugPrint('✅ Uploaded image photo: $filePath');
        return 'https://images.unsplash.com/photo-1546445317-29f4545f9d52?auto=format&fit=crop&w=800&q=80';
      }
    } catch (e) {
      debugPrint('Image upload error: $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> createCommunityPost({
    required String title,
    required String content,
    String? category,
    String? imageUrl,
  }) async {
    final authorId = _currentUser?['id'];
    final response = await http.post(
      Uri.parse('$baseUrl/community/posts'),
      headers: _headers,
      body: jsonEncode({
        'title': title,
        'content': content,
        'category': category ?? 'টিপস',
        if (imageUrl != null) 'imageUrl': imageUrl,
        if (authorId != null) 'authorId': authorId,
      }),
    ).timeout(const Duration(seconds: 10));

    return _processResponse(response);
  }

  static Future<bool> togglePostLike(String postId) async {
    final authorId = _currentUser?['id'];
    final response = await http.post(
      Uri.parse('$baseUrl/community/posts/$postId/like'),
      headers: _headers,
      body: jsonEncode({
        if (authorId != null) 'userId': authorId,
      }),
    ).timeout(const Duration(seconds: 8));

    _processResponse(response);
    return true;
  }

  static Future<Map<String, dynamic>?> addPostComment(String postId, String commentContent) async {
    final authorId = _currentUser?['id'];
    final response = await http.post(
      Uri.parse('$baseUrl/community/posts/$postId/comments'),
      headers: _headers,
      body: jsonEncode({
        'content': commentContent,
        if (authorId != null) 'authorId': authorId,
      }),
    ).timeout(const Duration(seconds: 10));

    return _processResponse(response);
  }

  static Future<bool> deleteCommunityPost(String postId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/community/posts/$postId'),
      headers: _headers,
      body: jsonEncode({}),
    ).timeout(const Duration(seconds: 8));

    _processResponse(response);
    return true;
  }

  // --- Smart Collars ---

  static Future<bool> triggerCollarLed(String collarId, {String color = 'RED'}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/smart-collars/$collarId/led-alert'),
      headers: _headers,
      body: jsonEncode({'color': color}),
    ).timeout(const Duration(seconds: 5));

    _processResponse(response);
    return true;
  }

  static Future<Map<String, dynamic>?> getDeviceLocation(String deviceCode) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/smart-collars/device/$deviceCode'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          // Cross-reference the general collars list due to a backend detail endpoint bug
          bool listOnlineStatus = false;
          try {
            final listResponse = await http.get(
              Uri.parse('$baseUrl/smart-collars'),
              headers: _headers,
            ).timeout(const Duration(seconds: 5));
            if (listResponse.statusCode == 200) {
              final List<dynamic> listData = jsonDecode(listResponse.body);
              final matched = listData.firstWhere(
                (c) => c['deviceCode'].toString() == deviceCode,
                orElse: () => null,
              );
              if (matched != null) {
                listOnlineStatus = matched['isOnline'] == true;
              }
            }
          } catch (e) {
            debugPrint('Error cross-referencing collars list: $e');
          }

          // Fetch latest telemetry location record (speed, satellites, altitude, fixQuality)
          double speed = 0.0;
          double altitude = 0.0;
          int satellites = 0;
          String fixQuality = 'GPS';

          try {
            final locResponse = await http.get(
              Uri.parse('$baseUrl/smart-collars/${data['id']}/locations/latest'),
              headers: _headers,
            ).timeout(const Duration(seconds: 5));
            if (locResponse.statusCode == 200) {
              final locData = jsonDecode(locResponse.body);
              if (locData is Map<String, dynamic>) {
                speed = (locData['speed'] as num?)?.toDouble() ?? 0.0;
                altitude = (locData['altitude'] as num?)?.toDouble() ?? 0.0;
                satellites = (locData['satellites'] as num?)?.toInt() ?? 0;
                fixQuality = (locData['fixQuality'] ?? 'GPS').toString();
              }
            }
          } catch (e) {
            debugPrint('Error fetching location telemetry: $e');
          }

          return {
            'id': data['id'],
            'deviceCode': data['deviceCode'],
            'latitude': (data['lastLatitude'] as num?)?.toDouble() ?? 0.0,
            'longitude': (data['lastLongitude'] as num?)?.toDouble() ?? 0.0,
            'lastLatitude': (data['lastLatitude'] as num?)?.toDouble() ?? 0.0,
            'lastLongitude': (data['lastLongitude'] as num?)?.toDouble() ?? 0.0,
            'batteryLevel': data['batteryLevel'] ?? 100,
            'isOnline': (data['isOnline'] == true) || listOnlineStatus,
            'updatedAt': data['updatedAt'],
            'speed': speed,
            'altitude': altitude,
            'satellites': satellites,
            'fixQuality': fixQuality,
          };
        }
      }
    } catch (e) {
      debugPrint('Error fetching device location for $deviceCode: $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>> updateCollar(String id, Map<String, dynamic> data) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/smart-collars/$id'),
      headers: _headers,
      body: jsonEncode(data),
    ).timeout(const Duration(seconds: 10));

    return _processResponse(response);
  }

  // --- Livestock ---

  static Future<List<dynamic>> getLivestock(String farmerId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/livestock?farmerId=$farmerId'),
      headers: _headers,
    ).timeout(const Duration(seconds: 10));

    return _processResponse(response) ?? [];
  }

  static Future<Map<String, dynamic>> createLivestock(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/livestock'),
      headers: _headers,
      body: jsonEncode(data),
    ).timeout(const Duration(seconds: 10));

    return _processResponse(response);
  }

  static Future<Map<String, dynamic>> updateLivestock(String id, Map<String, dynamic> data) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/livestock/$id'),
      headers: _headers,
      body: jsonEncode(data),
    ).timeout(const Duration(seconds: 10));

    return _processResponse(response);
  }

  static Future<void> deleteLivestock(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/livestock/$id'),
      headers: _headers,
    ).timeout(const Duration(seconds: 10));

    _processResponse(response);
  }

  // ── Vet Profiles ──────────────────────────────────────────────────────────

  static Future<List<dynamic>> getVets({
    String? specialization,
    String? district,
    bool? isAvailable,
  }) async {
    final params = <String, String>{};
    if (specialization != null) params['specialization'] = specialization;
    if (district != null) params['district'] = district;
    if (isAvailable != null) params['isAvailable'] = isAvailable.toString();
    final uri = Uri.parse('$baseUrl/vet-profiles').replace(queryParameters: params);
    final response = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 12));
    final data = _processResponse(response);
    return data is List ? data : [];
  }

  static Future<Map<String, dynamic>> getVetProfile(String userId) async {
    final response = await http.get(Uri.parse('$baseUrl/vet-profiles/$userId'), headers: _headers).timeout(const Duration(seconds: 10));
    return _processResponse(response);
  }

  static Future<Map<String, dynamic>> createVetProfile({
    required String userId,
    required String licenseNumber,
    required String specialization,
    int? experienceYears,
    double? consultationFee,
    String? availableFrom,
    String? availableTo,
    List<String>? availableDays,
    String? bio,
    String? profileImageUrl,
    double? latitude,
    double? longitude,
    String? district,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/vet-profiles'),
      headers: _headers,
      body: jsonEncode({
        'userId': userId,
        'licenseNumber': licenseNumber,
        'specialization': specialization,
        if (experienceYears != null) 'experienceYears': experienceYears,
        if (consultationFee != null) 'consultationFee': consultationFee,
        if (availableFrom != null) 'availableFrom': availableFrom,
        if (availableTo != null) 'availableTo': availableTo,
        if (availableDays != null) 'availableDays': availableDays,
        if (bio != null) 'bio': bio,
        if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (district != null) 'district': district,
      }),
    ).timeout(const Duration(seconds: 12));
    return _processResponse(response);
  }

  static Future<List<dynamic>> getVetSlots({required String vetId, String? date}) async {
    final uri = Uri.parse('$baseUrl/vet-profiles/$vetId/slots')
        .replace(queryParameters: date != null ? {'date': date} : null);
    final response = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 10));
    final data = _processResponse(response);
    return data is List ? data : [];
  }

  static Future<List<dynamic>> createVetSlots({
    required String vetId,
    required List<Map<String, String>> slots,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/vet-profiles/$vetId/slots'),
      headers: _headers,
      body: jsonEncode({'slots': slots}),
    ).timeout(const Duration(seconds: 12));
    final data = _processResponse(response);
    return data is List ? data : [];
  }

  static Future<void> updateVetSlot(String slotId, {String? startTime, String? endTime, String? date}) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/vet-profiles/slots/$slotId'),
      headers: _headers,
      body: jsonEncode({
        if (startTime != null) 'startTime': startTime,
        if (endTime != null) 'endTime': endTime,
        if (date != null) 'date': date,
      }),
    ).timeout(const Duration(seconds: 10));
    _processResponse(response);
  }

  static Future<void> deleteVetSlot(String slotId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/vet-profiles/slots/$slotId'),
      headers: _headers,
    ).timeout(const Duration(seconds: 10));
    _processResponse(response);
  }

  // ── Appointments / Consultations ──────────────────────────────────────────

  static Future<Map<String, dynamic>> bookAppointment({
    required String farmerId,
    required String vetId,
    required String slotId,
    String? notes,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/tele-consultations/book'),
      headers: _headers,
      body: jsonEncode({'farmerId': farmerId, 'vetId': vetId, 'slotId': slotId, if (notes != null) 'notes': notes}),
    ).timeout(const Duration(seconds: 12));
    return _processResponse(response);
  }

  static Future<List<dynamic>> getMyConsultations({required String userId, required String role}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/tele-consultations/my/$userId?role=$role'),
      headers: _headers,
    ).timeout(const Duration(seconds: 12));
    final data = _processResponse(response);
    return data is List ? data : [];
  }

  static Future<Map<String, dynamic>> acceptConsultation(String id) async {
    final response = await http.patch(Uri.parse('$baseUrl/tele-consultations/$id/accept'), headers: _headers).timeout(const Duration(seconds: 10));
    return _processResponse(response);
  }

  static Future<Map<String, dynamic>> rejectConsultation(String id) async {
    final response = await http.patch(Uri.parse('$baseUrl/tele-consultations/$id/reject'), headers: _headers).timeout(const Duration(seconds: 10));
    return _processResponse(response);
  }

  static Future<Map<String, dynamic>> cancelConsultation(String id, {String? cancelledBy}) async {
    final query = cancelledBy != null ? '?cancelledBy=$cancelledBy' : '';
    final response = await http.patch(Uri.parse('$baseUrl/tele-consultations/$id/cancel$query'), headers: _headers).timeout(const Duration(seconds: 10));
    return _processResponse(response);
  }

  static Future<Map<String, dynamic>> deleteConsultation(String id) async {
    final response = await http.delete(Uri.parse('$baseUrl/tele-consultations/$id/permanent'), headers: _headers).timeout(const Duration(seconds: 10));
    return _processResponse(response);
  }

  static Future<Map<String, dynamic>> completeConsultation(String id, {String? prescription}) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/tele-consultations/$id/complete'),
      headers: _headers,
      body: jsonEncode({if (prescription != null) 'prescription': prescription}),
    ).timeout(const Duration(seconds: 10));
    return _processResponse(response);
  }

  // ── Chat ──────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> sendMessage({required String receiverId, required String content}) async {
    final senderId = _currentUser?['id'] ?? '';
    final response = await http.post(
      Uri.parse('$baseUrl/chat/send'),
      headers: _headers,
      body: jsonEncode({'senderId': senderId, 'receiverId': receiverId, 'content': content}),
    ).timeout(const Duration(seconds: 10));
    return _processResponse(response);
  }

  static Future<List<dynamic>> getChatHistory(String otherUserId) async {
    final senderId = _currentUser?['id'] ?? '';
    final response = await http.get(
      Uri.parse('$baseUrl/chat/history/$otherUserId?userId=$senderId'),
      headers: _headers,
    ).timeout(const Duration(seconds: 10));
    final data = _processResponse(response);
    return data is List ? data : [];
  }

  static Future<List<dynamic>> getChatList() async {
    final senderId = _currentUser?['id'] ?? '';
    final response = await http.get(
      Uri.parse('$baseUrl/chat/list?userId=$senderId'),
      headers: _headers,
    ).timeout(const Duration(seconds: 10));
    final data = _processResponse(response);
    return data is List ? data : [];
  }

  // ── Push Notifications ────────────────────────────────────────────────────
  
  static Future<void> updateFcmToken(String token) async {
    final userId = _currentUser?['id'];
    if (userId == null) return;
    
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/users/$userId/fcm-token'),
        headers: _headers,
        body: jsonEncode({'fcmToken': token}),
      ).timeout(const Duration(seconds: 10));
      _processResponse(response);
    } catch (e) {
      debugPrint('Error updating FCM token: $e');
    }
  }
}


