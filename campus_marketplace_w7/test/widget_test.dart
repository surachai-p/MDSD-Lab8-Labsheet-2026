// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import 'package:campus_marketplace_w7/database/app_database.dart';
import 'package:campus_marketplace_w7/models/cart_model.dart';
import 'package:campus_marketplace_w7/models/item.dart';
import 'package:campus_marketplace_w7/models/listing_draft.dart';
import 'package:campus_marketplace_w7/repositories/favorites_repository.dart';
import 'package:campus_marketplace_w7/repositories/item_repository.dart';
import 'package:campus_marketplace_w7/repositories/listing_draft_repository.dart';
import 'package:campus_marketplace_w7/screens/home_page.dart';
import 'package:campus_marketplace_w7/screens/main_scaffold.dart';

class _FakeItemRepository implements ItemRepository {
  @override
  Future<List<Item>> getItems() => Completer<List<Item>>().future;
}

class _OneItemRepository implements ItemRepository {
  @override
  Future<List<Item>> getItems() async => const [
    Item(
      id: 1,
      title: 'สินค้าทดสอบ',
      price: 99.5,
      description: 'รายละเอียด',
      category: 'อื่นๆ',
      imageUrl: 'https://example.com/a.png',
    ),
  ];
}

class _FakeFavoritesRepository implements FavoritesRepository {
  final _rows = <FavoriteItem>[];

  @override
  Future<void> addFavorite(
    int itemId,
    String title,
    double price,
    String imageUrl,
  ) async {
    if (_rows.any((row) => row.itemId == itemId)) return;
    _rows.add(
      FavoriteItem(
        id: _rows.length + 1,
        itemId: itemId,
        title: title,
        price: price,
        imageUrl: imageUrl,
        addedAt: DateTime(2026),
      ),
    );
  }

  @override
  Future<List<FavoriteItem>> getAllFavorites() async => List.of(_rows);

  @override
  Future<void> removeFavorite(int itemId) async {
    _rows.removeWhere((row) => row.itemId == itemId);
  }
}

class _FakeDraftRepository implements ListingDraftRepository {
  @override
  Future<void> saveDraft(ListingDraft draft, String imagePath) async {}

  @override
  Future<List<ListingDraftRow>> getAllDrafts() async => [];

  @override
  Future<void> deleteDraft(int id) async {}
}

void main() {
  testWidgets('shows app title and loading state', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (context) => CartModel(),
        child: MaterialApp(
          title: 'Campus Marketplace',
          home: HomePage(
            repository: _FakeItemRepository(),
            favoritesRepository: _FakeFavoritesRepository(),
          ),
        ),
      ),
    );

    expect(find.text('Campus Marketplace'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('favorite added on Home appears in the Favorites tab', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (context) => CartModel(),
        child: MaterialApp(
          home: MainScaffold(
            itemRepository: _OneItemRepository(),
            favoritesRepository: _FakeFavoritesRepository(),
            draftRepository: _FakeDraftRepository(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.favorite_border));
    await tester.pump();
    await tester.tap(find.text('รายการโปรด'));
    await tester.pump();
    await tester.pump();

    // แถวสินค้าอยู่ทั้ง Tab หน้าหลักและ Tab รายการโปรด จึงตรวจจากปุ่มลบที่มีเฉพาะ Tab รายการโปรด
    expect(find.byIcon(Icons.delete), findsOneWidget);

    await tester.tap(find.byIcon(Icons.delete));
    await tester.pump();
    await tester.pump();

    expect(find.byIcon(Icons.delete), findsNothing);
    expect(
      find.text('ยังไม่มีรายการโปรด ลองกดหัวใจที่หน้าหลักดูสิ'),
      findsOneWidget,
    );
  });
}
