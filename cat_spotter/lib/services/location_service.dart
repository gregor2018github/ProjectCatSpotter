import 'dart:async';
import 'dart:io';
import 'package:geolocator/geolocator.dart';
import '../core/constants.dart';

class LocationService {
  /// Requests permission if needed, then returns the best available position.
  ///
  /// Strategy:
  ///   1. Verify location service is enabled and permission is granted.
  ///   2. Try [Geolocator.getLastKnownPosition] for an immediate result —
  ///      this is instantaneous when the OS has a cached fix.
  ///   3. Fall back to [Geolocator.getPositionStream], which is more reliable
  ///      than [Geolocator.getCurrentPosition] on many Android versions
  ///      because it uses the same callback path as continuous updates and
  ///      avoids the single-shot FLP request that can silently stall.
  ///   4. A hard [Timer] cancels the stream after [AppConstants.gpsTimeoutSeconds].
  static Future<Position?> getCurrentPosition() async {
    if (!await _ensurePermission()) return null;

    // Fast path: use last-known position (returns immediately).
    final lastKnown = await _getLastKnown();
    if (lastKnown != null) return lastKnown;

    // Slow path: stream-based acquisition with a hard timeout.
    final completer = Completer<Position?>();
    StreamSubscription<Position>? sub;

    try {
      sub = Geolocator.getPositionStream(
        locationSettings: _buildSettings(LocationAccuracy.high),
      ).listen(
        (pos) {
          if (!completer.isCompleted) completer.complete(pos);
        },
        onError: (Object _) {
          if (!completer.isCompleted) completer.complete(null);
        },
        cancelOnError: true,
      );
    } catch (_) {
      return null;
    }

    final timer = Timer(
      const Duration(seconds: AppConstants.gpsTimeoutSeconds),
      () {
        if (!completer.isCompleted) completer.complete(null);
      },
    );

    final result = await completer.future;
    timer.cancel();
    await sub?.cancel();
    return result;
  }

  // Build platform-appropriate location settings.
  // AndroidSettings uses the Fused Location Provider which is significantly
  // faster and more reliable than the raw Android Location Manager on
  // modern devices (Pixel 6, Android 12+).
  static LocationSettings _buildSettings(LocationAccuracy accuracy) {
    if (Platform.isAndroid) {
      return AndroidSettings(
        accuracy: accuracy,
        distanceFilter: 0,
        forceLocationManager: false, // false = use Fused Location Provider
        intervalDuration: const Duration(seconds: 5),
      );
    }
    return LocationSettings(accuracy: accuracy, distanceFilter: 0);
  }

  static Future<Position?> _getLastKnown() async {
    try {
      return await Geolocator.getLastKnownPosition();
    } catch (_) {
      return null;
    }
  }

  /// Returns true if fine or coarse location permission is granted.
  static Future<bool> isPermissionGranted() async {
    final p = await Geolocator.checkPermission();
    return p == LocationPermission.whileInUse || p == LocationPermission.always;
  }

  static Future<bool> _ensurePermission() async {
    final serviceOn = await Geolocator.isLocationServiceEnabled();
    if (!serviceOn) return false;

    LocationPermission p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) {
      p = await Geolocator.requestPermission();
    }
    if (p == LocationPermission.deniedForever) return false;
    return p == LocationPermission.whileInUse || p == LocationPermission.always;
  }
}
