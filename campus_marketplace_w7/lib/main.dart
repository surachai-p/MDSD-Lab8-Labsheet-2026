import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// นำเข้าฐานข้อมูลและ Repository ที่เกี่ยวข้อง
import 'database/app_database.dart';
import 'repositories/favorites_repository_drift.dart';
import 'repositories/listing_draft_repository_drift.dart';
import 'repositories/item_repository_api.dart'; // หรือ path ที่เก็บ ItemRepository ของสัปดาห์ที่ 6
import 'screens/main_scaffold.dart';
import 'models/cart_model.dart'; // หรือ path ที่เก็บ CartModel ของสัปดาห์ที่ 5

void main() {
  // 1. สร้าง AppDatabase ขึ้นมา 1 ตัวใน main() ห้ามสร้างซ้ำในจุดอื่น
  final db = AppDatabase();

  runApp(MyApp(database: db));
}

class MyApp extends StatelessWidget {
  final AppDatabase database;

  const MyApp({super.key, required this.database});

  @override
  Widget build(BuildContext context) {
    // เตรียม Repository ทั้งสองตัวโดยใช้ AppDatabase ที่ส่งต่อมา
    final favoritesRepository = FavoritesRepositoryDrift(database);
    final draftRepository = ListingDraftRepositoryDrift(database);
    final itemRepository = ItemRepositoryApi();

    return MultiProvider(
      providers: [
        // คง Provider ของ CartModel ไว้ตามเดิมตั้งแต่สัปดาห์ที่ 5-7
        ChangeNotifierProvider(create: (_) => CartModel()),
      ],
      child: MaterialApp(
        title: 'Campus Marketplace',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        // ส่ง Repository ทั้ง 3 ตัวเข้าไปใน MainScaffold
        home: MainScaffold(
          itemRepository: itemRepository,
          favoritesRepository: favoritesRepository,
          draftRepository: draftRepository,
        ),
      ),
    );
  }
}