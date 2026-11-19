import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/item.dart';
import 'item_repository.dart';

class ItemRepositoryApi implements ItemRepository {
  static const _baseUrl = 'https://fakestoreapi.com/products';

  @override
  Future<List<Item>> getItems() async {
    try {
      final response = await http
          .get(Uri.parse(_baseUrl))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        throw Exception(
          'ไม่สามารถโหลดรายการสินค้าได้ (สถานะ ${response.statusCode})',
        );
      }
      final data = jsonDecode(response.body) as List<dynamic>;
      return data
          .map((item) => Item.fromJson(item as Map<String, dynamic>))
          .toList();
    } on TimeoutException {
      throw Exception('การเชื่อมต่อหมดเวลา กรุณาลองใหม่อีกครั้ง');
    } on http.ClientException {
      throw Exception(
        'ไม่สามารถเชื่อมต่ออินเทอร์เน็ตได้ กรุณาตรวจสอบการเชื่อมต่อ',
      );
    } on FormatException {
      throw Exception('ข้อมูลที่ได้รับจากเซิร์ฟเวอร์ไม่ถูกต้อง');
    }
  }
}
