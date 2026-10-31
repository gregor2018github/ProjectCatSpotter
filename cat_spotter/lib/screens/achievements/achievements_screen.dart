import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../models/achievement.dart';
import '../../providers/achievements_provider.dart';
import '../../widgets/achievement_popup.dart';
import '../../widgets/error_display.dart';
import '../../widgets/loading_indicator.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(achievementsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Trophies')),
      body: async.when(
        loading: () => const LoadingIndicator(message: 'Counting trophies…'),
        error: (e, _) => ErrorDisplay(
          message: e.toString(),
          onRetry: () => ref.invalidate(achievementsProvider),
        ),
        data: (state) => _content(context, state),
      ),
    );
  }

  Widget _content(BuildContext context, AchievementsState state) {
    final items = Achievement.all.toList()
      ..sort((a, b) {
        final ua = state.unlocked[a.id];
        final ub = state.unlocked[b.id];
        // Unlocked first (newest first), then locked by closest to done.
        if (ua != null && ub != null) return ub.compareTo(ua);
        if (ua != null) return -1;
        if (ub != null) return 1;
        final pa = a.progressOf(state.stats) / a.target;
        final pb = b.progressOf(state.stats) / b.target;
        return pb.compareTo(pa);
      });
    final unlockedCount = state.unlocked.keys
        .where((id) => Achievement.all.any((a) => a.id == id))
        .length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      children: [
        _StreakCard(stats: state.stats),
        const SizedBox(height: 14),
        _StatsRow(stats: state.stats),
        const SizedBox(height: 28),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text('Achievements',
                  style: Theme.of(context).textTheme.titleLarge),
            ),
            Text(
              '$unlockedCount / ${Achievement.all.length}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: unlockedCount / Achievement.all.length,
            minHeight: 6,
            backgroundColor: AppColors.surfaceHigh,
            color: AppColors.gold,
          ),
        ),
        const SizedBox(height: 16),
        for (final a in items) ...[
          _AchievementTile(
            achievement: a,
            stats: state.stats,
            unlockedAt: state.unlocked[a.id],
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _StreakCard extends StatelessWidget {
  final SpottingStats stats;
  const _StreakCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final streak = stats.currentStreak;
    final String hint;
    if (streak == 0) {
      hint = 'Spot a cat today to start a streak.';
    } else if (stats.spottedToday) {
      hint = 'You spotted a cat today. Streak is safe!';
    } else {
      hint = 'Spot a cat today to keep it going.';
    }

    final today = DateTime.now();
    final week = [
      for (var i = 6; i >= 0; i--)
        DateTime(today.year, today.month, today.day - i),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4B6B4F), AppColors.forest],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.local_fire_department,
                size: 44,
                color: streak > 0 ? AppColors.gold : Colors.white38,
              ),
              const SizedBox(width: 10),
              Text(
                '$streak',
                style: AppTheme.display(
                  fontSize: 44,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              const Padding(
                padding: EdgeInsets.only(top: 14),
                child: Text(
                  'day streak',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'BEST',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    '${stats.longestStreak} day${stats.longestStreak == 1 ? '' : 's'}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(hint, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final d in week)
                _DayDot(
                  label: DateFormat('E').format(d).substring(0, 1),
                  active: stats.sightingDays.contains(d),
                  isToday: d.day == today.day &&
                      d.month == today.month &&
                      d.year == today.year,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DayDot extends StatelessWidget {
  final String label;
  final bool active;
  final bool isToday;
  const _DayDot(
      {required this.label, required this.active, required this.isToday});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? AppColors.gold : Colors.white.withValues(alpha: 0.12),
            border: isToday
                ? Border.all(color: Colors.white, width: 2)
                : null,
          ),
          child: active
              ? const Icon(Icons.pets, size: 16, color: Colors.white)
              : null,
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: isToday ? Colors.white : Colors.white70,
            fontSize: 12,
            fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  final SpottingStats stats;
  const _StatsRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _stat(Icons.camera_alt_outlined, '${stats.totalSightings}', 'Sightings'),
        const SizedBox(width: 10),
        _stat(Icons.pets, '${stats.totalCats}', 'Cats'),
        const SizedBox(width: 10),
        _stat(Icons.calendar_month_outlined, '${stats.activeDays}',
            'Active days'),
      ],
    );
  }

  Widget _stat(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.walnut, size: 20),
            const SizedBox(height: 6),
            Text(
              value,
              style: AppTheme.display(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  final Achievement achievement;
  final SpottingStats stats;
  final DateTime? unlockedAt;

  const _AchievementTile({
    required this.achievement,
    required this.stats,
    required this.unlockedAt,
  });

  @override
  Widget build(BuildContext context) {
    final a = achievement;
    final unlocked = unlockedAt != null;
    final progress = a.progressOf(stats);

    return Material(
      color: unlocked ? AppColors.surface : AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: unlocked
              ? a.tier.color.withValues(alpha: 0.45)
              : AppColors.divider,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: unlocked ? () => AchievementPopup.show(context, [a]) : null,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              AchievementMedal(achievement: a, size: 52, locked: !unlocked),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a.title,
                      style: AppTheme.display(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: unlocked
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      a.description,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (unlocked)
                      Text(
                        'Unlocked ${DateFormat.yMMMd().format(unlockedAt!)}',
                        style: TextStyle(
                          color: a.tier.color,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: progress / a.target,
                                minHeight: 5,
                                backgroundColor: AppColors.surfaceHigh,
                                color: AppColors.walnut,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '${_fmt(progress, a)} / ${_fmt(a.target, a)}'
                            '${a.unit.isEmpty ? '' : ' ${a.unit}'}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Distances show one decimal; counts are whole numbers.
  static String _fmt(double v, Achievement a) =>
      a.unit.isEmpty ? v.toInt().toString() : v.toStringAsFixed(1);
}
