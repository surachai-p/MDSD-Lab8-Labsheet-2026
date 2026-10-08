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
    await _db
        .into(_db.favoriteItems)
        .insert(
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
  Future<List<FavoriteItem>> getAllFavorites() {
    return (_db.select(
      _db.favoriteItems,
    )..orderBy([(favorite) => OrderingTerm.desc(favorite.addedAt)])).get();
  }

  @override
  Future<void> removeFavorite(int itemId) async {
    await (_db.delete(
      _db.favoriteItems,
    )..where((favorite) => favorite.itemId.equals(itemId))).go();
  }
}
