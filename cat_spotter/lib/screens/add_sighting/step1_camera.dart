import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../providers/add_sighting_provider.dart';
import '../../services/camera_service.dart';
import '../../services/location_service.dart';

class Step1Camera extends ConsumerStatefulWidget {
  final VoidCallback onNext;
  const Step1Camera({super.key, required this.onNext});

  @override
  ConsumerState<Step1Camera> createState() => _Step1CameraState();
}

class _Step1CameraState extends ConsumerState<Step1Camera> {
  @override
  void initState() {
    super.initState();
    // Start GPS acquisition immediately so it's ready by step 3.
    _startGps();
  }

  Future<void> _startGps() async {
    ref.read(addSightingProvider.notifier).setGpsLoading(true);
    final position = await LocationService.getCurrentPosition();
    if (mounted) {
      ref.read(addSightingProvider.notifier).setGpsPosition(position);
    }
  }

  Future<void> _takePhoto() async {
    final file = await CameraService.takePhoto();
    if (file != null && mounted) {
      ref.read(addSightingProvider.notifier).setImage(file);
    }
  }

  Future<void> _pickFromGallery() async {
    final file = await CameraService.pickFromGallery();
    if (file != null && mounted) {
      ref.read(addSightingProvider.notifier).setImage(file);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addSightingProvider);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // GPS status indicator
          _gpsStatusRow(state),
          const SizedBox(height: 20),

          // Photo preview or placeholder
          Expanded(
            child: state.capturedImage != null
                ? _photoPreview(state.capturedImage!.path)
                : _photoPlaceholder(context),
          ),

          const SizedBox(height: 20),

          // Action buttons
          if (state.capturedImage == null) ...[
            ElevatedButton.icon(
              onPressed: _takePhoto,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Take Photo'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _pickFromGallery,
              icon: const Icon(Icons.photo_library),
              label: const Text('Choose from Gallery'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _takePhoto,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retake'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: widget.onNext,
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Next'),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _gpsStatusRow(AddSightingState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          if (state.gpsLoading)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.accent),
            )
          else if (state.gpsPosition != null)
            const Icon(Icons.gps_fixed, color: Colors.green, size: 16)
          else
            const Icon(Icons.gps_off, color: AppColors.error, size: 16),
          const SizedBox(width: 10),
          Text(
            state.gpsLoading
                ? 'Acquiring GPS…'
                : state.gpsPosition != null
                    ? 'GPS acquired (±${state.gpsPosition!.accuracy.toStringAsFixed(0)} m)'
                    : 'GPS unavailable — you can place pin manually',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _photoPreview(String path) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.file(
        File(path),
        fit: BoxFit.cover,
        width: double.infinity,
      ),
    );
  }

  Widget _photoPlaceholder(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: AppColors.cardBorder.withValues(alpha: 0.5), width: 2),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_a_photo, size: 64, color: AppColors.accent),
            const SizedBox(height: 12),
            Text(
              'Take or choose a photo of the cat',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
