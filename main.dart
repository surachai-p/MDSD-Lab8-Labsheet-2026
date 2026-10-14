import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/cart_model.dart';
import 'screens/main_scaffold.dart';
import 'repositories/item_repository_api.dart';
import 'repositories/favorites_repository_drift.dart';
import 'repositories/listing_draft_repository_drift.dart';
import 'database/app_database.dart';

void main() {
  // สร้าง AppDatabase() ขึ้นมา 1 ตัว เก็บไว้ในตัวแปร db
  final db = AppDatabase();

  runApp(
    ChangeNotifierProvider(
      create: (context) => CartModel(),
      // ส่ง db เข้าไปเป็นพารามิเตอร์ของ MyApp
      child: MyApp(db: db),
    ),
  );
}

class MyApp extends StatelessWidget {
  // เพิ่ม field ใหม่ใน MyApp รับค่า AppDatabase
  final AppDatabase db;
  const MyApp({super.key, required this.db});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Campus Marketplace',
      debugShowCheckedModeBanner: false,
      home: MainScaffold(
        itemRepository: ItemRepositoryApi(),
        favoritesRepository: FavoritesRepositoryDrift(db),
        draftRepository: ListingDraftRepositoryDrift(db), // เชื่อมของจริงแล้ว!
      ),
    );
  }
}