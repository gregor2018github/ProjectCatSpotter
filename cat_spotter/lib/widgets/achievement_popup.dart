import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../models/achievement.dart';
import '../providers/achievements_provider.dart';

/// Wraps the app and pops up an info box whenever achievements unlock.
/// Sits above the Navigator (via MaterialApp.builder), so dialogs are shown
/// through [navigatorKey].
class AchievementListener extends ConsumerStatefulWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  const AchievementListener({
    super.key,
    required this.navigatorKey,
    required this.child,
  });

  @override
  ConsumerState<AchievementListener> createState() =>
      _AchievementListenerState();
}

class _AchievementListenerState extends ConsumerState<AchievementListener> {
  final List<Achievement> _queue = [];
  bool _showing = false;

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<AchievementsState>>(achievementsProvider, (_, next) {
      final newly = next.valueOrNull?.newlyUnlocked ?? const [];
      if (newly.isEmpty) return;
      _queue.addAll(newly);
      // Short delay lets route transitions (e.g. closing the add-sighting
      // wizard) settle before the popup appears.
      Future.delayed(const Duration(milliseconds: 450), _showNext);
    });
    return widget.child;
  }

  Future<void> _showNext() async {
    if (_showing || _queue.isEmpty) return;
    final ctx = widget.navigatorKey.currentContext;
    if (ctx == null) return;

    final batch = List<Achievement>.of(_queue);
    _queue.clear();
    _showing = true;
    await AchievementPopup.show(ctx, batch);
    _showing = false;
    if (_queue.isNotEmpty) _showNext();
  }
}

class AchievementPopup extends StatelessWidget {
  final List<Achievement> achievements;

  const AchievementPopup({super.key, required this.achievements});

  static Future<void> show(BuildContext context, List<Achievement> items) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close',
      barrierColor: Colors.black.withValues(alpha: 0.45),
      transitionDuration: const Duration(milliseconds: 380),
      pageBuilder: (_, __, ___) => AchievementPopup(achievements: items),
      transitionBuilder: (_, anim, __, child) {
        final curved =
            CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
        return FadeTransition(
          opacity: anim,
          child: ScaleTransition(scale: curved, child: child),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final single = achievements.length == 1;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Material(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(28),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 360,
              maxHeight: MediaQuery.sizeOf(context).height * 0.75,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'ACHIEVEMENT${single ? '' : 'S'} UNLOCKED',
                    style: const TextStyle(
                      color: AppColors.forest,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.6,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (single)
                    _singleBody(achievements.first)
                  else
                    Flexible(child: _multiBody()),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Nice!'),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tap anywhere to close',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _singleBody(Achievement a) {
    return Column(
      children: [
        AchievementMedal(achievement: a, size: 104),
        const SizedBox(height: 18),
        Text(
          a.title,
          textAlign: TextAlign.center,
          style: AppTheme.display(fontSize: 26, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          a.description,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
        ),
        const SizedBox(height: 14),
        TierChip(tier: a.tier),
      ],
    );
  }

  Widget _multiBody() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${achievements.length} new achievements!',
          style: AppTheme.display(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        Flexible(
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: achievements.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final a = achievements[i];
              return Row(
                children: [
                  AchievementMedal(achievement: a, size: 48),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          a.title,
                          style: AppTheme.display(
                              fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          a.description,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Circular medal in the achievement's tier colour. Greyed out when locked.
class AchievementMedal extends StatelessWidget {
  final Achievement achievement;
  final double size;
  final bool locked;

  const AchievementMedal({
    super.key,
    required this.achievement,
    this.size = 56,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    final base = locked ? AppColors.cardBorder : achievement.tier.color;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.lerp(base, Colors.white, 0.25)!, base],
        ),
        border: Border.all(
          color: locked
              ? AppColors.divider
              : Color.lerp(base, Colors.white, 0.55)!,
          width: size * 0.05,
        ),
        boxShadow: locked
            ? null
            : [
                BoxShadow(
                  color: base.withValues(alpha: 0.35),
                  blurRadius: size * 0.18,
                  offset: Offset(0, size * 0.06),
                ),
              ],
      ),
      child: Icon(
        locked ? Icons.lock_outline : achievement.icon,
        color: locked ? AppColors.textSecondary : Colors.white,
        size: size * 0.46,
      ),
    );
  }
}

class TierChip extends StatelessWidget {
  final AchievementTier tier;
  const TierChip({super.key, required this.tier});

  @override
  Widget build(BuildContext context) {
    final label = switch (tier) {
      AchievementTier.bronze => 'Bronze',
      AchievementTier.silver => 'Silver',
      AchievementTier.gold => 'Gold',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: tier.color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: tier.color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
