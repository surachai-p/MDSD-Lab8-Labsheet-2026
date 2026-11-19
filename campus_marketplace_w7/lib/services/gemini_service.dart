import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class GeminiService {
  static const _apiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const _model = 'gemini-2.5-flash';

  Future<String> generateText(String prompt) async {
    _ensureApiKey();
    final response = await http
        .post(
          Uri.parse(
            'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$_apiKey',
          ),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {
                'parts': [
                  {'text': prompt},
                ],
              },
            ],
          }),
        )
        .timeout(const Duration(seconds: 20));

    final data = _decodeResponse(response);
    final candidates = data['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) {
      throw Exception('Gemini ไม่สามารถสร้างคำตอบได้ในขณะนี้');
    }
    final parts =
        (candidates.first as Map<String, dynamic>)['content']?['parts']
            as List<dynamic>?;
    final text = parts?.isNotEmpty == true
        ? (parts!.first as Map<String, dynamic>)['text'] as String?
        : null;
    if (text == null || text.trim().isEmpty) {
      throw Exception('Gemini ส่งคำตอบว่างกลับมา');
    }
    return text;
  }

  void _ensureApiKey() {
    if (_apiKey.isEmpty) {
      throw Exception(
        'ไม่พบ Gemini API key: รันด้วย --dart-define=GEMINI_API_KEY=your_key',
      );
    }
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message =
          (data['error'] as Map<String, dynamic>?)?['message'] ??
          'Gemini API error (${response.statusCode})';
      throw Exception(message);
    }
    return data;
  }
}
