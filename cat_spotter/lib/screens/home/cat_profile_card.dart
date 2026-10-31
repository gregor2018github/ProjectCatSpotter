import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/cat_profile.dart';
import '../../widgets/local_image.dart';

class CatProfileCard extends StatelessWidget {
  final CatProfile profile;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const CatProfileCard({
    super.key,
    required this.profile,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          LocalImage(
            relativePath: profile.coverImagePath,
            fit: BoxFit.cover,
          ),
          // Bottom scrim so the name stays legible over any photo.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.45, 1.0],
                colors: [Colors.transparent, Color(0xD92B1D14)],
              ),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name,
                  style: AppTheme.display(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                _sightingChip(),
              ],
            ),
          ),
          Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onTap,
              onLongPress: () => _showOptions(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sightingChip() {
    final count = profile.sightingCount;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Color(profile.color),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$count sighting${count == 1 ? '' : 's'}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showOptions(BuildContext context) {
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
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading:
                  const Icon(Icons.edit_outlined, color: AppColors.textPrimary),
              title: Text('Edit ${profile.name}'),
              onTap: () {
                Navigator.pop(context);
                onEdit();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.error),
              title: Text(
                'Delete ${profile.name}',
                style: const TextStyle(color: AppColors.error),
              ),
              onTap: () {
                Navigator.pop(context);
                onDelete();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
