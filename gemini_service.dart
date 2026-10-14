import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  static const String apiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const String apiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash-lite:generateContent';

  static const List<String> _models = [
    'gemini-3.5-flash-lite',
    'gemini-3.8-flash',
  ];

  Future<String> generateText(String prompt) async {
    String lastError = '';

    for (final model in _models) {
      final uri = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey');

      try {
        final response = await http.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {
                'parts': [
                  {'text': prompt}
                ]
              }
            ]
          }),
        ).timeout(const Duration(seconds: 20));

        if (response.statusCode == 200) {
          final decodedResponse = jsonDecode(response.body);
          final candidates = decodedResponse['candidates'] as List<dynamic>?;

          if (candidates != null && candidates.isNotEmpty) {
            final content = candidates.first['content'];
            if (content != null && content['parts'] != null) {
              final parts = content['parts'] as List<dynamic>;
              if (parts.isNotEmpty) {
                return parts.first['text'] as String;
              }
            }
          }
          throw Exception('API returned success but candidates data is missing or invalid.');
        } else if (response.statusCode == 503) {
          lastError = 'เซิร์ฟเวอร์ AI มีผู้ใช้งานหนาแน่นชั่วคราว (503)';
          continue;
        } else if (response.statusCode == 429) {
          throw Exception('โควตาการใช้งาน API ชั่วคราวเต็ม (429) กรุณารอสักครู่');
        } else {
          lastError = 'Failed to generate text. Status Code: ${response.statusCode} - Body: ${response.body}';
        }
      } on TimeoutException {
        lastError = 'Request timed out.';
        continue;
      } catch (e) {
        lastError = 'An error occurred: $e';
      }
    }

    throw Exception(lastError.isNotEmpty ? lastError : 'Request timed out.');
  }
}
