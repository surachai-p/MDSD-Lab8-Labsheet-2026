import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../models/listing_draft.dart';
import 'listing_draft_repository.dart';

class ListingDraftRepositoryDrift implements ListingDraftRepository {
  final AppDatabase _db;

  ListingDraftRepositoryDrift(this._db);

  @override
  Future<void> saveDraft(ListingDraft draft, String imagePath) async {
    // ดึงค่าจาก ListingDraft เดิม + imagePath ที่รับมาแยก
    // แล้วสร้าง Companion object สำหรับ Insert ลงฐานข้อมูล
    await _db.into(_db.listingDrafts).insert(
      ListingDraftsCompanion.insert(
        title: draft.title,
        category: draft.category,
        description: draft.description,
        imagePath: imagePath,
      ),
    );
  }

  @override
  Future<List<ListingDraftRow>> getAllDrafts() async {
    // ดึงร่างทั้งหมดเรียงจากแก้ไขล่าสุด (updatedAt desc)
    return await (_db.select(_db.listingDrafts)
          ..orderBy([
            (t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc)
          ]))
        .get();
  }

  @override
  Future<void> deleteDraft(int id) async {
    // ลบร่างโดยอ้างอิงจาก id
    await (_db.delete(_db.listingDrafts)..where((t) => t.id.equals(id))).go();
  }
}
