import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/cat_sighting_dao.dart';
import '../models/cat_sighting.dart';
import '../services/image_storage_service.dart';
import 'cat_profiles_provider.dart';

/// Family provider — pass catProfileId as argument.
final catSightingsProvider = FutureProvider.autoDispose
    .family<List<CatSighting>, String>((ref, catProfileId) async {
  return CatSightingDao.getSightingsForCat(catProfileId);
});

/// All sightings across every cat profile (for the global map).
final allCatSightingsProvider =
    FutureProvider<List<CatSighting>>((ref) async {
  return CatSightingDao.getAllSightings();
});

/// Deletes a sighting (image file + DB row) and refreshes both sightings
/// and profiles providers.
Future<void> deleteSighting(WidgetRef ref, CatSighting sighting) async {
  await ImageStorageService.deleteImage(sighting.imagePath);
  await CatSightingDao.deleteSighting(sighting.id);
  ref.invalidate(catSightingsProvider(sighting.catProfileId));
  ref.invalidate(allCatSightingsProvider);
  ref.invalidate(catProfilesProvider);
}
