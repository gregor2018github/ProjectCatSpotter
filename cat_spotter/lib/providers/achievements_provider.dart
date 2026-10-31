import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/achievement_dao.dart';
import '../models/achievement.dart';
import 'cat_profiles_provider.dart';
import 'cat_sightings_provider.dart';

class AchievementsState {
  final SpottingStats stats;

  /// Achievement id → unlock time, for every unlocked achievement.
  final Map<String, DateTime> unlocked;

  /// Achievements unlocked by the most recent recompute (for the popup).
  final List<Achievement> newlyUnlocked;

  const AchievementsState({
    required this.stats,
    required this.unlocked,
    required this.newlyUnlocked,
  });
}

/// Recomputes whenever profiles or sightings change. Newly earned
/// achievements are persisted here, so each one is reported exactly once.
final achievementsProvider = FutureProvider<AchievementsState>((ref) async {
  final profiles = await ref.watch(catProfilesProvider.future);
  final sightings = await ref.watch(allCatSightingsProvider.future);
  final stats = SpottingStats.compute(profiles, sightings);

  final unlocked = await AchievementDao.getUnlocked();
  final newly = Achievement.all
      .where((a) => !unlocked.containsKey(a.id) && a.isEarned(stats))
      .toList();

  if (newly.isNotEmpty) {
    final now = DateTime.now();
    await AchievementDao.markUnlocked(newly.map((a) => a.id), now);
    for (final a in newly) {
      unlocked[a.id] = now;
    }
  }

  return AchievementsState(
    stats: stats,
    unlocked: unlocked,
    newlyUnlocked: newly,
  );
});
