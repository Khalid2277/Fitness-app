import 'package:hive/hive.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PhotoAngle
// ─────────────────────────────────────────────────────────────────────────────

/// The four standard angles used for consistent progress tracking.
enum PhotoAngle {
  front,
  leftSide,
  rightSide,
  back;

  String get displayName {
    switch (this) {
      case PhotoAngle.front:
        return 'Front';
      case PhotoAngle.leftSide:
        return 'Left Side';
      case PhotoAngle.rightSide:
        return 'Right Side';
      case PhotoAngle.back:
        return 'Back';
    }
  }

  /// Storage key used in the photos map.
  String get key {
    switch (this) {
      case PhotoAngle.front:
        return 'front';
      case PhotoAngle.leftSide:
        return 'leftSide';
      case PhotoAngle.rightSide:
        return 'rightSide';
      case PhotoAngle.back:
        return 'back';
    }
  }

  /// Brief instruction for the user when capturing this angle.
  String get poseGuide {
    switch (this) {
      case PhotoAngle.front:
        return 'Stand relaxed, arms at your sides, facing the camera.';
      case PhotoAngle.leftSide:
        return 'Turn 90° to your left. Keep your arms relaxed at your sides.';
      case PhotoAngle.rightSide:
        return 'Turn 90° to your right. Keep your arms relaxed at your sides.';
      case PhotoAngle.back:
        return 'Face away from the camera, arms relaxed at your sides.';
    }
  }

  /// Parses a key string back to a [PhotoAngle].
  static PhotoAngle fromKey(String key) {
    return PhotoAngle.values.firstWhere(
      (a) => a.key == key,
      orElse: () => PhotoAngle.front,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ProgressPhotoSet — typeId 23
// ─────────────────────────────────────────────────────────────────────────────

/// A set of progress photos taken during a single session.
///
/// [photos] maps [PhotoAngle.key] → local file path on the device.
class ProgressPhotoSet {
  final String id;
  final DateTime date;
  final Map<String, String> photos;
  final String? notes;
  final double? weight;
  final double? bodyFatPercentage;
  final DateTime createdAt;

  const ProgressPhotoSet({
    required this.id,
    required this.date,
    required this.photos,
    this.notes,
    this.weight,
    this.bodyFatPercentage,
    required this.createdAt,
  });

  // ──────────────────────── Computed getters ────────────────────────────────

  /// Whether all 4 required angles have been captured.
  bool get isComplete =>
      PhotoAngle.values.every((angle) => photos.containsKey(angle.key));

  /// The number of angles that have been captured.
  int get completedAngleCount =>
      PhotoAngle.values.where((a) => photos.containsKey(a.key)).length;

  /// List of angles that have been captured.
  List<PhotoAngle> get completedAngles =>
      PhotoAngle.values.where((a) => photos.containsKey(a.key)).toList();

  /// List of angles still missing.
  List<PhotoAngle> get missingAngles =>
      PhotoAngle.values.where((a) => !photos.containsKey(a.key)).toList();

  /// Returns the file path for the given angle, or null.
  String? photoPathFor(PhotoAngle angle) => photos[angle.key];

  // ──────────────────────── Serialization ───────────────────────────────────

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'photos': photos,
        'notes': notes,
        'weight': weight,
        'bodyFatPercentage': bodyFatPercentage,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ProgressPhotoSet.fromJson(Map<String, dynamic> json) {
    return ProgressPhotoSet(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      photos: Map<String, String>.from(json['photos'] as Map),
      notes: json['notes'] as String?,
      weight: json['weight'] as double?,
      bodyFatPercentage: json['bodyFatPercentage'] as double?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  ProgressPhotoSet copyWith({
    String? id,
    DateTime? date,
    Map<String, String>? photos,
    String? notes,
    double? weight,
    double? bodyFatPercentage,
    DateTime? createdAt,
  }) {
    return ProgressPhotoSet(
      id: id ?? this.id,
      date: date ?? this.date,
      photos: photos ?? this.photos,
      notes: notes ?? this.notes,
      weight: weight ?? this.weight,
      bodyFatPercentage: bodyFatPercentage ?? this.bodyFatPercentage,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hive TypeAdapter — typeId 23
// ─────────────────────────────────────────────────────────────────────────────

class ProgressPhotoSetAdapter extends TypeAdapter<ProgressPhotoSet> {
  @override
  final int typeId = 23;

  @override
  ProgressPhotoSet read(BinaryReader reader) {
    final map = reader.readMap().cast<String, dynamic>();
    return ProgressPhotoSet.fromJson({
      'id': map['id'],
      'date': map['date'],
      'photos': Map<String, String>.from(map['photos'] as Map),
      'notes': map['notes'],
      'weight': map['weight'],
      'bodyFatPercentage': map['bodyFatPercentage'],
      'createdAt': map['createdAt'],
    });
  }

  @override
  void write(BinaryWriter writer, ProgressPhotoSet obj) {
    writer.writeMap(obj.toJson());
  }
}
