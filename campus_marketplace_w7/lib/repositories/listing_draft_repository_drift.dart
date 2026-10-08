import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../models/listing_draft.dart';
import 'listing_draft_repository.dart';

class ListingDraftRepositoryDrift implements ListingDraftRepository {
  final AppDatabase database;

  ListingDraftRepositoryDrift(this.database);

  @override
  Future<int> saveDraft(ListingDraft draft, String? imagePath) async {
    return await database.into(database.listingDrafts).insert(
          ListingDraftsCompanion(
            title: Value(draft.title),
            category: Value(draft.category),
            description: Value(draft.description),
            imagePath: Value(imagePath ?? ''),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  @override
  Future<List<ListingDraftRow>> getAllDrafts() async {
    return await (database.select(database.listingDrafts)
          ..orderBy([
            (tbl) => OrderingTerm(
                  expression: tbl.updatedAt,
                  mode: OrderingMode.desc,
                ),
          ]))
        .get();
  }

  @override
  Future<ListingDraftRow?> getDraftById(int id) async {
    return await (database.select(database.listingDrafts)
          ..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  @override
  Future<void> deleteDraft(int id) async {
    await (database.delete(database.listingDrafts)
          ..where((tbl) => tbl.id.equals(id)))
        .go();
  }
}
