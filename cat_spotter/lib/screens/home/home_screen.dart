import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../models/cat_profile.dart';
import '../../providers/achievements_provider.dart';
import '../../providers/cat_profiles_provider.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/error_display.dart';
import '../../widgets/loading_indicator.dart';
import '../achievements/achievements_screen.dart';
import '../add_sighting/add_sighting_screen.dart';
import '../all_cats_map/all_cats_map_screen.dart';
import '../cat_detail/cat_detail_screen.dart';
import '../cat_form/cat_form_screen.dart';
import 'cat_profile_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilesAsync = ref.watch(catProfilesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.pets, color: AppColors.accent, size: 22),
            SizedBox(width: 10),
            Text('Cat Spotter'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.emoji_events_outlined),
            tooltip: 'Trophies',
            onPressed: () => _openAchievements(context),
          ),
          IconButton(
            icon: const Icon(Icons.map_outlined),
            tooltip: 'All cats map',
            onPressed: () => _openAllCatsMap(context),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add cat profile',
            onPressed: () => _openAddCat(context),
          ),
        ],
      ),
      body: profilesAsync.when(
        data: (profiles) => profiles.isEmpty
            ? _emptyState(context)
            : _grid(context, ref, profiles),
        loading: () => const LoadingIndicator(message: 'Loading cats…'),
        error: (e, _) =>
            ErrorDisplay(message: e.toString(), onRetry: () => ref.invalidate(catProfilesProvider)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddSighting(context),
        tooltip: 'Add sighting',
        icon: const Icon(Icons.camera_alt_outlined),
        label: const Text('Spot a cat'),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.pets, size: 80, color: AppColors.accent),
            const SizedBox(height: 24),
            Text(
              'No cats spotted yet!',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Tap + to add a cat profile, then use the camera button to record sightings.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _grid(
      BuildContext context, WidgetRef ref, List<CatProfile> profiles) {
    final totalSightings =
        profiles.fold<int>(0, (sum, p) => sum + p.sightingCount);
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${profiles.length} cat${profiles.length == 1 ? '' : 's'} · '
                    '$totalSightings sighting${totalSightings == 1 ? '' : 's'}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                _streakBadge(context, ref),
              ],
            ),
          ),
        ),
        SliverPadding(
          // Bottom padding keeps the last row clear of the FAB.
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
          sliver: SliverGrid.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 0.8,
            ),
            itemCount: profiles.length,
            itemBuilder: (context, index) {
              final profile = profiles[index];
              return CatProfileCard(
                profile: profile,
                onTap: () => _openDetail(context, profile),
                onEdit: () => _openEditCat(context, profile),
                onDelete: () => _confirmDelete(context, ref, profile),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _streakBadge(BuildContext context, WidgetRef ref) {
    final streak =
        ref.watch(achievementsProvider).valueOrNull?.stats.currentStreak ?? 0;
    final active = streak > 0;
    return Material(
      color: active ? AppColors.accentLight : AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _openAchievements(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.local_fire_department,
                size: 16,
                color: active ? AppColors.accent : AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                active ? '$streak-day streak' : 'No streak',
                style: TextStyle(
                  color: active ? AppColors.accent : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openAchievements(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AchievementsScreen()),
    );
  }

  void _openDetail(BuildContext context, CatProfile profile) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => CatDetailScreen(catProfileId: profile.id)),
    );
  }

  void _openAllCatsMap(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AllCatsMapScreen()),
    );
  }

  void _openAddCat(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CatFormScreen()),
    );
  }

  void _openEditCat(BuildContext context, CatProfile profile) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CatFormScreen(existing: profile)),
    );
  }

  void _openAddSighting(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddSightingScreen()),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, CatProfile profile) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Delete ${profile.name}?',
      message:
          'This will permanently delete the cat profile and all ${profile.sightingCount} sighting${profile.sightingCount == 1 ? '' : 's'}, including photos.',
    );
    if (confirmed && context.mounted) {
      await ref
          .read(catProfilesProvider.notifier)
          .deleteProfile(profile.id, coverImagePath: profile.coverImagePath);
    }
  }
}
