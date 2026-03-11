import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/cat_profile_dao.dart';
import '../data/cat_sighting_dao.dart';
import '../models/cat_profile.dart';
import '../services/image_storage_service.dart';

class CatProfilesNotifier extends AsyncNotifier<List<CatProfile>> {
  @override
  Future<List<CatProfile>> build() => CatProfileDao.getAllProfiles();

  Future<void> addProfile(CatProfile profile) async {
    await CatProfileDao.insertProfile(profile);
    ref.invalidateSelf();
  }

  Future<void> updateProfile(CatProfile profile) async {
    await CatProfileDao.updateProfile(profile);
    ref.invalidateSelf();
  }

  /// Deletes a profile and cleans up all associated image files on disk.
  Future<void> deleteProfile(String id, {String? coverImagePath}) async {
    // 1. Collect sighting image paths before CASCADE delete removes them.
    final sightings = await CatSightingDao.getSightingsForCat(id);

    // 2. Delete the profile (CASCADE removes sighting rows from DB).
    await CatProfileDao.deleteProfile(id);

    // 3. Delete image files from disk.
    for (final s in sightings) {
      await ImageStorageService.deleteImage(s.imagePath);
    }
    if (coverImagePath != null) {
      await ImageStorageService.deleteImage(coverImagePath);
    }

    ref.invalidateSelf();
  }
}

final catProfilesProvider =
    AsyncNotifierProvider<CatProfilesNotifier, List<CatProfile>>(
  CatProfilesNotifier.new,
);
