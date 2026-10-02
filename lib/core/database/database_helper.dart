import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _openDatabase();
    return _database!;
  }

  Future<Database> _openDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'mas_ai.db');

    return openDatabase(
      path,
      version: 2,
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );
  }

  Future<void> _createDatabase(
    Database db,
    int version,
  ) async {
    await db.execute('''
      CREATE TABLE subjects (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE topics (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subject_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        mastery REAL NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (subject_id) REFERENCES subjects (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE content (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subject_id INTEGER,
        topic_id INTEGER,
        title TEXT NOT NULL,
        type TEXT NOT NULL,
        content TEXT NOT NULL,
        file_path TEXT,
        original_file_name TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (subject_id) REFERENCES subjects (id),
        FOREIGN KEY (topic_id) REFERENCES topics (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE questions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        content_id INTEGER,
        topic_id INTEGER,
        type TEXT NOT NULL,
        question TEXT NOT NULL,
        answer TEXT NOT NULL,
        options TEXT,
        explanation TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (content_id) REFERENCES content (id),
        FOREIGN KEY (topic_id) REFERENCES topics (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE attempts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        question_id INTEGER NOT NULL,
        answer TEXT,
        is_correct INTEGER NOT NULL,
        error_reason TEXT,
        answered_at TEXT NOT NULL,
        FOREIGN KEY (question_id) REFERENCES questions (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE reviews (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        topic_id INTEGER NOT NULL,
        due_at TEXT NOT NULL,
        interval_days INTEGER NOT NULL DEFAULT 1,
        ease REAL NOT NULL DEFAULT 2.5,
        repetitions INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (topic_id) REFERENCES topics (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE mind_maps (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        content_id INTEGER,
        topic_id INTEGER,
        title TEXT NOT NULL,
        data TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (content_id) REFERENCES content (id),
        FOREIGN KEY (topic_id) REFERENCES topics (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE files (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        content_id INTEGER,
        file_name TEXT NOT NULL,
        file_path TEXT NOT NULL,
        mime_type TEXT,
        file_size INTEGER,
        extracted_text TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (content_id) REFERENCES content (id)
      )
    ''');
  }

  Future<void> _upgradeDatabase(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await db.execute('''
        ALTER TABLE content ADD COLUMN file_path TEXT
      ''');

      await db.execute('''
        ALTER TABLE content ADD COLUMN original_file_name TEXT
      ''');

      await db.execute('''
        CREATE TABLE mind_maps (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          content_id INTEGER,
          topic_id INTEGER,
          title TEXT NOT NULL,
          data TEXT NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (content_id) REFERENCES content (id),
          FOREIGN KEY (topic_id) REFERENCES topics (id)
        )
      ''');

      await db.execute('''
        CREATE TABLE files (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          content_id INTEGER,
          file_name TEXT NOT NULL,
          file_path TEXT NOT NULL,
          mime_type TEXT,
          file_size INTEGER,
          extracted_text TEXT,
          created_at TEXT NOT NULL,
          FOREIGN KEY (content_id) REFERENCES content (id)
        )
      ''');
    }
  }

  Future<void> close() async {
    final db = _database;

    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
