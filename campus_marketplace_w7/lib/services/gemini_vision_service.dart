import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/listing_draft.dart';

class GeminiVisionService {
  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const String _model = 'gemini-3.8-flash';
  static const Duration _requestTimeout = Duration(seconds: 120);
  static const int _maxAttempts = 3;
  static const Set<int> _retryableStatusCodes = {503, 502, 500, 429};

  static const String _prompt = '''
วิเคราะห์ภาพสินค้ามือสองสำหรับประกาศขายในตลาดนักศึกษา
สร้างชื่อสินค้า หมวดหมู่ และคำอธิบายสินค้าเป็นภาษาไทย
หากข้อมูลบางอย่างมองไม่เห็น อย่าคาดเดารายละเอียดที่ไม่ปรากฏในภาพ
''';

  Future<ListingDraft> analyzeProductImage(File imageFile) async {
    if (_apiKey.isEmpty) {
      throw Exception('ไม่พบ GEMINI_API_KEY กรุณาตรวจสอบคำสั่ง flutter run');
    }

    final imageBytes = await imageFile.readAsBytes();
    if (imageBytes.isEmpty) throw Exception('ไฟล์ภาพว่างเปล่า กรุณาเลือกรูปใหม่');
    final mimeType = _mimeTypeFor(imageBytes, imageFile.path);
    if (mimeType == null) {
      throw Exception('ไม่รองรับชนิดไฟล์ภาพนี้ กรุณาเลือกรูป JPEG, PNG หรือ WebP');
    }

    // The picker resizes images to at most 2048 px and JPEG quality 88.
    // Guard against unexpectedly large files from other callers as well.
    if (imageBytes.length > 12 * 1024 * 1024) {
      throw Exception('ไฟล์ภาพมีขนาดใหญ่เกินไป กรุณาเลือกรูปที่มีขนาดไม่เกิน 12 MB');
    }

    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/'
      'models/$_model:generateContent',
    );
    final requestBody = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': _prompt},
            {
              'inline_data': {
                'mime_type': mimeType,
                'data': base64Encode(imageBytes),
              },
            },
          ],
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

    for (var attempt = 1; attempt <= _maxAttempts; attempt++) {
      try {
        final response = await http
            .post(
              uri,
              headers: {
                'Content-Type': 'application/json',
                'x-goog-api-key': _apiKey,
              },
              body: requestBody,
            )
            .timeout(_requestTimeout);

        debugPrint('Gemini HTTP status: ${response.statusCode} (attempt $attempt/$_maxAttempts)');
        if (response.statusCode == 200) return _parseResponse(response.body);

        // Log the server response for diagnosis. Never log headers or request body.
        debugPrint('Gemini error response: ${response.body}');
        if (_retryableStatusCodes.contains(response.statusCode) &&
            attempt < _maxAttempts) {
          await Future<void>.delayed(Duration(seconds: 1 << (attempt - 1)));
          continue;
        }
        throw Exception(_httpErrorMessage(response.statusCode));
      } on TimeoutException {
        debugPrint('Gemini request timed out (attempt $attempt/$_maxAttempts)');
        throw Exception('รอการตอบกลับจาก Gemini นานเกินไป กรุณาตรวจสอบอินเทอร์เน็ตแล้วลองใหม่');
      } on SocketException catch (error) {
        debugPrint('Gemini socket error: $error');
        throw Exception('เชื่อมต่ออินเทอร์เน็ตไม่ได้ กรุณาตรวจสอบเครือข่ายแล้วลองใหม่');
      } on http.ClientException catch (error) {
        debugPrint('Gemini HTTP client error: $error');
        throw Exception('ส่งคำขอไปยัง Gemini ไม่สำเร็จ กรุณาลองใหม่');
      } on FormatException catch (error) {
        debugPrint('Gemini response format error: $error');
        throw Exception('Gemini ส่งข้อมูลกลับมาในรูปแบบที่อ่านไม่ได้ กรุณาลองใหม่');
      }
    }
    throw Exception('Gemini ยังไม่พร้อมให้บริการ กรุณาลองใหม่ภายหลัง');
  }

  ListingDraft _parseResponse(String body) {
    final apiJson = jsonDecode(body) as Map<String, dynamic>;
    final candidates = apiJson['candidates'];
    if (candidates is! List || candidates.isEmpty) {
      throw Exception('Gemini ไม่ส่งผลการวิเคราะห์กลับมา กรุณาลองใหม่');
    }

    for (final item in candidates) {
      if (item is! Map<String, dynamic>) continue;
      final content = item['content'];
      if (content is! Map<String, dynamic>) continue;
      final parts = content['parts'];
      if (parts is! List) continue;
      for (final part in parts) {
        if (part is! Map<String, dynamic> || part['text'] is! String) continue;
        final result = jsonDecode(part['text'] as String);
        if (result is Map<String, dynamic> &&
            result['title'] is String &&
            result['category'] is String &&
            result['description'] is String) {
          return ListingDraft.fromJson(result);
        }
      }
    }
    throw Exception('Gemini ส่งผลการวิเคราะห์ไม่ครบถ้วน กรุณาลองใหม่');
  }

  String? _mimeTypeFor(List<int> bytes, String path) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xff && bytes[1] == 0xd8 && bytes[2] == 0xff) {
      return 'image/jpeg';
    }
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4e &&
        bytes[3] == 0x47 && bytes[4] == 0x0d && bytes[5] == 0x0a &&
        bytes[6] == 0x1a && bytes[7] == 0x0a) {
      return 'image/png';
    }
    if (bytes.length >= 12 &&
        String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF' &&
        String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP') {
      return 'image/webp';
    }
    final extension = path.toLowerCase().split('.').last;
    return switch (extension) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => null,
    };
  }

  String _httpErrorMessage(int statusCode) => switch (statusCode) {
    400 => 'ข้อมูลภาพหรือคำขอไม่ถูกต้อง กรุณาเลือกรูปอื่น',
    401 || 403 => 'ไม่สามารถยืนยันสิทธิ์ Gemini ได้ กรุณาตรวจสอบ API Key',
    404 => 'ไม่พบโมเดล Gemini ที่ร้องขอ กรุณาตรวจสอบการตั้งค่า',
    429 => 'มีคำขอใช้งาน Gemini มากเกินไป กรุณารอสักครู่แล้วลองใหม่',
    500 || 502 || 503 => 'Gemini ขัดข้องชั่วคราว กรุณาลองใหม่ภายหลัง',
    _ => 'Gemini ตอบกลับข้อผิดพลาด (รหัส $statusCode) กรุณาลองใหม่',
  };
}
