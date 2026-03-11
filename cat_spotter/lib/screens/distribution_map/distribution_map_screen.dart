import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/cat_sighting.dart';
import '../../providers/cat_sightings_provider.dart';
import '../../widgets/error_display.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/local_image.dart';

class DistributionMapScreen extends ConsumerStatefulWidget {
  final String catProfileId;
  final String catName;

  const DistributionMapScreen({
    super.key,
    required this.catProfileId,
    required this.catName,
  });

  @override
  ConsumerState<DistributionMapScreen> createState() =>
      _DistributionMapScreenState();
}

class _DistributionMapScreenState
    extends ConsumerState<DistributionMapScreen> {
  CatSighting? _selected;

  @override
  Widget build(BuildContext context) {
    final sightingsAsync = ref.watch(catSightingsProvider(widget.catProfileId));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.catName),
        actions: [
          if (sightingsAsync.hasValue)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${sightingsAsync.value!.length}',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: sightingsAsync.when(
        data: (sightings) => _mapView(context, sightings),
        loading: () => const LoadingIndicator(),
        error: (e, _) => ErrorDisplay(message: e.toString()),
      ),
    );
  }

  Widget _mapView(BuildContext context, List<CatSighting> sightings) {
    if (sightings.isEmpty) {
      return const Center(
        child: Text('No sightings to show',
            style: TextStyle(color: AppColors.textSecondary)),
      );
    }

    final points = sightings.map((s) => s.latLng).toList();
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
            initialCenter: points.length == 1 ? points.first : _centroid(points),
            initialZoom: 14,
            initialCameraFit: cameraFit,
            onTap: (_, __) => setState(() => _selected = null),
          ),
          children: [
            TileLayer(
              urlTemplate: AppConstants.osmTileUrl,
              userAgentPackageName: AppConstants.osmUserAgent,
            ),
            MarkerLayer(
              markers: sightings
                  .map(
                    (s) => Marker(
                      point: s.latLng,
                      width: 36,
                      height: 36,
                      child: GestureDetector(
                        onTap: () => setState(() => _selected = s),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _selected?.id == s.id
                                ? AppColors.textPrimary
                                : AppColors.accent,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: const [
                              BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(0, 2)),
                            ],
                          ),
                          child: const Icon(Icons.pets,
                              color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),

        // Bottom panel slides in when a marker is tapped.
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
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 80,
                height: 80,
                child: LocalImage(
                  relativePath: sighting.imagePath,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat('MMM d, y  h:mm a').format(sighting.capturedAt),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.place,
                          size: 13, color: AppColors.textSecondary),
                      const SizedBox(width: 3),
                      Text(
                        '${sighting.latitude.toStringAsFixed(5)}, ${sighting.longitude.toStringAsFixed(5)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  if (sighting.locationFineTuned)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: AppColors.accent.withValues(alpha: 0.5)),
                        ),
                        child: const Text(
                          'Fine-tuned location',
                          style: TextStyle(
                              color: AppColors.accent,
                              fontSize: 11,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  if (sighting.notes != null && sighting.notes!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        sighting.notes!,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 2,
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
    final lat = pts.map((p) => p.latitude).reduce((a, b) => a + b) / pts.length;
    final lng =
        pts.map((p) => p.longitude).reduce((a, b) => a + b) / pts.length;
    return LatLng(lat, lng);
  }
}
