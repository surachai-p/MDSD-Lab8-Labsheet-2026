import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class GeminiVisionService {
  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const String apiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash-lite:generateContent';

  static const List<String> _models = [
    'gemini-3.5-flash-lite',
    'gemini-3.8-flash',
  ];

  /// วิเคราะห์รูปภาพสินค้าด้วย Gemini Vision
  /// คืนค่า Map ที่มีคีย์: title, description, price, category
  Future<Map<String, dynamic>> analyzeProductImage(File imageFile, String prompt) async {
    // ขั้นที่ 1: อ่านไฟล์ภาพเป็น bytes แล้วเข้ารหัส Base64
    final imageBytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(imageBytes);

    // ขั้นที่ 2: ตรวจหา MIME type จากนามสกุลไฟล์
    final extension = imageFile.path.split('.').last.toLowerCase();
    final mimeType = switch (extension) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };

    String lastError = '';

    // วนลูปทดลองโมเดล โดยเริ่มจากโมเดลที่เร็วและเสถียรที่สุดก่อน
    for (final model in _models) {
      final uri = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$_apiKey');

      try {
        final response = await http
            .post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'contents': [
                  {
                    'parts': [
                      // Part 1: ข้อมูลรูปภาพแบบ inline (Base64)
                      {
                        'inline_data': {
                          'mime_type': mimeType,
                          'data': base64Image,
                        }
                      },
                      // Part 2: Prompt ที่ส่งพร้อมกับรูปภาพ
                      {
                        'text': prompt
                      },
                    ]
                  }
                ],
                // ขั้นที่ 3: ใช้ responseSchema บังคับให้ Gemini ตอบกลับเป็น JSON ตามโครงสร้างที่กำหนด
                'generationConfig': {
                  'responseMimeType': 'application/json',
                  'responseSchema': {
                    'type': 'OBJECT',
                    'properties': {
                      'title': {
                        'type': 'STRING',
                        'description': 'ชื่อสินค้าภาษาไทย สั้นกระชับ ไม่เกิน 60 ตัวอักษร',
                      },
                      'description': {
                        'type': 'STRING',
                        'description': 'คำอธิบายสินค้าภาษาไทย รายละเอียดเพิ่มเติม 1-2 ประโยค',
                      },
                      'price': {
                        'type': 'NUMBER',
                        'description': 'ราคาสินค้าที่แนะนำเป็นตัวเลข หน่วยบาท',
                      },
                      'category': {
                        'type': 'STRING',
                        'description': 'หมวดหมู่สินค้า เช่น เสื้อผ้า, อิเล็กทรอนิกส์, หนังสือ, อุปกรณ์การเรียน, อื่นๆ',
                      },
                    },
                    'required': ['title', 'description', 'price', 'category'],
                  },
                },
              }),
            )
            .timeout(const Duration(seconds: 30));

        // ขั้นที่ 4: ตรวจสอบ Status Code
        if (response.statusCode == 200) {
          // jsonDecode ชั้นที่ 1: แกะ Gemini API response wrapper
          final decodedResponse = jsonDecode(response.body);
          final candidates = decodedResponse['candidates'] as List<dynamic>?;

          if (candidates != null && candidates.isNotEmpty) {
            final content = candidates.first['content'];
            if (content != null && content['parts'] != null) {
              final parts = content['parts'] as List<dynamic>;
              if (parts.isNotEmpty) {
                final rawText = parts.first['text'] as String;

                // jsonDecode ชั้นที่ 2: แกะ JSON ที่ Gemini สร้างขึ้นตาม responseSchema
                final productData = jsonDecode(rawText) as Map<String, dynamic>;
                return productData;
              }
            }
          }
          throw Exception('API ตอบกลับสำเร็จแต่ไม่พบข้อมูล candidates');
        } else if (response.statusCode == 503) {
          lastError = 'เซิร์ฟเวอร์ AI มีผู้ใช้งานหนาแน่นชั่วคราว (503)';
          continue; // สลับไปลองโมเดลสำรอง
        } else if (response.statusCode == 429) {
          throw Exception('โควตาการใช้งาน API ชั่วคราวเต็ม (429) กรุณารอสักครู่');
        } else {
          lastError =
              'API ตอบกลับด้วย Status Code: ${response.statusCode} - ${response.body}';
        }
      } on TimeoutException {
        lastError = 'การเชื่อมต่อหมดเวลา (30 วินาที) กรุณาลองใหม่อีกครั้ง';
        continue; // สลับไปลองโมเดลสำรอง
      } catch (e) {
        lastError = 'เกิดข้อผิดพลาด: $e';
      }
    }

    throw Exception(lastError.isNotEmpty ? lastError : 'การเชื่อมต่อหมดเวลา (30 วินาที) กรุณาลองใหม่อีกครั้ง');
  }
}
