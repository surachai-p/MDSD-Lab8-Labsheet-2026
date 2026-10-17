import '../database/app_database.dart';

abstract class FavoritesRepository {
  // เมธอดสำหรับเพิ่มสินค้าลงรายการโปรด
  Future<void> addFavorite(int itemId, String title, double price, String imageUrl);
  
  // เมธอดสำหรับดึงรายการโปรดทั้งหมด (เรียงจากใหม่ไปเก่า)
  Future<List<FavoriteItem>> getAllFavorites();
  
  // เมธอดสำหรับลบสินค้าออกจากรายการโปรด
  Future<void> removeFavorite(int itemId);
}