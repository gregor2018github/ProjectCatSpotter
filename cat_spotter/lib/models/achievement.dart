import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../core/theme.dart';
import 'cat_profile.dart';
import 'cat_sighting.dart';

enum AchievementTier { bronze, silver, gold }

extension AchievementTierColors on AchievementTier {
  Color get color => switch (this) {
        AchievementTier.bronze => AppColors.bronze,
        AchievementTier.silver => AppColors.silver,
        AchievementTier.gold => AppColors.gold,
      };
}

/// A static achievement definition. Whether it is earned is derived from
/// [SpottingStats]; only the unlock timestamp is persisted.
class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final AchievementTier tier;
  final double target;

  /// Unit shown after progress numbers, e.g. "km". Empty for plain counts.
  final String unit;
  final double Function(SpottingStats s) _progress;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.tier,
    required this.target,
    required double Function(SpottingStats s) progress,
    this.unit = '',
  }) : _progress = progress;

  double progressOf(SpottingStats s) => _progress(s).clamp(0, target);
  bool isEarned(SpottingStats s) => _progress(s) >= target;

  static final List<Achievement> all = [
    // Total sightings
    Achievement(
      id: 'sightings_1',
      title: 'First Spot',
      description: 'Record your very first cat sighting.',
      icon: Icons.visibility_outlined,
      tier: AchievementTier.bronze,
      target: 1,
      progress: (s) => s.totalSightings.toDouble(),
    ),
    Achievement(
      id: 'sightings_10',
      title: 'Keen Eye',
      description: 'Record 10 sightings.',
      icon: Icons.remove_red_eye,
      tier: AchievementTier.bronze,
      target: 10,
      progress: (s) => s.totalSightings.toDouble(),
    ),
    Achievement(
      id: 'sightings_25',
      title: 'Cat Whisperer',
      description: 'Record 25 sightings.',
      icon: Icons.record_voice_over_outlined,
      tier: AchievementTier.silver,
      target: 25,
      progress: (s) => s.totalSightings.toDouble(),
    ),
    Achievement(
      id: 'sightings_50',
      title: 'Neighbourhood Watch',
      description: 'Record 50 sightings.',
      icon: Icons.holiday_village_outlined,
      tier: AchievementTier.silver,
      target: 50,
      progress: (s) => s.totalSightings.toDouble(),
    ),
    Achievement(
      id: 'sightings_100',
      title: 'Legendary Spotter',
      description: 'Record 100 sightings.',
      icon: Icons.workspace_premium_outlined,
      tier: AchievementTier.gold,
      target: 100,
      progress: (s) => s.totalSightings.toDouble(),
    ),

    // Cat profiles
    Achievement(
      id: 'cats_3',
      title: 'Small Clowder',
      description: 'Get to know 3 different cats.',
      icon: Icons.pets,
      tier: AchievementTier.bronze,
      target: 3,
      progress: (s) => s.totalCats.toDouble(),
    ),
    Achievement(
      id: 'cats_10',
      title: 'Cat Census',
      description: 'Get to know 10 different cats.',
      icon: Icons.groups_outlined,
      tier: AchievementTier.gold,
      target: 10,
      progress: (s) => s.totalCats.toDouble(),
    ),

    // Streaks
    Achievement(
      id: 'streak_3',
      title: 'On a Roll',
      description: 'Spot cats 3 days in a row.',
      icon: Icons.local_fire_department_outlined,
      tier: AchievementTier.bronze,
      target: 3,
      progress: (s) => s.longestStreak.toDouble(),
    ),
    Achievement(
      id: 'streak_7',
      title: 'Week of Whiskers',
      description: 'Spot cats 7 days in a row.',
      icon: Icons.local_fire_department,
      tier: AchievementTier.silver,
      target: 7,
      progress: (s) => s.longestStreak.toDouble(),
    ),
    Achievement(
      id: 'streak_30',
      title: 'Purrsistent',
      description: 'Spot cats 30 days in a row.',
      icon: Icons.whatshot,
      tier: AchievementTier.gold,
      target: 30,
      progress: (s) => s.longestStreak.toDouble(),
    ),

    // Loyalty to one cat
    Achievement(
      id: 'loyal_5',
      title: 'Old Friends',
      description: 'Spot the same cat 5 times.',
      icon: Icons.favorite_border,
      tier: AchievementTier.bronze,
      target: 5,
      progress: (s) => s.maxSightingsOneCat.toDouble(),
    ),
    Achievement(
      id: 'loyal_20',
      title: 'Best Friends',
      description: 'Spot the same cat 20 times.',
      icon: Icons.favorite,
      tier: AchievementTier.silver,
      target: 20,
      progress: (s) => s.maxSightingsOneCat.toDouble(),
    ),

    // Single-day and time-of-day
    Achievement(
      id: 'busy_day_3',
      title: 'Cat Parade',
      description: 'Record 3 sightings in a single day.',
      icon: Icons.celebration_outlined,
      tier: AchievementTier.silver,
      target: 3,
      progress: (s) => s.maxSightingsOneDay.toDouble(),
    ),
    Achievement(
      id: 'early_bird',
      title: 'Early Bird',
      description: 'Spot a cat between 5 and 8 in the morning.',
      icon: Icons.wb_twilight,
      tier: AchievementTier.bronze,
      target: 1,
      progress: (s) => s.earlyBirdSightings.toDouble(),
    ),
    Achievement(
      id: 'night_owl',
      title: 'Night Owl',
      description: 'Spot a cat between 10 at night and 5 in the morning.',
      icon: Icons.nightlight_outlined,
      tier: AchievementTier.bronze,
      target: 1,
      progress: (s) => s.nightOwlSightings.toDouble(),
    ),

    // Distance between sightings
    Achievement(
      id: 'explorer_1km',
      title: 'Wanderer',
      description: 'Spot cats at least 1 km apart.',
      icon: Icons.hiking,
      tier: AchievementTier.bronze,
      target: 1,
      unit: 'km',
      progress: (s) => s.maxSpreadKm,
    ),
    Achievement(
      id: 'explorer_500km',
      title: 'Globetrotter',
      description: 'Spot cats at least 500 km apart.',
      icon: Icons.public,
      tier: AchievementTier.gold,
      target: 500,
      unit: 'km',
      progress: (s) => s.maxSpreadKm,
    ),
  ];
}

/// Aggregate stats derived from all profiles and sightings.
class SpottingStats {
  final int totalSightings;
  final int totalCats;
  final int activeDays;
  final int currentStreak;
  final int longestStreak;
  final int maxSightingsOneCat;
  final int maxSightingsOneDay;
  final int earlyBirdSightings;
  final int nightOwlSightings;
  final double maxSpreadKm;

  /// Local calendar days (midnight) on which at least one sighting happened.
  final Set<DateTime> sightingDays;

  const SpottingStats({
    required this.totalSightings,
    required this.totalCats,
    required this.activeDays,
    required this.currentStreak,
    required this.longestStreak,
    required this.maxSightingsOneCat,
    required this.maxSightingsOneDay,
    required this.earlyBirdSightings,
    required this.nightOwlSightings,
    required this.maxSpreadKm,
    required this.sightingDays,
  });

  bool get spottedToday => sightingDays.contains(_day(DateTime.now()));

  factory SpottingStats.compute(
    List<CatProfile> profiles,
    List<CatSighting> sightings, {
    DateTime? now,
  }) {
    final today = _day(now ?? DateTime.now());

    final perCat = <String, int>{};
    final perDay = <DateTime, int>{};
    var early = 0;
    var night = 0;
    for (final s in sightings) {
      final t = s.capturedAt.toLocal();
      perCat[s.catProfileId] = (perCat[s.catProfileId] ?? 0) + 1;
      final d = _day(t);
      perDay[d] = (perDay[d] ?? 0) + 1;
      if (t.hour >= 5 && t.hour < 8) early++;
      if (t.hour >= 22 || t.hour < 5) night++;
    }

    final days = perDay.keys.toSet();

    // Longest run of consecutive days.
    final sorted = days.toList()..sort();
    var longest = 0;
    var run = 0;
    DateTime? prev;
    for (final d in sorted) {
      run = (prev != null && _daysBetween(prev, d) == 1) ? run + 1 : 1;
      if (run > longest) longest = run;
      prev = d;
    }

    // Current streak stays alive until a full day is missed: counting starts
    // from today if there was a sighting today, otherwise from yesterday.
    var current = 0;
    var cursor = days.contains(today) ? today : _addDays(today, -1);
    while (days.contains(cursor)) {
      current++;
      cursor = _addDays(cursor, -1);
    }

    // Largest distance between any two sightings (n is small, O(n²) is fine).
    const distance = Distance();
    var spread = 0.0;
    for (var i = 0; i < sightings.length; i++) {
      for (var j = i + 1; j < sightings.length; j++) {
        final m = distance(sightings[i].latLng, sightings[j].latLng);
        if (m > spread) spread = m;
      }
    }

    return SpottingStats(
      totalSightings: sightings.length,
      totalCats: profiles.length,
      activeDays: days.length,
      currentStreak: current,
      longestStreak: longest,
      maxSightingsOneCat:
          perCat.values.fold(0, (a, b) => a > b ? a : b),
      maxSightingsOneDay:
          perDay.values.fold(0, (a, b) => a > b ? a : b),
      earlyBirdSightings: early,
      nightOwlSightings: night,
      maxSpreadKm: spread / 1000,
      sightingDays: days,
    );
  }

  static DateTime _day(DateTime t) => DateTime(t.year, t.month, t.day);

  // Calendar arithmetic (not Duration) so DST changes don't skew day counts.
  static DateTime _addDays(DateTime d, int n) =>
      DateTime(d.year, d.month, d.day + n);

  static int _daysBetween(DateTime a, DateTime b) =>
      DateTime.utc(b.year, b.month, b.day)
          .difference(DateTime.utc(a.year, a.month, a.day))
          .inDays;
}
