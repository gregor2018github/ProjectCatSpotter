import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../data/cat_profile_dao.dart';
import '../../data/cat_sighting_dao.dart';
import '../../models/cat_sighting.dart';
import '../../providers/add_sighting_provider.dart';
import '../../providers/cat_profiles_provider.dart';
import '../../providers/cat_sightings_provider.dart';
import '../../services/image_storage_service.dart';

/// Default fallback center when no GPS is available (London).
const _kDefaultCenter = LatLng(51.505, -0.09);

class Step3MapFinetune extends ConsumerStatefulWidget {
  final VoidCallback onSaved;
  const Step3MapFinetune({super.key, required this.onSaved});

  @override
  ConsumerState<Step3MapFinetune> createState() => _Step3State();
}

class _Step3State extends ConsumerState<Step3MapFinetune> {
  late LatLng _pinLocation;
  bool _isFineTuned = false;
  LatLng? _gpsOriginal;
  bool _saving = false;
  final _notesController = TextEditingController();
  final _mapController = MapController();

  @override
  void initState() {
    super.initState();
    final state = ref.read(addSightingProvider);
    final pos = state.gpsPosition;
    _gpsOriginal = pos != null ? LatLng(pos.latitude, pos.longitude) : null;
    _pinLocation = _gpsOriginal ?? _kDefaultCenter;
    _notesController.text = state.notes;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _onMapTap(TapPosition _, LatLng latLng) {
    setState(() {
      _pinLocation = latLng;
      _isFineTuned = true;
    });
  }

  void _resetToGps() {
    if (_gpsOriginal == null) return;
    setState(() {
      _pinLocation = _gpsOriginal!;
      _isFineTuned = false;
    });
    _mapController.move(_pinLocation, _mapController.camera.zoom);
  }

  Future<void> _save() async {
    final state = ref.read(addSightingProvider);
    if (state.capturedImage == null || state.selectedCat == null) return;

    setState(() => _saving = true);

    try {
      // 1. Save image to permanent storage (returns relative path).
      final relativePath =
          await ImageStorageService.saveImage(state.capturedImage!);

      // 2. Build sighting model.
      final sighting = CatSighting(
        catProfileId: state.selectedCat!.id,
        imagePath: relativePath,
        latitude: _pinLocation.latitude,
        longitude: _pinLocation.longitude,
        accuracy: state.gpsPosition?.accuracy,
        locationFineTuned: _isFineTuned,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        capturedAt: DateTime.now(),
      );

      // 3. Insert into DB.
      await CatSightingDao.insertSighting(sighting);

      // 4. Update cat profile's updatedAt.
      final profile =
          await CatProfileDao.getProfileById(state.selectedCat!.id);
      if (profile != null) {
        await CatProfileDao.updateProfile(
            profile.copyWith(updatedAt: DateTime.now()));
      }

      // 5. Auto-set cover photo if the cat has none yet.
      if (profile != null &&
          (profile.coverImagePath == null || profile.coverImagePath!.isEmpty)) {
        await CatProfileDao.updateProfile(
            profile.copyWith(coverImagePath: relativePath));
      }

      // 6. Invalidate providers so UI refreshes.
      ref.invalidate(catSightingsProvider(state.selectedCat!.id));
      ref.invalidate(allCatSightingsProvider);
      ref.invalidate(catProfilesProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sighting saved!')),
        );
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e')),
        );
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final gpsLoading = ref.watch(addSightingProvider).gpsLoading;

    return Column(
      children: [
        // Instruction bar
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: AppColors.surface,
          child: Row(
            children: [
              const Icon(Icons.touch_app, color: AppColors.accent, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Tap the map to move the pin',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 13),
                ),
              ),
              if (gpsLoading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.accent),
                ),
            ],
          ),
        ),

        // Map
        Expanded(
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _pinLocation,
              initialZoom: 15,
              onTap: _onMapTap,
            ),
            children: [
              TileLayer(
                urlTemplate: AppConstants.osmTileUrl,
                userAgentPackageName: AppConstants.osmUserAgent,
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _pinLocation,
                    width: 40,
                    height: 48,
                    alignment: Alignment.topCenter,
                    child: const Icon(
                      Icons.location_pin,
                      color: AppColors.accent,
                      size: 48,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Bottom panel
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          decoration: const BoxDecoration(
            color: AppColors.background,
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Coordinates + fine-tuned indicator
              Row(
                children: [
                  const Icon(Icons.place, size: 14, color: AppColors.accent),
                  const SizedBox(width: 4),
                  Text(
                    '${_pinLocation.latitude.toStringAsFixed(5)}, ${_pinLocation.longitude.toStringAsFixed(5)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (_isFineTuned) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Fine-tuned',
                        style: TextStyle(
                            color: AppColors.accent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (_gpsOriginal != null && _isFineTuned)
                    TextButton(
                      onPressed: _resetToGps,
                      style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4)),
                      child: const Text('Reset to GPS',
                          style: TextStyle(
                              color: AppColors.accent, fontSize: 12)),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // Optional notes
              TextField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                maxLines: 2,
                maxLength: AppConstants.notesMaxLength,
                buildCounter: (_, {required currentLength, required isFocused, maxLength}) =>
                    Text(
                  '$currentLength/${maxLength ?? AppConstants.notesMaxLength}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: 10),

              // Save button
              ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save),
                label: Text(_saving ? 'Saving…' : 'Save Sighting'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }
}
