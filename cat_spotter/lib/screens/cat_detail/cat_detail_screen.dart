import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../data/cat_profile_dao.dart';
import '../../models/cat_profile.dart';
import '../../models/cat_sighting.dart';
import '../../providers/cat_profiles_provider.dart';
import '../../providers/cat_sightings_provider.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/error_display.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/local_image.dart';
import '../add_sighting/add_sighting_screen.dart';
import '../cat_form/cat_form_screen.dart';
import '../distribution_map/distribution_map_screen.dart';
import 'mini_map_widget.dart';
import 'sighting_thumbnail.dart';

class CatDetailScreen extends ConsumerWidget {
  final String catProfileId;

  const CatDetailScreen({super.key, required this.catProfileId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sightingsAsync = ref.watch(catSightingsProvider(catProfileId));

    return Scaffold(
      body: sightingsAsync.when(
        data: (sightings) => _buildWithProfile(context, ref, sightings),
        loading: () => const Scaffold(body: LoadingIndicator()),
        error: (e, _) =>
            Scaffold(body: ErrorDisplay(message: e.toString())),
      ),
    );
  }

  Widget _buildWithProfile(
      BuildContext context, WidgetRef ref, List<CatSighting> sightings) {
    return FutureBuilder<CatProfile?>(
      future: CatProfileDao.getProfileById(catProfileId),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(body: LoadingIndicator());
        }
        final profile = snap.data;
        if (profile == null) {
          return const Scaffold(
              body: Center(child: Text('Cat not found')));
        }
        return _body(context, ref, profile, sightings);
      },
    );
  }

  Scaffold _body(BuildContext context, WidgetRef ref, CatProfile profile,
      List<CatSighting> sightings) {
    final firstSeen = sightings.isNotEmpty
        ? DateFormat('MMM d, y').format(sightings.last.capturedAt)
        : null;
    final lastSeen = sightings.isNotEmpty
        ? DateFormat('MMM d, y').format(sightings.first.capturedAt)
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(profile.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => CatFormScreen(existing: profile)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            onPressed: () => _confirmDelete(context, ref, profile),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                AddSightingScreen(preselectedCat: profile),
          ),
        ),
        tooltip: 'Add sighting',
        child: const Icon(Icons.camera_alt),
      ),
      body: CustomScrollView(
        slivers: [
          // Cover photo header
          SliverToBoxAdapter(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(20)),
              child: SizedBox(
                height: 220,
                child: LocalImage(
                  relativePath: profile.coverImagePath,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          // Stats row
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (profile.notes != null && profile.notes!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        profile.notes!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: AppColors.textSecondary),
                      ),
                    ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _statChip(context, Icons.place,
                          '${sightings.length} sighting${sightings.length == 1 ? '' : 's'}'),
                      if (firstSeen != null)
                        _statChip(context, Icons.calendar_today,
                            'First: $firstSeen'),
                      if (lastSeen != null && lastSeen != firstSeen)
                        _statChip(context, Icons.update, 'Last: $lastSeen'),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Mini map
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sighting Map',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 10),
                  MiniMapWidget(
                    sightings: sightings,
                    onViewFull: sightings.isEmpty
                        ? null
                        : () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DistributionMapScreen(
                                    catProfileId: catProfileId,
                                    catName: profile.name),
                              ),
                            ),
                  ),
                ],
              ),
            ),
          ),

          // Sightings header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
              child: Text(
                'Photos',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),

          // Photo grid
          if (sightings.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'No photos yet. Add a sighting!',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final s = sightings[index];
                    return SightingThumbnail(
                      sighting: s,
                      onTap: () => _openSightingView(context, s),
                      onDelete: () => _confirmDeleteSighting(context, ref, s),
                    );
                  },
                  childCount: sightings.length,
                ),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _statChip(BuildContext context, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.accent),
          const SizedBox(width: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  void _openSightingView(BuildContext context, CatSighting sighting) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => _SightingViewScreen(sighting: sighting)),
    );
  }

  Future<void> _confirmDeleteSighting(
      BuildContext context, WidgetRef ref, CatSighting sighting) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Delete sighting?',
      message: 'This will permanently delete the photo and location data.',
    );
    if (confirmed && context.mounted) {
      await deleteSighting(ref, sighting);
    }
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, CatProfile profile) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Delete ${profile.name}?',
      message:
          'This will permanently delete the cat and all sightings and photos.',
    );
    if (confirmed && context.mounted) {
      await ref
          .read(catProfilesProvider.notifier)
          .deleteProfile(profile.id, coverImagePath: profile.coverImagePath);
      if (context.mounted) Navigator.pop(context);
    }
  }
}

// ---------------------------------------------------------------------------
// Simple full-screen photo viewer
// ---------------------------------------------------------------------------
class _SightingViewScreen extends StatelessWidget {
  final CatSighting sighting;
  const _SightingViewScreen({required this.sighting});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          DateFormat('MMM d, y  h:mm a').format(sighting.capturedAt),
          style: const TextStyle(color: Colors.white, fontSize: 15),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: InteractiveViewer(
              child: Center(
                child: LocalImage(
                  relativePath: sighting.imagePath,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.black87,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.place, color: AppColors.accent, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      '${sighting.latitude.toStringAsFixed(5)}, ${sighting.longitude.toStringAsFixed(5)}',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    if (sighting.locationFineTuned) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Fine-tuned',
                          style:
                              TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ),
                    ],
                  ],
                ),
                if (sighting.accuracy != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Accuracy: ±${sighting.accuracy!.toStringAsFixed(0)} m',
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 12),
                    ),
                  ),
                if (sighting.notes != null && sighting.notes!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      sighting.notes!,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
