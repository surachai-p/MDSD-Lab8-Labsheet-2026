import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'models/cart_model.dart';
import 'database/app_database.dart';
import 'repositories/item_repository_api.dart';
// นำเข้าไฟล์ที่จะสร้างในอนาคต (ตอนนี้จะขึ้นเส้นแดง ถือเป็นปกติ)
import 'repositories/favorites_repository_drift.dart';
import 'repositories/listing_draft_repository_drift.dart';
import 'screens/main_scaffold.dart';

void main() {
  // สร้าง AppDatabase 1 ตัว เก็บไว้ในตัวแปร db
  final db = AppDatabase();

  runApp(
    ChangeNotifierProvider<CartModel>(
      create: (context) => CartModel(),
      // ส่ง db เข้าไปเป็นพารามิเตอร์ของ MyApp
      child: MyApp(db: db),
    ),
  );
}

class MyApp extends StatelessWidget {
  final AppDatabase db;
  // เพิ่ม field รับค่า AppDatabase
  const MyApp({super.key, required this.db});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // เพิ่มบรรทัดนี้เพื่อซ่อนป้าย DEBUG
      title: 'Campus Marketplace',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // สร้าง MainScaffold โดยส่งพารามิเตอร์ 3 ตัวเข้าไป
      home: MainScaffold(
        itemRepository: ItemRepositoryApi(),
        favoritesRepository: FavoritesRepositoryDrift(
          db,
        ), // รอสร้างคลาสจริงในส่วนที่ 4
        draftRepository: ListingDraftRepositoryDrift(
          db,
        ), // รอสร้างคลาสจริงในส่วนที่ 5
      ),
    );
  }
}
