import 'package:drift/drift.dart';

import '../database/app_database.dart';
import 'favorites_repository.dart';

class FavoritesRepositoryDrift implements FavoritesRepository {
  final AppDatabase _db;

  FavoritesRepositoryDrift(this._db);

  @override
  Future<void> addFavorite(int itemId, String title, double price, String imageUrl) async {
    await _db.into(_db.favoriteItems).insert(
          FavoriteItemsCompanion.insert(
            itemId: itemId,
            title: title,
            price: price,
            imageUrl: imageUrl,
          ),
          // itemId เป็น .unique() ถ้ากดซ้ำให้ข้ามไปเฉย ๆ แทนที่จะ Error
          mode: InsertMode.insertOrIgnore,
        );
  }

  @override
  Future<List<FavoriteItem>> getAllFavorites() {
    // currentDateAndTime ละเอียดระดับวินาที จึงใช้ id ตัดสินเมื่อกดถูกใจในวินาทีเดียวกัน
    return (_db.select(_db.favoriteItems)
          ..orderBy([
            (t) => OrderingTerm.desc(t.addedAt),
            (t) => OrderingTerm.desc(t.id),
          ]))
        .get();
  }

  @override
  Future<void> removeFavorite(int itemId) async {
    await (_db.delete(_db.favoriteItems)..where((t) => t.itemId.equals(itemId))).go();
  }
}
