import '../models/listing_draft.dart';
import '../database/app_database.dart';

abstract class ListingDraftRepository {
  // บันทึกร่างใหม่ — รับ ListingDraft ที่มีอยู่แล้วจากสัปดาห์ 7
  // บวก imagePath แยกต่างหาก เพราะ ListingDraft เดิมไม่มี field นี้
  Future<void> saveDraft(ListingDraft draft, String imagePath);

  // คืนค่า ListingDraftRow (ที่ Drift Generate ขึ้น) ไม่ใช่ ListingDraft
  // เพราะเราต้องการ id และ updatedAt ที่เก็บอยู่ในฐานข้อมูลด้วย
  Future<List<ListingDraftRow>> getAllDrafts();

  Future<void> deleteDraft(int id);
}
