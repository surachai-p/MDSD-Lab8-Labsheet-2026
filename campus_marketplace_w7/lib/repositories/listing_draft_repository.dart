import '../database/app_database.dart';
import '../models/listing_draft.dart'; // แก้ไข path ให้ตรงกับไฟล์ model ของคุณ

abstract class ListingDraftRepository {
  Future<void> saveDraft(ListingDraft draft, String imagePath);
  Future<List<ListingDraftRow>> getAllDrafts();
  Future<void> deleteDraft(int id);
}