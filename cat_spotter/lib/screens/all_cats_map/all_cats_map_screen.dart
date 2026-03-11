import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/cat_profile.dart';
import '../../models/cat_sighting.dart';
import '../../providers/cat_profiles_provider.dart';
import '../../providers/cat_sightings_provider.dart';
import '../../widgets/error_display.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/local_image.dart';

class AllCatsMapScreen extends ConsumerWidget {
  const AllCatsMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilesAsync = ref.watch(catProfilesProvider);
    final sightingsAsync = ref.watch(allCatSightingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.map, color: AppColors.accent),
            SizedBox(width: 8),
            Text('All Cats Map'),
          ],
        ),
      ),
      body: profilesAsync.when(
        data: (profiles) => sightingsAsync.when(
          data: (sightings) =>
              _MapView(profiles: profiles, sightings: sightings),
          loading: () => const LoadingIndicator(),
          error: (e, _) => ErrorDisplay(message: e.toString()),
        ),
        loading: () => const LoadingIndicator(),
        error: (e, _) => ErrorDisplay(message: e.toString()),
      ),
    );
  }
}

// ─── Stateful inner widget holds selected-marker state ───────────────────────

class _MapView extends StatefulWidget {
  final List<CatProfile> profiles;
  final List<CatSighting> sightings;

  const _MapView({required this.profiles, required this.sightings});

  @override
  State<_MapView> createState() => _MapViewState();
}

class _MapViewState extends State<_MapView> {
  CatSighting? _selected;

  // Fast lookup: catProfileId → CatProfile
  late final Map<String, CatProfile> _profileMap;

  @override
  void initState() {
    super.initState();
    _profileMap = {for (final p in widget.profiles) p.id: p};
  }

  @override
  Widget build(BuildContext context) {
    if (widget.sightings.isEmpty) {
      return const Center(
        child: Text(
          'No sightings recorded yet.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    final points = widget.sightings.map((s) => s.latLng).toList();
    final cameraFit = points.length > 1
        ? CameraFit.bounds(
            bounds: LatLngBounds.fromPoints(points),
            padding: const EdgeInsets.all(60),
          )
        : null;

    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            initialCenter:
                points.length == 1 ? points.first : _centroid(points),
            initialZoom: 13,
            initialCameraFit: cameraFit,
            onTap: (_, __) => setState(() => _selected = null),
          ),
          children: [
            TileLayer(
              urlTemplate: AppConstants.osmTileUrl,
              userAgentPackageName: AppConstants.osmUserAgent,
            ),
            MarkerLayer(
              markers: widget.sightings.map((s) {
                final profile = _profileMap[s.catProfileId];
                final markerColor = profile != null
                    ? Color(profile.color)
                    : AppColors.accent;
                final isSelected = _selected?.id == s.id;

                return Marker(
                  point: s.latLng,
                  width: 36,
                  height: 36,
                  child: GestureDetector(
                    onTap: () => setState(() => _selected = s),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white
                            : markerColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? markerColor : Colors.white,
                          width: 2.5,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.pets,
                        color: isSelected ? markerColor : Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),

        // Legend — bottom-left corner, only when no marker is selected
        if (_selected == null)
          Positioned(
            left: 12,
            bottom: 12,
            child: _Legend(profiles: widget.profiles),
          ),

        // Sighting detail panel slides in when a marker is tapped
        if (_selected != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _sightingPanel(context, _selected!),
          ),
      ],
    );
  }

  Widget _sightingPanel(BuildContext context, CatSighting sighting) {
    final profile = _profileMap[sighting.catProfileId];
    final markerColor =
        profile != null ? Color(profile.color) : AppColors.accent;

    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Photo thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 72,
                height: 72,
                child: LocalImage(
                  relativePath: sighting.imagePath,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Cat name with colour dot
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: markerColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        profile?.name ?? 'Unknown cat',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: markerColor,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMM d, y  h:mm a').format(sighting.capturedAt),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Row(
                    children: [
                      const Icon(Icons.place,
                          size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 3),
                      Text(
                        '${sighting.latitude.toStringAsFixed(4)}, '
                        '${sighting.longitude.toStringAsFixed(4)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  if (sighting.notes != null && sighting.notes!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        sighting.notes!,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: () => setState(() => _selected = null),
            ),
          ],
        ),
      ),
    );
  }

  LatLng _centroid(List<LatLng> pts) {
    final lat =
        pts.map((p) => p.latitude).reduce((a, b) => a + b) / pts.length;
    final lng =
        pts.map((p) => p.longitude).reduce((a, b) => a + b) / pts.length;
    return LatLng(lat, lng);
  }
}

// ─── Legend widget ─────────────────────────────────────────────────────────

class _Legend extends StatelessWidget {
  final List<CatProfile> profiles;

  const _Legend({required this.profiles});

  @override
  Widget build(BuildContext context) {
    // Only show profiles that actually have sightings (sightingCount > 0)
    final visible = profiles.where((p) => p.sightingCount > 0).toList();
    if (visible.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: visible.map((p) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Color(p.color),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  p.name,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(width: 4),
                Text(
                  '(${p.sightingCount})',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
