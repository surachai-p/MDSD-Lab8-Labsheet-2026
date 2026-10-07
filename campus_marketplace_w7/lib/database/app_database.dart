import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

// ดึงตารางจากไฟล์ tables.dart ที่เราสร้างไว้ในขั้นตอน 2.2
import 'tables.dart';

// ประกาศให้ไฟล์นี้รอรับโค้ดที่จะถูก Generate อัตโนมัติ
part 'app_database.g.dart';

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'campus_db.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

// นำคลาส FavoriteItems และ ListingDrafts เข้ามาในฐานข้อมูล
@DriftDatabase(tables: [FavoriteItems, ListingDrafts])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}