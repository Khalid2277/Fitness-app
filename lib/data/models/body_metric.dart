import 'package:hive/hive.dart';

@HiveType(typeId: 14)
class BodyMetric extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime date;

  @HiveField(2)
  final double? weight;

  @HiveField(3)
  final double? bodyFatPercentage;

  @HiveField(4)
  final double? chest;

  @HiveField(5)
  final double? waist;

  @HiveField(6)
  final double? hips;

  @HiveField(7)
  final double? bicepLeft;

  @HiveField(8)
  final double? bicepRight;

  @HiveField(9)
  final double? thighLeft;

  @HiveField(10)
  final double? thighRight;

  @HiveField(11)
  final double? neck;

  @HiveField(12)
  final String? notes;

  @HiveField(13)
  final String? photoPath;

  BodyMetric({
    required this.id,
    required this.date,
    this.weight,
    this.bodyFatPercentage,
    this.chest,
    this.waist,
    this.hips,
    this.bicepLeft,
    this.bicepRight,
    this.thighLeft,
    this.thighRight,
    this.neck,
    this.notes,
    this.photoPath,
  });

  /// Whether any body measurement (excluding weight/body fat) is recorded.
  bool get hasMeasurements =>
      chest != null ||
      waist != null ||
      hips != null ||
      bicepLeft != null ||
      bicepRight != null ||
      thighLeft != null ||
      thighRight != null ||
      neck != null;

  /// Waist-to-hip ratio (a common health indicator).
  double? get waistToHipRatio {
    if (waist != null && hips != null && hips! > 0) {
      return waist! / hips!;
    }
    return null;
  }

  /// Estimated lean body mass in kg (requires weight and body fat %).
  double? get leanBodyMass {
    if (weight != null && bodyFatPercentage != null) {
      return weight! * (1 - bodyFatPercentage! / 100);
    }
    return null;
  }

  BodyMetric copyWith({
    String? id,
    DateTime? date,
    double? weight,
    double? bodyFatPercentage,
    double? chest,
    double? waist,
    double? hips,
    double? bicepLeft,
    double? bicepRight,
    double? thighLeft,
    double? thighRight,
    double? neck,
    String? notes,
    String? photoPath,
  }) {
    return BodyMetric(
      id: id ?? this.id,
      date: date ?? this.date,
      weight: weight ?? this.weight,
      bodyFatPercentage: bodyFatPercentage ?? this.bodyFatPercentage,
      chest: chest ?? this.chest,
      waist: waist ?? this.waist,
      hips: hips ?? this.hips,
      bicepLeft: bicepLeft ?? this.bicepLeft,
      bicepRight: bicepRight ?? this.bicepRight,
      thighLeft: thighLeft ?? this.thighLeft,
      thighRight: thighRight ?? this.thighRight,
      neck: neck ?? this.neck,
      notes: notes ?? this.notes,
      photoPath: photoPath ?? this.photoPath,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'weight': weight,
      'bodyFatPercentage': bodyFatPercentage,
      'chest': chest,
      'waist': waist,
      'hips': hips,
      'bicepLeft': bicepLeft,
      'bicepRight': bicepRight,
      'thighLeft': thighLeft,
      'thighRight': thighRight,
      'neck': neck,
      'notes': notes,
      'photoPath': photoPath,
    };
  }

  factory BodyMetric.fromJson(Map<String, dynamic> json) {
    return BodyMetric(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      weight: (json['weight'] as num?)?.toDouble(),
      bodyFatPercentage: (json['bodyFatPercentage'] as num?)?.toDouble(),
      chest: (json['chest'] as num?)?.toDouble(),
      waist: (json['waist'] as num?)?.toDouble(),
      hips: (json['hips'] as num?)?.toDouble(),
      bicepLeft: (json['bicepLeft'] as num?)?.toDouble(),
      bicepRight: (json['bicepRight'] as num?)?.toDouble(),
      thighLeft: (json['thighLeft'] as num?)?.toDouble(),
      thighRight: (json['thighRight'] as num?)?.toDouble(),
      neck: (json['neck'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      photoPath: json['photoPath'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is BodyMetric && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'BodyMetric(id: $id, date: $date, weight: $weight kg)';
}

class BodyMetricAdapter extends TypeAdapter<BodyMetric> {
  @override
  final int typeId = 14;

  @override
  BodyMetric read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      final key = reader.readByte();
      final value = reader.read();
      fields[key] = value;
    }
    return BodyMetric(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      weight: fields[2] as double?,
      bodyFatPercentage: fields[3] as double?,
      chest: fields[4] as double?,
      waist: fields[5] as double?,
      hips: fields[6] as double?,
      bicepLeft: fields[7] as double?,
      bicepRight: fields[8] as double?,
      thighLeft: fields[9] as double?,
      thighRight: fields[10] as double?,
      neck: fields[11] as double?,
      notes: fields[12] as String?,
      photoPath: fields[13] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, BodyMetric obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.weight)
      ..writeByte(3)
      ..write(obj.bodyFatPercentage)
      ..writeByte(4)
      ..write(obj.chest)
      ..writeByte(5)
      ..write(obj.waist)
      ..writeByte(6)
      ..write(obj.hips)
      ..writeByte(7)
      ..write(obj.bicepLeft)
      ..writeByte(8)
      ..write(obj.bicepRight)
      ..writeByte(9)
      ..write(obj.thighLeft)
      ..writeByte(10)
      ..write(obj.thighRight)
      ..writeByte(11)
      ..write(obj.neck)
      ..writeByte(12)
      ..write(obj.notes)
      ..writeByte(13)
      ..write(obj.photoPath);
  }
}
