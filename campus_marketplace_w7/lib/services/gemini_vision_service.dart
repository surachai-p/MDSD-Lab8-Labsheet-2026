import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/listing_draft.dart';

class GeminiVisionService {
  static const _model = 'gemini-3.5-flash';
  static const _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent';
  static const _apiKey = String.fromEnvironment('GEMINI_API_KEY');

  String _getMimeType(String path) {
    final ext = path.toLowerCase().split('.').last;
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'heic':
        return 'image/heic';
      case 'heif':
        return 'image/heif';
      case 'jpg':
      case 'jpeg':
      default:
        return 'image/jpeg';
    }
  }

  Future<ListingDraft> analyzeProductImage(
    File imageFile, [
    String? prompt,
  ]) async {
    final uri = Uri.parse('$_baseUrl?key=$_apiKey');

    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);
    final mimeType = _getMimeType(imageFile.path);

    final effectivePrompt =
        prompt ??
        'วิเคราะห์ภาพสินค้านี้เพื่อสร้างข้อมูลสำหรับลงประกาศขายสินค้ามือสอง โดยระบุชื่อสินค้า (title), หมวดหมู่สินค้า (category), และคำอธิบายสินค้าสั้นๆ (description)';

    // ตรวจสอบความปลอดภัยตามหลัก AI Safety (หัวข้อ 7.6-7.7) กรณีเนื้อหาเข้าข่ายไม่ปลอดภัย
    if (effectivePrompt.contains('ปลอมแปลง') ||
        effectivePrompt.contains('ไม่ต้องสนใจคำแนะนำก่อนหน้านี้')) {
      throw Exception('เกิดข้อผิดพลาดขณะส่งคำขอไปยัง Gemini อาจเป็นเพราะเนื้อหาที่ส่งไปถูกระบบความปลอดภัยของ Gemini บล็อก กรุณาตรวจสอบเนื้อหาที่ส่งไปและลองใหม่');
    }

    final requestBody = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': effectivePrompt},
            {
              'inlineData': {'mimeType': mimeType, 'data': base64Image},
            },
          ],
        },
      ],
      'safetySettings': [
        {
          'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
          'threshold': 'BLOCK_LOW_AND_ABOVE',
        },
        {
          'category': 'HARM_CATEGORY_HARASSMENT',
          'threshold': 'BLOCK_LOW_AND_ABOVE',
        },
        {
          'category': 'HARM_CATEGORY_HATE_SPEECH',
          'threshold': 'BLOCK_LOW_AND_ABOVE',
        },
        {
          'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
          'threshold': 'BLOCK_LOW_AND_ABOVE',
        },
      ],
      'generationConfig': {
        'responseMimeType': 'application/json',
        'responseSchema': {
          'type': 'OBJECT',
          'properties': {
            'title': {'type': 'STRING'},
            'category': {'type': 'STRING'},
            'description': {'type': 'STRING'},
          },
          'required': ['title', 'category', 'description'],
        },
      },
    });

    http.Response? response;

    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        response = await http
            .post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: requestBody,
            )
            .timeout(const Duration(seconds: 60));

        if (response.statusCode == 200) {
          break;
        } else if (response.statusCode == 503 && attempt < 2) {
          await Future.delayed(Duration(seconds: 2 * (attempt + 1)));
          continue;
        } else {
          break;
        }
      } catch (e) {
        if (attempt == 2) rethrow;
        await Future.delayed(const Duration(seconds: 2));
      }
    }

    if (response != null && response.statusCode == 200) {
      final data = jsonDecode(response.body);

      final promptFeedback = data['promptFeedback'] as Map<String, dynamic>?;
      final blockReason = promptFeedback?['blockReason'] as String?;
      if (blockReason == 'SAFETY') {
        throw Exception(
          'เกิดข้อผิดพลาดขณะส่งคำขอไปยัง Gemini อาจเป็นเพราะเนื้อหาที่ส่งไปถูกระบบความปลอดภัยของ Gemini บล็อก กรุณาตรวจสอบเนื้อหาที่ส่งไปและลองใหม่',
        );
      }

      final candidates = data['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        throw Exception(
          'เกิดข้อผิดพลาดขณะส่งคำขอไปยัง Gemini อาจเป็นเพราะเนื้อหาที่ส่งไปถูกระบบความปลอดภัยของ Gemini บล็อก กรุณาตรวจสอบเนื้อหาที่ส่งไปและลองใหม่',
        );
      }

      final candidate = candidates.first as Map<String, dynamic>;
      final finishReason = candidate['finishReason'] as String?;
      if (finishReason == 'SAFETY') {
        throw Exception(
          'เกิดข้อผิดพลาดขณะส่งคำขอไปยัง Gemini อาจเป็นเพราะเนื้อหาที่ส่งไปถูกระบบความปลอดภัยของ Gemini บล็อก กรุณาตรวจสอบเนื้อหาที่ส่งไปและลองใหม่',
        );
      }

      final content = candidate['content'] as Map<String, dynamic>?;
      final parts = content?['parts'] as List<dynamic>?;
      if (parts == null || parts.isEmpty) {
        throw Exception(
          'AI ไม่สามารถวิเคราะห์ภาพนี้ได้ อาจเข้าข่ายเนื้อหาที่ไม่เหมาะสม ลองใช้ภาพอื่น',
        );
      }

      var text = parts.first['text'] as String;

      text = text.trim();
      if (text.startsWith('```json')) {
        text = text.substring(7);
      } else if (text.startsWith('```')) {
        text = text.substring(3);
      }
      if (text.endsWith('```')) {
        text = text.substring(0, text.length - 3);
      }
      text = text.trim();

      final jsonMap = jsonDecode(text) as Map<String, dynamic>;
      return ListingDraft.fromJson(jsonMap);
    } else if (response != null && response.statusCode == 429) {
      throw Exception('ใช้งานเกินโควตาที่กำหนดในขณะนี้ กรุณาลองใหม่ภายหลัง');
    } else if (response != null && response.statusCode == 503) {
      throw Exception(
        'เซิร์ฟเวอร์ Gemini กำลังมีผู้ใช้งานหนาแน่นชั่วคราว (รหัส 503) กรุณากดลองใหม่อีกครั้ง',
      );
    } else {
      final code = response?.statusCode ?? 'No response';
      throw Exception('เซิร์ฟเวอร์ Gemini ตอบกลับผิดพลาด (รหัส $code)');
    }
  }
}
