import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../models/cat_profile.dart';
import '../../providers/add_sighting_provider.dart';
import '../../providers/cat_profiles_provider.dart';
import '../../widgets/local_image.dart';
import '../cat_form/cat_form_screen.dart';

class Step2AssignCat extends ConsumerWidget {
  final VoidCallback onNext;
  const Step2AssignCat({super.key, required this.onNext});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(addSightingProvider);
    final profilesAsync = ref.watch(catProfilesProvider);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Which cat is this?',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            'Select an existing profile or create a new one.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),

          // Cat list
          Expanded(
            child: profilesAsync.when(
              data: (profiles) => _catList(context, ref, profiles, state),
              loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.accent)),
              error: (e, _) => Text(e.toString()),
            ),
          ),

          const SizedBox(height: 16),

          // Next button
          ElevatedButton.icon(
            onPressed: state.hasCat ? onNext : null,
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Next: Fine-tune Location'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _catList(BuildContext context, WidgetRef ref,
      List<CatProfile> profiles, AddSightingState state) {
    return ListView(
      children: [
        ...profiles.map((p) {
          final selected = state.selectedCat?.id == p.id;
          return _CatTile(
            profile: p,
            selected: selected,
            onTap: () =>
                ref.read(addSightingProvider.notifier).setSelectedCat(p),
          );
        }),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _createNewCat(context, ref),
          icon: const Icon(Icons.add),
          label: const Text('Create New Cat'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
        ),
      ],
    );
  }

  Future<void> _createNewCat(BuildContext context, WidgetRef ref) async {
    // Pass the sighting image so the cat form can pre-populate the cover photo.
    final sightingImage = ref.read(addSightingProvider).capturedImage;
    final newProfile = await Navigator.push<CatProfile>(
      context,
      MaterialPageRoute(
        builder: (_) => CatFormScreen(initialCoverFile: sightingImage),
        fullscreenDialog: true,
      ),
    );
    if (newProfile != null) {
      ref.read(addSightingProvider.notifier).setSelectedCat(newProfile);
    }
  }
}

class _CatTile extends StatelessWidget {
  final CatProfile profile;
  final bool selected;
  final VoidCallback onTap;

  const _CatTile({
    required this.profile,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accent.withValues(alpha: 0.12)
              : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.divider,
            width: selected ? 2 : 1,
          ),
        ),
        child: ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 48,
              height: 48,
              child: LocalImage(
                relativePath: profile.coverImagePath,
                fit: BoxFit.cover,
              ),
            ),
          ),
          title: Text(
            profile.name,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color:
                      selected ? AppColors.accent : AppColors.textPrimary,
                ),
          ),
          subtitle: Text(
            '${profile.sightingCount} sighting${profile.sightingCount == 1 ? '' : 's'}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          trailing: selected
              ? const Icon(Icons.check_circle, color: AppColors.accent)
              : null,
        ),
      ),
    );
  }
}
