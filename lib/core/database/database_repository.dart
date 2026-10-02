import 'database_helper.dart';

class DatabaseRepository {
  DatabaseRepository._();

  static final DatabaseRepository instance = DatabaseRepository._();

  Future<int> insertSubject(Map<String, dynamic> data) async {
    final db = await DatabaseHelper.instance.database;

    return db.insert(
      'subjects',
      data,
    );
  }

  Future<int> insertTopic(Map<String, dynamic> data) async {
    final db = await DatabaseHelper.instance.database;

    return db.insert(
      'topics',
      data,
    );
  }

  Future<int> insertContent(Map<String, dynamic> data) async {
    final db = await DatabaseHelper.instance.database;

    return db.insert(
      'content',
      data,
    );
  }

  Future<int> insertFile(Map<String, dynamic> data) async {
    final db = await DatabaseHelper.instance.database;

    return db.insert(
      'files',
      data,
    );
  }

  Future<int> insertQuestion(Map<String, dynamic> data) async {
    final db = await DatabaseHelper.instance.database;

    return db.insert(
      'questions',
      data,
    );
  }

  Future<int> insertAttempt(Map<String, dynamic> data) async {
    final db = await DatabaseHelper.instance.database;

    return db.insert(
      'attempts',
      data,
    );
  }

  Future<int> insertReview(Map<String, dynamic> data) async {
    final db = await DatabaseHelper.instance.database;

    return db.insert(
      'reviews',
      data,
    );
  }

  Future<int> insertMindMap(Map<String, dynamic> data) async {
    final db = await DatabaseHelper.instance.database;

    return db.insert(
      'mind_maps',
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

  Future<List<Map<String, dynamic>>> getContent({
    int? topicId,
  }) async {
    final db = await DatabaseHelper.instance.database;

    if (topicId == null) {
      return db.query(
        'content',
        orderBy: 'id DESC',
      );
    }

    return db.query(
      'content',
      where: 'topic_id = ?',
      whereArgs: [topicId],
      orderBy: 'id DESC',
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

  Future<int> deleteContent(int id) async {
    final db = await DatabaseHelper.instance.database;

    return db.delete(
      'content',
      where: 'id = ?',
      whereArgs: [id],
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

  Future<int> deleteTopic(int id) async {
    final db = await DatabaseHelper.instance.database;

    return db.delete(
      'topics',
      where: 'id = ?',
      whereArgs: [id],
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

  Future<int> deleteQuestion(int id) async {
    final db = await DatabaseHelper.instance.database;

    return db.delete(
      'questions',
      where: 'id = ?',
      whereArgs: [id],
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
