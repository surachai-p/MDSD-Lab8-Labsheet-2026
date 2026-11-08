import '../models/listing_draft.dart';
import '../database/app_database.dart';

abstract class ListingDraftRepository {
  Future<int> saveDraft(ListingDraft draft, String imagePath);

  Future<List<ListingDraftRow>> getAllDrafts();

  Future<void> deleteDraft(int id);
}