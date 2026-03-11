import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

/// Resolves once on app start; all image widgets watch this to build file paths.
final appDocsDirProvider = FutureProvider<Directory>((ref) async {
  return getApplicationDocumentsDirectory();
});
