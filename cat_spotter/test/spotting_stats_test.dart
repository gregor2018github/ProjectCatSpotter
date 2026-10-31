import 'package:cat_spotter/models/achievement.dart';
import 'package:cat_spotter/models/cat_sighting.dart';
import 'package:flutter_test/flutter_test.dart';

CatSighting _s(DateTime t, {String cat = 'a', double lat = 52.0}) =>
    CatSighting(
      catProfileId: cat,
      imagePath: 'x.jpg',
      latitude: lat,
      longitude: 13.0,
      capturedAt: t,
    );

void main() {
  final now = DateTime(2026, 10, 31, 12);

  test('streak counts consecutive days ending today', () {
    final s = SpottingStats.compute([], [
      _s(DateTime(2026, 10, 31, 9)),
      _s(DateTime(2026, 10, 30, 23)),
      _s(DateTime(2026, 10, 29, 6)),
      _s(DateTime(2026, 10, 27, 10)),
    ], now: now);
    expect(s.currentStreak, 3);
    expect(s.longestStreak, 3);
    expect(s.activeDays, 4);
  });

  test('streak stays alive until a full day is missed', () {
    final s = SpottingStats.compute([], [
      _s(DateTime(2026, 10, 30, 9)),
      _s(DateTime(2026, 10, 29, 9)),
    ], now: now);
    expect(s.currentStreak, 2);

    final broken = SpottingStats.compute([], [
      _s(DateTime(2026, 10, 29, 9)),
    ], now: now);
    expect(broken.currentStreak, 0);
    expect(broken.longestStreak, 1);
  });

  test('streak crosses month boundary and DST change', () {
    final s = SpottingStats.compute([], [
      _s(DateTime(2026, 11, 1, 9)),
      _s(DateTime(2026, 10, 31, 9)),
      _s(DateTime(2026, 10, 25, 9)), // EU DST ends
      _s(DateTime(2026, 10, 24, 9)),
      _s(DateTime(2026, 10, 26, 9)),
    ], now: DateTime(2026, 11, 1, 20));
    expect(s.currentStreak, 2);
    expect(s.longestStreak, 3);
  });

  test('time-of-day, per-cat, per-day and distance stats', () {
    final s = SpottingStats.compute([], [
      _s(DateTime(2026, 10, 31, 6), cat: 'a'),
      _s(DateTime(2026, 10, 31, 23), cat: 'a'),
      _s(DateTime(2026, 10, 31, 2), cat: 'b', lat: 52.02),
    ], now: now);
    expect(s.earlyBirdSightings, 1);
    expect(s.nightOwlSightings, 2);
    expect(s.maxSightingsOneCat, 2);
    expect(s.maxSightingsOneDay, 3);
    expect(s.maxSpreadKm, closeTo(2.2, 0.1));
  });

  test('achievement ids are unique', () {
    final ids = Achievement.all.map((a) => a.id).toList();
    expect(ids.toSet().length, ids.length);
  });
}
