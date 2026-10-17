import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class GeminiVisionService {
  static const _apiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const _model = 'gemini-3.5-flash-lite';
  static const _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent';

  Future<Map<String, dynamic>> analyzeProductImage(File imageFile, String prompt) async {
    if (_apiKey.isEmpty) throw Exception('ไม่พบ API Key');

    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    final url = Uri.parse('$_baseUrl?key=$_apiKey');
    final headers = {'Content-Type': 'application/json'};
    
    // โครงสร้าง Request ที่เพิ่ม safetySettings แบบเข้มงวดสุดขีด
    final body = jsonEncode({
      "contents": [{
        "parts": [
          {"text": prompt},
          {"inline_data": {"mime_type": "image/jpeg", "data": base64Image}}
        ]
      }],
      // บังคับตั้งค่าความปลอดภัยให้บล็อกทุกกรณีที่มีความเสี่ยงเล็กน้อย
      "safetySettings": [
        {"category": "HARM_CATEGORY_HARASSMENT", "threshold": "BLOCK_LOW_AND_ABOVE"},
        {"category": "HARM_CATEGORY_HATE_SPEECH", "threshold": "BLOCK_LOW_AND_ABOVE"},
        {"category": "HARM_CATEGORY_SEXUALLY_EXPLICIT", "threshold": "BLOCK_LOW_AND_ABOVE"},
        {"category": "HARM_CATEGORY_DANGEROUS_CONTENT", "threshold": "BLOCK_LOW_AND_ABOVE"}
      ],
      "generationConfig": {
        "responseMimeType": "application/json",
        "responseSchema": {
          "type": "object",
          "properties": {
            "title": {"type": "string"},
            "category": {"type": "string"},
            "description": {"type": "string"}
          },
          "required": ["title", "category", "description"]
        }
      }
    });

    try {
      final response = await http.post(url, headers: headers, body: body).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // เช็คว่าโดนบล็อกตั้งแต่ Prompt Feedback หรือไม่
        if (data['promptFeedback'] != null && data['promptFeedback']['blockReason'] != null) {
          throw Exception('คำขอถูกบล็อกความปลอดภัย: ${data['promptFeedback']['blockReason']}');
        }

        if (data['candidates'] != null && (data['candidates'] as List).isNotEmpty) {
          final candidate = data['candidates'][0];
          
          // เช็คเหตุผลการจบการทำงาน ถ้าไม่ใช่ STOP แปลว่าโดนกรอง/บล็อก
          final finishReason = candidate['finishReason'];
          if (finishReason != 'STOP') {
            throw Exception('เนื้อหาถูกระงับเนื่องจากไม่ผ่านเกณฑ์ความปลอดภัย (FinishReason: $finishReason)');
          }

          if (candidate['content'] == null || candidate['content']['parts'] == null || (candidate['content']['parts'] as List).isEmpty) {
            throw Exception('คำขอถูกปฏิเสธโดยระบบ Safety Filter ของ Gemini');
          }

          return jsonDecode(candidate['content']['parts'][0]['text']);
        }
        
        throw Exception('AI ไม่สามารถวิเคราะห์ภาพนี้ได้');
      }
      throw Exception('API Error: ${response.statusCode}');
    } catch (e) {
      // ตัดคำว่า "Exception: " ออกนิดหน่อยเพื่อให้แสดงผลบน Snackbar อ่านง่ายขึ้น
      final errorMsg = e.toString().replaceFirst('Exception: ', '');
      throw Exception(errorMsg);
    }
  }
}