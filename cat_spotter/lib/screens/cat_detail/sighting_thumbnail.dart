import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../models/cat_sighting.dart';
import '../../widgets/local_image.dart';

class SightingThumbnail extends StatelessWidget {
  final CatSighting sighting;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const SightingThumbnail({
    super.key,
    required this.sighting,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onDelete == null
          ? null
          : () => _showDeleteSheet(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          fit: StackFit.expand,
          children: [
            LocalImage(
              relativePath: sighting.imagePath,
              fit: BoxFit.cover,
            ),
            if (sighting.locationFineTuned)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.edit_location_alt,
                      size: 12, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showDeleteSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                DateFormat('MMM d, y  h:mm a').format(sighting.capturedAt),
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ),
            ListTile(
              leading:
                  const Icon(Icons.delete_outline, color: AppColors.error),
              title: const Text('Delete sighting',
                  style: TextStyle(color: AppColors.error)),
              onTap: () {
                Navigator.pop(context);
                onDelete?.call();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
