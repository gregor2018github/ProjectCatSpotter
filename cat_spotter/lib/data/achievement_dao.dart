import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';

class AchievementDao {
  /// Returns a map of achievement id → unlock time.
  static Future<Map<String, DateTime>> getUnlocked() async {
    final db = await DatabaseHelper.database;
    final rows = await db.query('achievements');
    return {
      for (final r in rows)
        r['id'] as String: DateTime.parse(r['unlocked_at'] as String),
    };
  }

  /// Records achievements as unlocked; already-unlocked ids are left as-is.
  static Future<void> markUnlocked(Iterable<String> ids, DateTime at) async {
    final db = await DatabaseHelper.database;
    final batch = db.batch();
    for (final id in ids) {
      batch.insert(
        'achievements',
        {'id': id, 'unlocked_at': at.toIso8601String()},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await batch.commit(noResult: true);
  }
}
