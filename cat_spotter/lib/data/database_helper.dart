import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static const String _dbName = 'cat_spotter.db';
  static const int _dbVersion = 2;

  static Database? _database;

  static Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // v2: add per-cat colour for map markers (default = accent 0xFFFF8C42)
      await db.execute(
        'ALTER TABLE cat_profiles ADD COLUMN color INTEGER NOT NULL DEFAULT 4294937666',
      );
    }
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE cat_profiles (
        id               TEXT PRIMARY KEY,
        name             TEXT NOT NULL,
        cover_image_path TEXT,
        notes            TEXT,
        color            INTEGER NOT NULL DEFAULT 4294937666,
        created_at       TEXT NOT NULL,
        updated_at       TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE cat_sightings (
        id                  TEXT PRIMARY KEY,
        cat_profile_id      TEXT NOT NULL,
        image_path          TEXT NOT NULL,
        latitude            REAL NOT NULL,
        longitude           REAL NOT NULL,
        accuracy            REAL,
        location_fine_tuned INTEGER NOT NULL DEFAULT 0,
        notes               TEXT,
        captured_at         TEXT NOT NULL,
        created_at          TEXT NOT NULL,
        FOREIGN KEY (cat_profile_id) REFERENCES cat_profiles(id)
            ON DELETE CASCADE
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_sightings_cat ON cat_sightings(cat_profile_id)',
    );
    await db.execute(
      'CREATE INDEX idx_sightings_time ON cat_sightings(captured_at DESC)',
    );
  }
}
