import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';
import '../models/cat_sighting.dart';

class CatSightingDao {
  static Future<List<CatSighting>> getSightingsForCat(
      String catProfileId) async {
    final db = await DatabaseHelper.database;
    final maps = await db.query(
      'cat_sightings',
      where: 'cat_profile_id = ?',
      whereArgs: [catProfileId],
      orderBy: 'captured_at DESC',
    );
    return maps.map(CatSighting.fromMap).toList();
  }

  /// Returns every sighting across all cats, ordered newest first.
  static Future<List<CatSighting>> getAllSightings() async {
    final db = await DatabaseHelper.database;
    final maps = await db.query(
      'cat_sightings',
      orderBy: 'captured_at DESC',
    );
    return maps.map(CatSighting.fromMap).toList();
  }

  static Future<CatSighting?> getSightingById(String id) async {
    final db = await DatabaseHelper.database;
    final maps = await db.query(
      'cat_sightings',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return CatSighting.fromMap(maps.first);
  }

  static Future<void> insertSighting(CatSighting sighting) async {
    final db = await DatabaseHelper.database;
    await db.insert(
      'cat_sightings',
      sighting.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> updateSighting(CatSighting sighting) async {
    final db = await DatabaseHelper.database;
    await db.update(
      'cat_sightings',
      sighting.toMap(),
      where: 'id = ?',
      whereArgs: [sighting.id],
    );
  }

  /// Deletes a sighting row. Caller must delete the image file first.
  static Future<void> deleteSighting(String id) async {
    final db = await DatabaseHelper.database;
    await db.delete('cat_sightings', where: 'id = ?', whereArgs: [id]);
  }
}
