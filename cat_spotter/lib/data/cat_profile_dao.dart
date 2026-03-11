import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';
import '../models/cat_profile.dart';

class CatProfileDao {
  /// Returns all profiles ordered by most recently updated,
  /// with sighting_count populated via LEFT JOIN.
  static Future<List<CatProfile>> getAllProfiles() async {
    final db = await DatabaseHelper.database;
    final maps = await db.rawQuery('''
      SELECT cp.*, COUNT(cs.id) AS sighting_count
      FROM cat_profiles cp
      LEFT JOIN cat_sightings cs ON cs.cat_profile_id = cp.id
      GROUP BY cp.id
      ORDER BY cp.updated_at DESC
    ''');
    return maps.map(CatProfile.fromMap).toList();
  }

  static Future<CatProfile?> getProfileById(String id) async {
    final db = await DatabaseHelper.database;
    final maps = await db.rawQuery('''
      SELECT cp.*, COUNT(cs.id) AS sighting_count
      FROM cat_profiles cp
      LEFT JOIN cat_sightings cs ON cs.cat_profile_id = cp.id
      WHERE cp.id = ?
      GROUP BY cp.id
    ''', [id]);
    if (maps.isEmpty) return null;
    return CatProfile.fromMap(maps.first);
  }

  static Future<void> insertProfile(CatProfile profile) async {
    final db = await DatabaseHelper.database;
    await db.insert(
      'cat_profiles',
      profile.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> updateProfile(CatProfile profile) async {
    final db = await DatabaseHelper.database;
    await db.update(
      'cat_profiles',
      profile.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [profile.id],
    );
  }

  /// Deletes the profile; CASCADE removes all linked sightings from DB.
  /// Caller must manually delete image files before calling this.
  static Future<void> deleteProfile(String id) async {
    final db = await DatabaseHelper.database;
    await db.delete('cat_profiles', where: 'id = ?', whereArgs: [id]);
  }
}
