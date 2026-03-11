import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../models/cat_profile.dart';
import '../../providers/cat_profiles_provider.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/error_display.dart';
import '../../widgets/loading_indicator.dart';
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
            Icon(Icons.pets, color: AppColors.accent),
            SizedBox(width: 8),
            Text('Cat Spotter'),
          ],
        ),
        actions: [
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddSighting(context),
        tooltip: 'Add sighting',
        child: const Icon(Icons.camera_alt),
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
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.78,
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
