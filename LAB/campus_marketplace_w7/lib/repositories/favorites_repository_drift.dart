import 'package:drift/drift.dart';
import '../database/app_database.dart';
import 'favorites_repository.dart';

class FavoritesRepositoryDrift implements FavoritesRepository {
  final AppDatabase _db;

  FavoritesRepositoryDrift(this._db);

  @override
  Future<void> addFavorite(
    int itemId,
    String title,
    double price,
    String imageUrl,
  ) async {
    await _db.into(_db.favoriteItems).insert(
          FavoriteItemsCompanion.insert(
            itemId: itemId,
            title: title,
            price: price,
            imageUrl: imageUrl,
          ),
          // สำคัญมาก: ป้องกันแอปแครช (UNIQUE constraint failed) หากผู้ใช้กดหัวใจซ้ำที่สินค้าเดิม
          mode: InsertMode.insertOrIgnore,
        );
  }

  @override
  Future<List<FavoriteItem>> getAllFavorites() {
    // ดึงข้อมูลและเรียงลำดับจากวันที่เพิ่ม (addedAt) จากใหม่ไปเก่า (desc)
    return (_db.select(_db.favoriteItems)
          ..orderBy([
            (t) => OrderingTerm(expression: t.addedAt, mode: OrderingMode.desc),
          ]))
        .get();
  }

  @override
  Future<void> removeFavorite(int itemId) async {
    // ลบข้อมูลที่ itemId ตรงกับที่ระบุ
    await (_db.delete(_db.favoriteItems)
          ..where((t) => t.itemId.equals(itemId)))
        .go();
  }
}