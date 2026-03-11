import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../providers/app_providers.dart';

/// Displays a locally stored image given its **relative** path.
/// Shows a warm placeholder if the path is null/empty or the file is missing.
class LocalImage extends ConsumerWidget {
  final String? relativePath;
  final BoxFit fit;
  final Widget? placeholder;
  final double? width;
  final double? height;

  const LocalImage({
    super.key,
    required this.relativePath,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ph = placeholder ?? _defaultPlaceholder();

    if (relativePath == null || relativePath!.isEmpty) {
      return SizedBox(width: width, height: height, child: ph);
    }

    final dirAsync = ref.watch(appDocsDirProvider);
    return dirAsync.when(
      data: (dir) {
        final file = File('${dir.path}/$relativePath');
        return Image.file(
          file,
          fit: fit,
          width: width,
          height: height,
          errorBuilder: (_, __, ___) =>
              SizedBox(width: width, height: height, child: ph),
        );
      },
      loading: () => SizedBox(
        width: width,
        height: height,
        child: const Center(
            child: CircularProgressIndicator(color: AppColors.accent)),
      ),
      error: (_, __) => SizedBox(width: width, height: height, child: ph),
    );
  }

  Widget _defaultPlaceholder() => Container(
        color: AppColors.surface,
        child: const Center(
          child: Icon(Icons.pets, color: AppColors.accent, size: 48),
        ),
      );
}
