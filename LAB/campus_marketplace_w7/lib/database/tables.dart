import 'package:drift/drift.dart';

// ตารางที่ 1: รายการโปรด (Favorites)
class FavoriteItems extends Table {
  // Primary Key ของแถวในฐานข้อมูลในเครื่อง (รันเลขอัตโนมัติ)
  IntColumn get id => integer().autoIncrement()();

  // รหัสสินค้าจาก Fake Store API พร้อมบังคับห้ามซ้ำ (.unique())
  IntColumn get itemId => integer().unique()();

  // สำเนาข้อมูลสินค้าสำหรับแสดงผลแบบ Offline-first
  TextColumn get title => text()();
  RealColumn get price => real()();
  TextColumn get imageUrl => text()();

  // เวลาที่กดบันทึกเป็นรายการโปรด (ใช้เรียงลำดับจากล่าสุด)
  DateTimeColumn get addedAt => dateTime().withDefault(currentDateAndTime)();
}

// ตารางที่ 2: ร่างประกาศขายสินค้า (Listing Drafts)
@DataClassName('ListingDraftRow') // บังคับชื่อ Class ที่ Drift สร้าง เพื่อไม่ให้ชนกับ ListingDraft เดิม
class ListingDrafts extends Table {
  // Primary Key ของร่างประกาศ (รันเลขอัตโนมัติ)
  IntColumn get id => integer().autoIncrement()();

  // รายละเอียดประกาศที่ได้จาก Gemini Vision
  TextColumn get title => text().withLength(min: 1, max: 100)();
  TextColumn get category => text()();
  TextColumn get description => text()();

  // ที่อยู่ของไฟล์รูปภาพในตัวเครื่อง (Local file path)
  TextColumn get imagePath => text()();

  // เวลาที่แก้ไขร่างล่าสุด
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}