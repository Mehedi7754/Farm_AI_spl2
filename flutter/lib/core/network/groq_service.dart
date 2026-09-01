import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GroqService {
  static String get _groqApiKey {
    try {
      if (dotenv.isInitialized && dotenv.env['GROQ_API_KEY'] != null && dotenv.env['GROQ_API_KEY']!.isNotEmpty) {
        return dotenv.env['GROQ_API_KEY']!;
      }
    } catch (_) {}
    return '';
  }

  static const String _groqEndpoint = 'https://api.groq.com/openai/v1/chat/completions';
  static const String defaultModel = 'llama-3.3-70b-versatile';

  static String extractCleanAnswer(String rawResponse) {
    if (rawResponse.trim().isEmpty) return '';

    try {
      final parsed = jsonDecode(rawResponse);
      if (parsed is Map && parsed.containsKey('answer')) {
        return parsed['answer'].toString().trim();
      }
    } catch (_) {
      final regExp = RegExp(r'"answer"\s*:\s*"([^"]+)"');
      final match = regExp.firstMatch(rawResponse);
      if (match != null && match.group(1) != null) {
        return match.group(1)!.replaceAll(r'\"', '"').replaceAll(r'\n', ' ').trim();
      }
    }

    return rawResponse
        .replaceAll(RegExp(r'[\{\}\"\[\]]'), '')
        .replaceAll(RegExp(r'[\*\#\-\_\`\~\:\;]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String buildSystemPrompt({required bool isFirstMessage}) {
    if (isFirstMessage) {
      return '''
You are a senior veterinary surgeon and livestock doctor. Respond strictly in JSON format with key "answer".
JSON schema: {"answer": "string"}

Rules:
1. Start the first message with: "আসসালামু আলাইকুম। আমি FarmAI ভেটেরিনারি সহকারী।"
2. Provide a 1-2 sentence professional Bengali answer. Keep it brief and direct.
3. No emojis, no markdown symbols, no extra JSON keys.
'''.trim();
    } else {
      return '''
You are a senior veterinary surgeon and livestock doctor. Respond strictly in JSON format with key "answer".
JSON schema: {"answer": "string"}

Rules:
1. Do not repeat greetings. Answer directly.
2. Provide a 1-2 sentence professional Bengali answer. Keep it brief and direct.
3. No emojis, no markdown symbols, no extra JSON keys.
'''.trim();
    }
  }

  static Future<String> chatCompletion({
    required String prompt,
    List<Map<String, String>> history = const [],
    String model = defaultModel,
  }) async {
    try {
      final isFirstMessage = history.isEmpty;
      final messages = <Map<String, String>>[
        {
          'role': 'system',
          'content': buildSystemPrompt(isFirstMessage: isFirstMessage),
        },
        ...history.take(4),
        {'role': 'user', 'content': prompt},
      ];

      final response = await http.post(
        Uri.parse(_groqEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_groqApiKey',
        },
        body: jsonEncode({
          'model': model,
          'response_format': {'type': 'json_object'},
          'messages': messages,
          'temperature': 0.3,
          'max_completion_tokens': 400,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final rawContent = data['choices']?[0]?['message']?['content']?.toString() ?? '';
        final cleanAnswer = extractCleanAnswer(rawContent);
        if (cleanAnswer.isNotEmpty) {
          return cleanAnswer;
        }
      } else {
        debugPrint('Groq API HTTP Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('Groq API Exception: $e');
    }

    return 'আক্রান্ত পশুকে পরিষ্কার স্থানে রাখুন, পর্যাপ্ত বিশুদ্ধ পানি দিন এবং ভেটেরিনারি চিকিৎসকের পরামর্শ নিন।';
  }
}
