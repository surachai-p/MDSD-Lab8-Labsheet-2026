import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  // ดึงค่าจากตอนรันแอป (--dart-define) เพื่อไม่ให้ API Key หลุดไปในโค้ด
  static const _apiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const _model = 'gemini-3.5-flash-lite';
  static const _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent';

  Future<String> generateText(String prompt) async {
    if (_apiKey.isEmpty) {
      throw Exception('ไม่พบ API Key กรุณาใส่ --dart-define=GEMINI_API_KEY=your_key ตอนรันแอป');
    }

    final url = Uri.parse('$_baseUrl?key=$_apiKey');
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode({
      "contents": [{
        "parts": [{"text": prompt}]
      }]
    });

    try {
      // ตั้ง Timeout ไว้ที่ 20 วินาที
      final response = await http.post(url, headers: headers, body: body).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['candidates'] != null && (data['candidates'] as List).isNotEmpty) {
          final candidate = data['candidates'][0];
          
          if (candidate['finishReason'] == 'SAFETY') {
            throw Exception('เนื้อหาถูกบล็อกโดยระบบความปลอดภัย');
          }
          
          return candidate['content']['parts'][0]['text'] ?? 'ไม่มีข้อความตอบกลับ';
        }
        throw Exception('AI ไม่สามารถให้คำตอบได้');
      }
      throw Exception('เซิร์ฟเวอร์ตอบกลับรหัส: ${response.statusCode}');
    } catch (e) {
      throw Exception('เกิดข้อผิดพลาด: $e');
    }
  }
}