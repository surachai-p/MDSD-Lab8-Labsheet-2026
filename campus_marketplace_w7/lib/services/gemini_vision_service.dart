import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/listing_draft.dart';

class GeminiVisionService {
  static const _apiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const _model = 'gemini-2.5-flash';

  Future<ListingDraft> analyzeProductImage({
    required File imageFile,
    required String prompt,
  }) async {
    if (_apiKey.isEmpty) {
      throw Exception(
        'ไม่พบ Gemini API key: รันด้วย --dart-define=GEMINI_API_KEY=your_key',
      );
    }
    final imageBytes = await imageFile.readAsBytes();
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
                  {
                    'inline_data': {
                      'mime_type': _mimeTypeFor(imageFile.path),
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
          }),
        )
        .timeout(const Duration(seconds: 20));

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message =
          (data['error'] as Map<String, dynamic>?)?['message'] ??
          'Gemini API error (${response.statusCode})';
      throw Exception(message);
    }
    final candidates = data['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) {
      throw Exception(
        'AI ไม่สามารถวิเคราะห์ภาพนี้ได้ อาจเข้าข่ายเนื้อหาที่ไม่เหมาะสม ลองใช้ภาพอื่น',
      );
    }
    final candidate = candidates.first as Map<String, dynamic>;
    if (candidate['finishReason'] == 'SAFETY') {
      throw Exception(
        'เนื้อหาที่วิเคราะห์เข้าข่ายไม่ปลอดภัยตามนโยบายของ Gemini กรุณาใช้ภาพอื่น',
      );
    }
    final parts =
        (candidate['content'] as Map<String, dynamic>?)?['parts']
            as List<dynamic>?;
    if (parts == null || parts.isEmpty) {
      throw Exception('AI ไม่สามารถวิเคราะห์ภาพนี้ได้ ลองใช้ภาพอื่น');
    }
    final text = (parts.first as Map<String, dynamic>)['text'] as String?;
    if (text == null || text.trim().isEmpty) {
      throw Exception('AI ส่งผลลัพธ์ว่างกลับมา');
    }
    return ListingDraft.fromJson(jsonDecode(text) as Map<String, dynamic>);
  }

  String _mimeTypeFor(String path) {
    final extension = path.toLowerCase().split('.').last;
    return switch (extension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };
  }
}
