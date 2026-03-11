import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';

class CatSighting {
  final String id;
  final String catProfileId;

  /// Relative path stored in DB, e.g. 'cat_photos/uuid.jpg'.
  /// Reconstruct full path at runtime with getApplicationDocumentsDirectory().
  final String imagePath;
  final double latitude;
  final double longitude;

  /// GPS accuracy in metres (null if unavailable).
  final double? accuracy;

  /// True if the user manually repositioned the pin.
  final bool locationFineTuned;
  final String? notes;
  final DateTime capturedAt;
  final DateTime createdAt;

  CatSighting({
    String? id,
    required this.catProfileId,
    required this.imagePath,
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.locationFineTuned = false,
    this.notes,
    DateTime? capturedAt,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        capturedAt = capturedAt ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  /// Convenience getter for flutter_map / latlong2.
  LatLng get latLng => LatLng(latitude, longitude);

  CatSighting copyWith({
    String? imagePath,
    double? latitude,
    double? longitude,
    double? accuracy,
    bool? locationFineTuned,
    String? notes,
  }) =>
      CatSighting(
        id: id,
        catProfileId: catProfileId,
        imagePath: imagePath ?? this.imagePath,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        accuracy: accuracy ?? this.accuracy,
        locationFineTuned: locationFineTuned ?? this.locationFineTuned,
        notes: notes ?? this.notes,
        capturedAt: capturedAt,
        createdAt: createdAt,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'cat_profile_id': catProfileId,
        'image_path': imagePath,
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'location_fine_tuned': locationFineTuned ? 1 : 0,
        'notes': notes,
        'captured_at': capturedAt.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };

  factory CatSighting.fromMap(Map<String, dynamic> map) => CatSighting(
        id: map['id'] as String,
        catProfileId: map['cat_profile_id'] as String,
        imagePath: map['image_path'] as String,
        latitude: (map['latitude'] as num).toDouble(),
        longitude: (map['longitude'] as num).toDouble(),
        accuracy: map['accuracy'] != null
            ? (map['accuracy'] as num).toDouble()
            : null,
        locationFineTuned: (map['location_fine_tuned'] as int) == 1,
        notes: map['notes'] as String?,
        capturedAt: DateTime.parse(map['captured_at'] as String),
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is CatSighting && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
