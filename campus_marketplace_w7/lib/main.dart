import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'database/app_database.dart';
import 'models/cart_model.dart';
import 'repositories/favorites_repository.dart';
import 'repositories/favorites_repository_drift.dart';
import 'repositories/item_repository.dart';
import 'repositories/item_repository_api.dart';
import 'repositories/listing_draft_repository.dart';
import 'repositories/listing_draft_repository_drift.dart';
import 'screens/main_scaffold.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final db = AppDatabase();

  runApp(
    ChangeNotifierProvider(
      create: (_) => CartModel(),
      child: MyApp(db: db),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    this.db,
    this.itemRepository,
    this.favoritesRepository,
    this.draftRepository,
  });

  final AppDatabase? db;
  final ItemRepository? itemRepository;
  final FavoritesRepository? favoritesRepository;
  final ListingDraftRepository? draftRepository;

  @override
  Widget build(BuildContext context) {
    final database = db ?? AppDatabase();
    return MaterialApp(
      title: 'Campus Marketplace',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: MainScaffold(
        itemRepository: itemRepository ?? ItemRepositoryApi(),
        favoritesRepository:
            favoritesRepository ?? FavoritesRepositoryDrift(database),
        draftRepository: draftRepository ?? ListingDraftRepositoryDrift(database),
      ),
    );
  }
}
