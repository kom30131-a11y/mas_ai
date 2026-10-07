import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';

class DocxDraftRepository {
  DocxDraftRepository._();

  static final instance =
      DocxDraftRepository._();

  Future<void> ensureReady() async {
    final db =
        await DatabaseHelper.instance.database;

    await db.execute('''
      CREATE TABLE IF NOT EXISTS document_drafts (
        content_id INTEGER PRIMARY KEY,
        draft_path TEXT NOT NULL,
        original_path TEXT NOT NULL,
        saved_at TEXT NOT NULL
      )
    ''');
  }

  Future<Map<String, dynamic>?> getDraft(
    int contentId,
  ) async {
    await ensureReady();

    final db =
        await DatabaseHelper.instance.database;

    final rows = await db.query(
      'document_drafts',
      where: 'content_id = ?',
      whereArgs: [contentId],
      limit: 1,
    );

    return rows.isEmpty
        ? null
        : rows.first;
  }

  Future<void> saveDraft({
    required int contentId,
    required String draftPath,
    required String originalPath,
  }) async {
    await ensureReady();

    final db =
        await DatabaseHelper.instance.database;

    await db.insert(
      'document_drafts',
      {
        'content_id': contentId,
        'draft_path': draftPath,
        'original_path': originalPath,
        'saved_at':
            DateTime.now().toIso8601String(),
      },
      conflictAlgorithm:
          ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteDraft(
    int contentId,
  ) async {
    await ensureReady();

    final db =
        await DatabaseHelper.instance.database;

    await db.delete(
      'document_drafts',
      where: 'content_id = ?',
      whereArgs: [contentId],
    );
  }
}
