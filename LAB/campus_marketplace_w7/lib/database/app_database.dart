import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

// นำเข้าไฟล์ตารางที่เราเพิ่งสร้างในส่วนที่ 2
import 'tables.dart'; 

// ระบุชื่อไฟล์ที่ Drift จะ Generate ขึ้นมาอัตโนมัติ
part 'app_database.g.dart';

// ระบุตารางทั้งหมดที่จะใช้ในฐานข้อมูลนี้
@DriftDatabase(tables: [FavoriteItems, ListingDrafts])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  // ระบุเวอร์ชันของฐานข้อมูล (เริ่มต้นที่ 1)
  @override
  int get schemaVersion => 1;
}

// ฟังก์ชันสำหรับเปิดไฟล์ฐานข้อมูล SQLite ในเครื่อง
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    // หาตำแหน่งโฟลเดอร์ Documents ของแอป
    final dbFolder = await getApplicationDocumentsDirectory();
    
    // สร้างไฟล์ฐานข้อมูลชื่อ campus_marketplace.sqlite
    final file = File(p.join(dbFolder.path, 'campus_marketplace.sqlite'));
    
    return NativeDatabase.createInBackground(file);
  });
}