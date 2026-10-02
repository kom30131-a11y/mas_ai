import 'database_helper.dart';

class DatabaseRepository {
  DatabaseRepository._();

  static final DatabaseRepository instance = DatabaseRepository._();

  // ============================================================
  // Subjects
  // ============================================================

  Future<int> insertSubject(Map<String, dynamic> data) async {
    final db = await DatabaseHelper.instance.database;

    return db.insert(
      'subjects',
      data,
    );
  }

  Future<List<Map<String, dynamic>>> getSubjects() async {
    final db = await DatabaseHelper.instance.database;

    return db.query(
      'subjects',
      orderBy: 'id DESC',
    );
  }

  Future<int> deleteSubject(int id) async {
    final db = await DatabaseHelper.instance.database;

    return db.delete(
      'subjects',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ============================================================
  // Topics
  // ============================================================

  Future<int> insertTopic(Map<String, dynamic> data) async {
    final db = await DatabaseHelper.instance.database;

    return db.insert(
      'topics',
      data,
    );
  }

  Future<List<Map<String, dynamic>>> getTopics({
    int? subjectId,
  }) async {
    final db = await DatabaseHelper.instance.database;

    if (subjectId == null) {
      return db.query(
        'topics',
        orderBy: 'id DESC',
      );
    }

    return db.query(
      'topics',
      where: 'subject_id = ?',
      whereArgs: [subjectId],
      orderBy: 'id DESC',
    );
  }

  Future<int> deleteTopic(int id) async {
    final db = await DatabaseHelper.instance.database;

    return db.delete(
      'topics',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ============================================================
  // Library Folders
  // ============================================================

  Future<int> insertFolder({
    required String name,
    int? parentId,
    int? subjectId,
  }) async {
    final db = await DatabaseHelper.instance.database;

    final now = DateTime.now().toIso8601String();

    return db.insert(
      'folders',
      {
        'name': name.trim(),
        'parent_id': parentId,
        'subject_id': subjectId,
        'created_at': now,
        'updated_at': now,
      },
    );
  }

  Future<List<Map<String, dynamic>>> getFolders({
    int? parentId,
  }) async {
    final db = await DatabaseHelper.instance.database;

    if (parentId == null) {
      return db.query(
        'folders',
        where: 'parent_id IS NULL',
        orderBy: 'name COLLATE NOCASE ASC',
      );
    }

    return db.query(
      'folders',
      where: 'parent_id = ?',
      whereArgs: [parentId],
      orderBy: 'name COLLATE NOCASE ASC',
    );
  }

  Future<int> renameFolder({
    required int folderId,
    required String name,
  }) async {
    final db = await DatabaseHelper.instance.database;

    return db.update(
      'folders',
      {
        'name': name.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [folderId],
    );
  }

  Future<void> deleteFolder(int folderId) async {
    final db = await DatabaseHelper.instance.database;

    await _deleteFolderRecursive(
      db,
      folderId,
    );
  }

  Future<void> _deleteFolderRecursive(
    dynamic db,
    int folderId,
  ) async {
    final children = await db.query(
      'folders',
      columns: ['id'],
      where: 'parent_id = ?',
      whereArgs: [folderId],
    );

    for (final child in children) {
      await _deleteFolderRecursive(
        db,
        child['id'] as int,
      );
    }

    await db.update(
      'content',
      {
        'folder_id': null,
      },
      where: 'folder_id = ?',
      whereArgs: [folderId],
    );

    await db.delete(
      'folders',
      where: 'id = ?',
      whereArgs: [folderId],
    );
  }

  // ============================================================
  // Content
  // ============================================================

  Future<int> insertContent(Map<String, dynamic> data) async {
    final db = await DatabaseHelper.instance.database;

    return db.insert(
      'content',
      data,
    );
  }

  Future<List<Map<String, dynamic>>> getContent({
    int? topicId,
    int? folderId,
  }) async {
    final db = await DatabaseHelper.instance.database;

    if (folderId != null) {
      return db.query(
        'content',
        where: 'folder_id = ?',
        whereArgs: [folderId],
        orderBy: 'id DESC',
      );
    }

    if (topicId != null) {
      return db.query(
        'content',
        where: 'topic_id = ?',
        whereArgs: [topicId],
        orderBy: 'id DESC',
      );
    }

    return db.query(
      'content',
      orderBy: 'id DESC',
    );
  }

  Future<int> moveContentToFolder({
    required int contentId,
    int? folderId,
  }) async {
    final db = await DatabaseHelper.instance.database;

    return db.update(
      'content',
      {
        'folder_id': folderId,
      },
      where: 'id = ?',
      whereArgs: [contentId],
    );
  }

  Future<int> deleteContent(int id) async {
    final db = await DatabaseHelper.instance.database;

    return db.delete(
      'content',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ============================================================
  // Files
  // ============================================================

  Future<int> insertFile(Map<String, dynamic> data) async {
    final db = await DatabaseHelper.instance.database;

    return db.insert(
      'files',
      data,
    );
  }

  Future<List<Map<String, dynamic>>> getFiles({
    int? contentId,
  }) async {
    final db = await DatabaseHelper.instance.database;

    if (contentId == null) {
      return db.query(
        'files',
        orderBy: 'id DESC',
      );
    }

    return db.query(
      'files',
      where: 'content_id = ?',
      whereArgs: [contentId],
      orderBy: 'id DESC',
    );
  }

  Future<int> deleteFile(int id) async {
    final db = await DatabaseHelper.instance.database;

    return db.delete(
      'files',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ============================================================
  // Questions
  // ============================================================

  Future<int> insertQuestion(Map<String, dynamic> data) async {
    final db = await DatabaseHelper.instance.database;

    return db.insert(
      'questions',
      data,
    );
  }

  Future<List<Map<String, dynamic>>> getQuestions({
    int? contentId,
  }) async {
    final db = await DatabaseHelper.instance.database;

    if (contentId == null) {
      return db.query(
        'questions',
        orderBy: 'id DESC',
      );
    }

    return db.query(
      'questions',
      where: 'content_id = ?',
      whereArgs: [contentId],
      orderBy: 'id DESC',
    );
  }

  Future<int> deleteQuestion(int id) async {
    final db = await DatabaseHelper.instance.database;

    return db.delete(
      'questions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ============================================================
  // Attempts
  // ============================================================

  Future<int> insertAttempt(Map<String, dynamic> data) async {
    final db = await DatabaseHelper.instance.database;

    return db.insert(
      'attempts',
      data,
    );
  }

  Future<List<Map<String, dynamic>>> getAttempts({
    int? questionId,
  }) async {
    final db = await DatabaseHelper.instance.database;

    if (questionId == null) {
      return db.query(
        'attempts',
        orderBy: 'id DESC',
      );
    }

    return db.query(
      'attempts',
      where: 'question_id = ?',
      whereArgs: [questionId],
      orderBy: 'id DESC',
    );
  }

  // ============================================================
  // Reviews
  // ============================================================

  Future<int> insertReview(Map<String, dynamic> data) async {
    final db = await DatabaseHelper.instance.database;

    return db.insert(
      'reviews',
      data,
    );
  }

  Future<List<Map<String, dynamic>>> getReviews({
    int? topicId,
  }) async {
    final db = await DatabaseHelper.instance.database;

    if (topicId == null) {
      return db.query(
        'reviews',
        orderBy: 'id DESC',
      );
    }

    return db.query(
      'reviews',
      where: 'topic_id = ?',
      whereArgs: [topicId],
      orderBy: 'id DESC',
    );
  }

  // ============================================================
  // Mind Maps
  // ============================================================

  Future<int> insertMindMap(Map<String, dynamic> data) async {
    final db = await DatabaseHelper.instance.database;

    return db.insert(
      'mind_maps',
      data,
    );
  }

  Future<List<Map<String, dynamic>>> getMindMaps({
    int? contentId,
  }) async {
    final db = await DatabaseHelper.instance.database;

    if (contentId == null) {
      return db.query(
        'mind_maps',
        orderBy: 'id DESC',
      );
    }

    return db.query(
      'mind_maps',
      where: 'content_id = ?',
      whereArgs: [contentId],
      orderBy: 'id DESC',
    );
  }

  Future<int> deleteMindMap(int id) async {
    final db = await DatabaseHelper.instance.database;

    return db.delete(
      'mind_maps',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
