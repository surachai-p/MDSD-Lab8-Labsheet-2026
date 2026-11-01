import 'dart:io';

import 'package:campus_marketplace_w7/database/app_database.dart';
import 'package:campus_marketplace_w7/models/listing_draft.dart';
import 'package:campus_marketplace_w7/repositories/listing_draft_repository_drift.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

const _draft = ListingDraft(
  title: 'หนังสือแคลคูลัส',
  category: 'หนังสือเรียน',
  description: 'สภาพดี',
);

void main() {
  late AppDatabase db;
  late ListingDraftRepositoryDrift repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = ListingDraftRepositoryDrift(db);
  });

  tearDown(() => db.close());

  test('saveDraft stores the draft fields with the image path', () async {
    await repository.saveDraft(_draft, '/images/a.jpg');

    final row = (await repository.getAllDrafts()).single;
    expect(row.title, 'หนังสือแคลคูลัส');
    expect(row.category, 'หนังสือเรียน');
    expect(row.description, 'สภาพดี');
    expect(row.imagePath, '/images/a.jpg');
  });

  test('sorts by updatedAt, newest first', () async {
    Future<void> insertAt(String title, DateTime updatedAt) {
      return db
          .into(db.listingDrafts)
          .insert(
            ListingDraftsCompanion.insert(
              title: title,
              category: 'อื่นๆ',
              description: '',
              imagePath: '',
              updatedAt: Value(updatedAt),
            ),
          );
    }

    await insertAt('เก่า', DateTime(2026, 1, 1));
    await insertAt('ใหม่', DateTime(2026, 1, 3));
    await insertAt('กลาง', DateTime(2026, 1, 2));

    final drafts = await repository.getAllDrafts();
    expect(drafts.map((d) => d.title), ['ใหม่', 'กลาง', 'เก่า']);
  });

  test('deleteDraft removes only the given draft', () async {
    await repository.saveDraft(_draft, 'a.jpg');
    await repository.saveDraft(_draft, 'b.jpg');
    final newest = (await repository.getAllDrafts()).first;

    await repository.deleteDraft(newest.id);

    final drafts = await repository.getAllDrafts();
    expect(drafts.map((d) => d.imagePath), ['a.jpg']);
  });

  test('an empty title is rejected', () async {
    const empty = ListingDraft(title: '', category: 'อื่นๆ', description: '');

    await expectLater(
      repository.saveDraft(empty, 'a.jpg'),
      throwsA(isA<InvalidDataException>()),
    );
  });

  test('drafts survive closing and reopening the file', () async {
    final directory = await Directory.systemTemp.createTemp('drafts_test');
    addTearDown(() => directory.delete(recursive: true));
    final file = File(p.join(directory.path, 'test.sqlite'));

    var fileDb = AppDatabase.forTesting(NativeDatabase(file));
    await ListingDraftRepositoryDrift(fileDb).saveDraft(_draft, 'a.jpg');
    await fileDb.close();

    fileDb = AppDatabase.forTesting(NativeDatabase(file));
    final drafts = await ListingDraftRepositoryDrift(fileDb).getAllDrafts();
    await fileDb.close();
    expect(drafts.single.title, 'หนังสือแคลคูลัส');
  });
}
