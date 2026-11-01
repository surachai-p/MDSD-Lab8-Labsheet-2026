import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [FavoriteItems, ListingDrafts])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  // ใช้ใน Test เพื่อส่งฐานข้อมูลในหน่วยความจำหรือไฟล์ชั่วคราวเข้ามาแทน
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;
}

// LazyDatabase ทำให้ main() สร้าง AppDatabase() ได้ทันที แล้วค่อยหา path ของไฟล์ตอน Query ครั้งแรก
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(p.join(directory.path, 'campus_marketplace.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
