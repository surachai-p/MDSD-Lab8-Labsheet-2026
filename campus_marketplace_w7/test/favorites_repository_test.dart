import 'dart:io';

import 'package:campus_marketplace_w7/database/app_database.dart';
import 'package:campus_marketplace_w7/repositories/favorites_repository_drift.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late AppDatabase db;
  late FavoritesRepositoryDrift repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = FavoritesRepositoryDrift(db);
  });

  tearDown(() => db.close());

  test('adding the same item twice keeps a single row without error', () async {
    await repository.addFavorite(1, 'A', 10.5, 'a.png');
    await repository.addFavorite(1, 'A', 10.5, 'a.png');

    final favorites = await repository.getAllFavorites();
    expect(favorites, hasLength(1));
    expect(favorites.single.price, 10.5);
  });

  test('sorts by addedAt, newest first', () async {
    Future<void> insertAt(int itemId, DateTime addedAt) {
      return db
          .into(db.favoriteItems)
          .insert(
            FavoriteItemsCompanion.insert(
              itemId: itemId,
              title: 'item $itemId',
              price: 1,
              imageUrl: '',
              addedAt: Value(addedAt),
            ),
          );
    }

    await insertAt(1, DateTime(2026, 1, 2));
    await insertAt(2, DateTime(2026, 1, 3));
    await insertAt(3, DateTime(2026, 1, 1));

    final favorites = await repository.getAllFavorites();
    expect(favorites.map((f) => f.itemId), [2, 1, 3]);
  });

  test('items added within the same second are newest first', () async {
    await repository.addFavorite(1, 'A', 1, '');
    await repository.addFavorite(2, 'B', 1, '');
    await repository.addFavorite(3, 'C', 1, '');

    final favorites = await repository.getAllFavorites();
    expect(favorites.map((f) => f.itemId), [3, 2, 1]);
  });

  test('removeFavorite deletes by itemId, not by row id', () async {
    await repository.addFavorite(100, 'A', 1, '');
    await repository.addFavorite(200, 'B', 1, '');

    await repository.removeFavorite(100);

    final favorites = await repository.getAllFavorites();
    expect(favorites.map((f) => f.itemId), [200]);
  });

  test('adds and removes survive closing and reopening the file', () async {
    final directory = await Directory.systemTemp.createTemp('favorites_test');
    addTearDown(() => directory.delete(recursive: true));
    final file = File(p.join(directory.path, 'test.sqlite'));

    var fileDb = AppDatabase.forTesting(NativeDatabase(file));
    var fileRepository = FavoritesRepositoryDrift(fileDb);
    await fileRepository.addFavorite(1, 'A', 1, '');
    await fileRepository.addFavorite(2, 'B', 1, '');
    await fileDb.close();

    fileDb = AppDatabase.forTesting(NativeDatabase(file));
    fileRepository = FavoritesRepositoryDrift(fileDb);
    expect(await fileRepository.getAllFavorites(), hasLength(2));
    await fileRepository.removeFavorite(1);
    await fileDb.close();

    fileDb = AppDatabase.forTesting(NativeDatabase(file));
    fileRepository = FavoritesRepositoryDrift(fileDb);
    final favorites = await fileRepository.getAllFavorites();
    await fileDb.close();
    expect(favorites.map((f) => f.itemId), [2]);
  });
}
