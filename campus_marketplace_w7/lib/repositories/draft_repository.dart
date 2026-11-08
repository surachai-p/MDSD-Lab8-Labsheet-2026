import 'package:drift/drift.dart';

import '../database/app_database.dart';

class DraftRepository {
  final AppDatabase _db;

  DraftRepository(this._db);

  // เพิ่มรายการ Draft
  Future<int> addDraft({
    required String title,
    required String category,
    required String description,
    required String imagePath,
  }) {
    return _db
        .into(_db.listingDrafts)
        .insert(
          ListingDraftsCompanion.insert(
            title: title,
            category: category,
            description: description,
            imagePath: imagePath,
          ),
        );
  }

  // ดึงรายการ Draft ทั้งหมด
  Future<List<ListingDraftRow>> getAllDrafts() {
    return (_db.select(_db.listingDrafts)..orderBy([
          (t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
        ]))
        .get();
  }

  // ลบ Draft
  Future<void> deleteDraft(int id) async {
    await (_db.delete(_db.listingDrafts)..where((t) => t.id.equals(id))).go();
  }
}
