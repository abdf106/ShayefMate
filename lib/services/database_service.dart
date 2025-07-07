import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'feedback_app.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE feedback(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            text TEXT,
            rating TEXT,
            audioPath TEXT,
            timestamp TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE feedback ADD COLUMN audioPath TEXT');
        }
      },
    );
  }

  static Future<void> insertFeedback(String text, int rating) async {
    final db = await database;
    await db.insert('feedback', {
      'text': text,
      'rating': rating,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  static Future<void> insertFeedbackWithAudio({
    required String text,
    required String rating,
    String? audioPath,
  }) async {
    final db = await database;
    await db.insert('feedback', {
      'text': text,
      'rating': rating,
      'audioPath': audioPath,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  static Future<List<Map<String, dynamic>>> getAllFeedback() async {
    final db = await database;
    return await db.query('feedback', orderBy: 'timestamp DESC');
  }
}
