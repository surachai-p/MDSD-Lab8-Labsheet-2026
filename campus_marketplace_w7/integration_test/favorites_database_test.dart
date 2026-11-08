import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:campus_marketplace_w7/database/app_database.dart';
import 'package:campus_marketplace_w7/repositories/favorites_repository_drift.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Favorites persist in SQLite and ignore duplicate item ids', (
    tester,
  ) async {
    const firstId = 910001;
    const secondId = 910002;

    final initialDb = AppDatabase();
    final initialRepository = FavoritesRepositoryDrift(initialDb);

    await initialRepository.removeFavorite(firstId);
    await initialRepository.removeFavorite(secondId);
    await initialRepository.addFavorite(
      firstId,
      'Persistence sample one',
      12.5,
      'https://example.com/one.png',
    );
    await initialRepository.addFavorite(
      secondId,
      'Persistence sample two',
      25,
      'https://example.com/two.png',
    );
    await initialRepository.addFavorite(
      firstId,
      'Duplicate sample',
      99,
      'https://example.com/duplicate.png',
    );

    final inserted = await initialRepository.getAllFavorites();
    expect(inserted.where((item) => item.itemId == firstId), hasLength(1));
    expect(inserted.where((item) => item.itemId == secondId), hasLength(1));
    await initialDb.close();

    final reopenedDb = AppDatabase();
    final reopenedRepository = FavoritesRepositoryDrift(reopenedDb);
    var persisted = await reopenedRepository.getAllFavorites();
    expect(
      persisted.map((item) => item.itemId),
      containsAll([firstId, secondId]),
    );

    await reopenedRepository.removeFavorite(firstId);
    await reopenedDb.close();

    final verifiedDb = AppDatabase();
    final verifiedRepository = FavoritesRepositoryDrift(verifiedDb);
    persisted = await verifiedRepository.getAllFavorites();
    expect(persisted.map((item) => item.itemId), isNot(contains(firstId)));
    expect(persisted.map((item) => item.itemId), contains(secondId));
    await verifiedDb.close();
  });
}
