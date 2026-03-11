import 'package:uuid/uuid.dart';

class CatProfile {
  final String id;
  final String name;

  /// Relative path stored in DB, e.g. 'cover_photos/uuid.jpg'.
  /// Reconstruct full path at runtime with getApplicationDocumentsDirectory().
  final String? coverImagePath;
  final String? notes;

  /// ARGB int used to colour this cat's map markers.
  /// Defaults to the app accent colour (0xFFFF8C42).
  final int color;

  final DateTime createdAt;
  final DateTime updatedAt;

  /// Populated via COUNT JOIN — not stored in this table.
  final int sightingCount;

  static const int defaultColor = 0xFFFF8C42;

  CatProfile({
    String? id,
    required this.name,
    this.coverImagePath,
    this.notes,
    int? color,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.sightingCount = 0,
  })  : id = id ?? const Uuid().v4(),
        color = color ?? defaultColor,
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  CatProfile copyWith({
    String? name,
    String? coverImagePath,
    bool clearCoverImage = false,
    String? notes,
    bool clearNotes = false,
    int? color,
    DateTime? updatedAt,
    int? sightingCount,
  }) {
    return CatProfile(
      id: id,
      name: name ?? this.name,
      coverImagePath:
          clearCoverImage ? null : (coverImagePath ?? this.coverImagePath),
      notes: clearNotes ? null : (notes ?? this.notes),
      color: color ?? this.color,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      sightingCount: sightingCount ?? this.sightingCount,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'cover_image_path': coverImagePath,
        'notes': notes,
        'color': color,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory CatProfile.fromMap(Map<String, dynamic> map) => CatProfile(
        id: map['id'] as String,
        name: map['name'] as String,
        coverImagePath: map['cover_image_path'] as String?,
        notes: map['notes'] as String?,
        color: (map['color'] as int?) ?? defaultColor,
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
        sightingCount: (map['sighting_count'] as int?) ?? 0,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is CatProfile && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'CatProfile(id: $id, name: $name)';
}
