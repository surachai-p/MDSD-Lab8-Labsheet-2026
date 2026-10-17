import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// นำเข้าไฟล์ที่จำเป็น
import 'database/app_database.dart';
import 'models/cart_model.dart';
import 'repositories/item_repository_api.dart';
import 'repositories/favorites_repository_drift.dart';
import 'repositories/listing_draft_repository_drift.dart';
import 'screens/main_scaffold.dart';

void main() {
  // จำเป็นต้องมีเพื่อให้ path_provider ทำงานได้ถูกต้องก่อน runApp
  WidgetsFlutterBinding.ensureInitialized();

  // 1. สร้างฐานข้อมูล 1 ตัว (Singleton-like)
  final db = AppDatabase();

  runApp(
    ChangeNotifierProvider(
      create: (context) => CartModel(),
      // 2. ส่ง db เข้าไปใน MyApp
      child: MyApp(db: db),
    ),
  );
}

class MyApp extends StatelessWidget {
  final AppDatabase db;

  // รับค่า db มาทาง Constructor
  const MyApp({super.key, required this.db});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Campus Marketplace',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // 3. ส่งข้อมูลต่อไปยัง MainScaffold
      home: MainScaffold(
        itemRepository: ItemRepositoryApi(),
        favoritesRepository: FavoritesRepositoryDrift(db),
        draftRepository: ListingDraftRepositoryDrift(db),
      ),
    );
  }
}
