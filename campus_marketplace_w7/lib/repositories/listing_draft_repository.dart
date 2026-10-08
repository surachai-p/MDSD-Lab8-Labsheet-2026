import '../database/app_database.dart';
import '../models/listing_draft.dart';

abstract class ListingDraftRepository {
  Future<int> saveDraft(ListingDraft draft, String? imagePath);
  Future<List<ListingDraftRow>> getAllDrafts();
  Future<ListingDraftRow?> getDraftById(int id);
  Future<void> deleteDraft(int id);
}
