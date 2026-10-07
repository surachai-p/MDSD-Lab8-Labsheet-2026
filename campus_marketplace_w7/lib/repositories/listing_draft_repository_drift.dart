import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../models/listing_draft.dart';
import 'listing_draft_repository.dart';

class ListingDraftRepositoryDrift implements ListingDraftRepository {
  final AppDatabase db;

  ListingDraftRepositoryDrift(this.db);

  @override
  Future<void> saveDraft(ListingDraft draft, String imagePath) async {
    await db.into(db.listingDrafts).insert(
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
    // เปลี่ยนมาเรียงตาม id จากมากไปน้อย (รายการล่าสุดอยู่บนสุด)
    return await (db.select(db.listingDrafts)
          ..orderBy([(t) => OrderingTerm(expression: t.id, mode: OrderingMode.desc)]))
        .get();
  }

  @override
  Future<void> deleteDraft(int id) async {
    await (db.delete(db.listingDrafts)..where((t) => t.id.equals(id))).go();
  }
}