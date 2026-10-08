import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../models/listing_draft.dart';

class GeminiVisionService {
  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const String _model = 'gemini-3.8-flash';
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent';
  static const int _maxAttempts = 3;

  Future<ListingDraft> analyzeProductImage({
    required File imageFile,
    required String prompt,
  }) async {
    final apiKey = _apiKey;
    if (apiKey.isEmpty) {
      throw Exception(
        'ไม่พบ GEMINI_API_KEY กรุณาระบุผ่าน --dart-define=GEMINI_API_KEY=your_key',
      );
    }
    if (apiKey != apiKey.trim() ||
        apiKey.contains('"') ||
        apiKey.contains("'") ||
        RegExp(r'[\x00-\x20\x7F]').hasMatch(apiKey)) {
      throw Exception(
        'รูปแบบ GEMINI_API_KEY ไม่ถูกต้อง: ให้ใส่เฉพาะค่า key โดยไม่ใส่เครื่องหมาย quote หรือช่องว่าง '
        'เช่น flutter run -d emulator-5554 '
        '--dart-define=GEMINI_API_KEY=YOUR_KEY'
        '',
      );
    }

    final imageBytes = await imageFile.readAsBytes();
    final imageBase64 = base64Encode(imageBytes);
    final mimeType = _mimeTypeFor(imageFile.path);
    final url = Uri.parse(_baseUrl);
    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {
              'inlineData': {'mimeType': mimeType, 'data': imageBase64},
            },
            {'text': prompt},
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
          'propertyOrdering': ['title', 'category', 'description'],
        },
        'temperature': 0.2,
        'maxOutputTokens': 2048,
      },
    });

    try {
      final response = await _sendWithRetry(url, body, apiKey);

      if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception(
          'Gemini API ปฏิเสธ API key กรุณาสร้าง key ใหม่จาก Google AI Studio และตรวจสอบว่าเปิดใช้ Gemini API แล้ว',
        );
      }
      if (response.statusCode != 200) {
        if (response.statusCode == 429 ||
            response.statusCode == 500 ||
            response.statusCode == 502 ||
            response.statusCode == 503 ||
            response.statusCode == 504) {
          throw Exception(
            'Gemini API ยังไม่พร้อมให้บริการหลังลองใหม่ $_maxAttempts ครั้ง '
            '(สถานะ ${response.statusCode}) กรุณารอสักครู่แล้วลองอีกครั้ง',
          );
        }
        throw Exception(
          'เกิดข้อผิดพลาดจาก Gemini API (สถานะ ${response.statusCode}): ${response.body}',
        );
      }

      final dynamic decodedResponse;
      try {
        decodedResponse = jsonDecode(response.body);
      } on FormatException catch (error) {
        throw Exception(
          'Gemini API ส่ง response ที่อ่านไม่ได้: ${error.message}',
        );
      }
      if (decodedResponse is! Map<String, dynamic>) {
        throw Exception('Gemini API ส่ง response ในรูปแบบที่ไม่รองรับ');
      }
      final responseJson = decodedResponse;
      final candidates = responseJson['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        final blockReason = responseJson['promptFeedback']?['blockReason'];
        throw Exception(_safetyRefusalMessage(blockReason?.toString()));
      }

      final candidate = candidates.first as Map<String, dynamic>;
      final finishReason = candidate['finishReason'] as String?;
      if (finishReason == 'SAFETY' ||
          finishReason == 'PROHIBITED_CONTENT' ||
          finishReason == 'BLOCKLIST') {
        throw Exception(_safetyRefusalMessage(finishReason));
      }
      if (finishReason == 'MAX_TOKENS') {
        throw Exception(
          'คำตอบจาก Gemini ยาวเกินไป กรุณาลองวิเคราะห์รูปภาพอีกครั้ง',
        );
      }

      final parts = candidate['content']?['parts'] as List?;
      final responseText = parts
          ?.map((part) => part['text'])
          .whereType<String>()
          .join('\n')
          .trim();
      if (responseText == null || responseText.isEmpty) {
        throw Exception(
          'Gemini ไม่ได้ส่งข้อความกลับมา กรุณาลองวิเคราะห์รูปภาพอีกครั้ง',
        );
      }

      try {
        return _parseListingDraft(responseText);
      } on FormatException catch (error) {
        throw Exception(
          'คำตอบจาก Gemini แปลงเป็นข้อมูลประกาศไม่ได้ (${error.message}) '
          'ข้อความที่ได้รับ: "${_excerpt(responseText)}"',
        );
      }
    } on TimeoutException {
      throw Exception('การเชื่อมต่อ Gemini API หมดเวลา กรุณาลองใหม่อีกครั้ง');
    } on http.ClientException {
      throw Exception(
        'ไม่สามารถเชื่อมต่ออินเทอร์เน็ตได้ กรุณาตรวจสอบการเชื่อมต่อ',
      );
    } on FormatException {
      throw Exception(
        'รูปแบบ GEMINI_API_KEY หรือ HTTP header ไม่ถูกต้อง '
        'ตรวจสอบคำสั่ง --dart-define โดยอย่าใส่ quote ไว้ในค่าของ key',
      );
    }
  }

  ListingDraft _parseListingDraft(String responseText) {
    var jsonText = responseText.trim();
    final fencedJson = RegExp(
      r'^```(?:json)?\s*([\s\S]*?)\s*```$',
      caseSensitive: false,
    ).firstMatch(jsonText);
    if (fencedJson != null) {
      jsonText = fencedJson.group(1)!.trim();
    }

    final jsonObject = _extractJsonObject(jsonText);
    if (jsonObject == null) {
      throw const FormatException('No JSON object found');
    }

    final decoded = jsonDecode(jsonObject);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('JSON response is not an object');
    }

    final title = decoded['title'];
    final category = decoded['category'];
    final description = decoded['description'];
    if (title is! String ||
        category is! String ||
        description is! String ||
        title.trim().isEmpty ||
        category.trim().isEmpty ||
        description.trim().isEmpty) {
      throw const FormatException('JSON response is missing required fields');
    }

    return ListingDraft(
      title: title.trim(),
      category: category.trim(),
      description: description.trim(),
    );
  }

  String? _extractJsonObject(String text) {
    final start = text.indexOf('{');
    if (start < 0) return null;

    var depth = 0;
    var isInsideString = false;
    var isEscaped = false;
    for (var index = start; index < text.length; index++) {
      final character = text[index];
      if (isInsideString) {
        if (isEscaped) {
          isEscaped = false;
        } else if (character == r'\') {
          isEscaped = true;
        } else if (character == '"') {
          isInsideString = false;
        }
        continue;
      }

      if (character == '"') {
        isInsideString = true;
      } else if (character == '{') {
        depth++;
      } else if (character == '}') {
        depth--;
        if (depth == 0) {
          return text.substring(start, index + 1);
        }
      }
    }
    return null;
  }

  String _excerpt(String text) {
    final normalized = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    const maxLength = 180;
    if (normalized.length <= maxLength) return normalized;
    return '${normalized.substring(0, maxLength)}...';
  }

  Future<http.Response> _sendWithRetry(
    Uri url,
    String body,
    String apiKey,
  ) async {
    const retryableStatuses = {429, 500, 502, 503, 504};
    final random = Random();

    for (var attempt = 1; attempt <= _maxAttempts; attempt++) {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'x-goog-api-key': apiKey,
            },
            body: body,
          )
          .timeout(const Duration(seconds: 60));

      if (!retryableStatuses.contains(response.statusCode) ||
          attempt == _maxAttempts) {
        return response;
      }

      final delay = Duration(
        milliseconds: (1000 * (1 << (attempt - 1))) + random.nextInt(500),
      );
      await Future<void>.delayed(delay);
    }

    throw StateError('Gemini retry loop exited unexpectedly');
  }

  String _mimeTypeFor(String path) {
    final extension = path.split('.').last.toLowerCase();
    return switch (extension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'heic' || 'heif' => 'image/heic',
      _ => 'image/jpeg',
    };
  }

  String _safetyRefusalMessage(String? reason) {
    if (reason == null) {
      return 'AI ไม่สามารถวิเคราะห์ภาพนี้ได้ อาจเข้าข่ายเนื้อหาที่ไม่เหมาะสม ลองใช้ภาพอื่น';
    }
    return 'เนื้อหาที่วิเคราะห์เข้าข่ายไม่ปลอดภัยตามนโยบายของ Gemini กรุณาใช้ภาพอื่น';
  }
}
