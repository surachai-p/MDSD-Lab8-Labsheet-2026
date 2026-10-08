import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const String _model = 'gemini-3.8-flash';
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent';

  Future<String> generateText(String prompt) async {
    if (_apiKey.isEmpty) {
      throw Exception(
        'ไม่พบ GEMINI_API_KEY กรุณาระบุผ่าน --dart-define=GEMINI_API_KEY=your_key',
      );
    }

    final url = Uri.parse(_baseUrl);
    final headers = {
      'Content-Type': 'application/json',
      'x-goog-api-key': _apiKey,
    };
    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt},
          ],
        },
      ],
    });

    try {
      final response = await http
          .post(url, headers: headers, body: body)
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final candidates = data['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final firstCandidate = candidates[0];
          final content = firstCandidate['content'];
          if (content != null && content['parts'] != null) {
            final parts = content['parts'] as List;
            if (parts.isNotEmpty && parts[0]['text'] != null) {
              return parts[0]['text'] as String;
            }
          }
        }
        throw Exception('ไม่พบข้อความตอบกลับจาก Gemini (candidates ว่างเปล่า)');
      } else {
        if (response.statusCode == 401 || response.statusCode == 403) {
          throw Exception(
            'Gemini API ปฏิเสธ API key กรุณาสร้าง key ใหม่จาก Google AI Studio และตรวจสอบว่าเปิดใช้ Gemini API แล้ว',
          );
        }
        throw Exception(
          'เกิดข้อผิดพลาดจาก Gemini API (สถานะ ${response.statusCode}): ${response.body}',
        );
      }
    } on TimeoutException {
      throw Exception('การเชื่อมต่อ Gemini API หมดเวลา (เกิน 20 วินาที)');
    } on http.ClientException {
      throw Exception(
        'ไม่สามารถเชื่อมต่ออินเทอร์เน็ตได้ กรุณาตรวจสอบการเชื่อมต่อ',
      );
    } catch (e) {
      rethrow;
    }
  }
}
