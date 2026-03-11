import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/cat_sighting.dart';

class MiniMapWidget extends StatelessWidget {
  final List<CatSighting> sightings;
  final VoidCallback? onViewFull;

  const MiniMapWidget({
    super.key,
    required this.sightings,
    this.onViewFull,
  });

  @override
  Widget build(BuildContext context) {
    if (sightings.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text('No sightings yet',
              style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }

    final points = sightings.map((s) => s.latLng).toList();
    final cameraFit = points.length == 1
        ? null
        : CameraFit.bounds(
            bounds: LatLngBounds.fromPoints(points),
            padding: const EdgeInsets.all(30),
          );

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 200,
        child: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter:
                    points.length == 1 ? points.first : _centroid(points),
                initialZoom: points.length == 1 ? 14 : 12,
                initialCameraFit: cameraFit,
                interactionOptions:
                    const InteractionOptions(flags: InteractiveFlag.none),
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
                          width: 14,
                          height: 14,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
            if (onViewFull != null)
              Positioned(
                right: 8,
                bottom: 8,
                child: ElevatedButton.icon(
                  onPressed: onViewFull,
                  icon: const Icon(Icons.fullscreen, size: 16),
                  label: const Text('Full map'),
                  style: ElevatedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  LatLng _centroid(List<LatLng> points) {
    final lat = points.map((p) => p.latitude).reduce((a, b) => a + b) /
        points.length;
    final lng = points.map((p) => p.longitude).reduce((a, b) => a + b) /
        points.length;
    return LatLng(lat, lng);
  }
}
