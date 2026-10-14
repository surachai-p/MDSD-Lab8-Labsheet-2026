import 'package:drift/drift.dart';
import '../database/app_database.dart';
import 'favorites_repository.dart';

class FavoritesRepositoryDrift implements FavoritesRepository {
  final AppDatabase _db;

  FavoritesRepositoryDrift(this._db);

  @override
  Future<void> addFavorite(int itemId, String title, double price, String imageUrl) async {
    // ใช้ InsertMode.insertOrIgnore เพื่อป้องกัน Error หากผู้ใช้กดถูกใจสินค้าชิ้นเดิมซ้ำ
    await _db.into(_db.favoriteItems).insert(
      FavoriteItemsCompanion.insert(
        itemId: itemId,
        title: title,
        price: price,
        imageUrl: imageUrl,
      ),
      mode: InsertMode.insertOrIgnore,
    );
  }

  @override
  Future<List<FavoriteItem>> getAllFavorites() async {
    // ดึงข้อมูลรายการโปรดทั้งหมด และเรียงลำดับจากใหม่ไปเก่าตาม addedAt
    return await (_db.select(_db.favoriteItems)
          ..orderBy([
            (t) => OrderingTerm(expression: t.addedAt, mode: OrderingMode.desc)
          ]))
        .get();
  }

  @override
  Future<void> removeFavorite(int itemId) async {
    // ลบรายการโปรดโดยอ้างอิงจาก itemId
    await (_db.delete(_db.favoriteItems)..where((t) => t.itemId.equals(itemId))).go();
  }
}
