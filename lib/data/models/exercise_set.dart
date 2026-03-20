import 'package:hive/hive.dart';

@HiveType(typeId: 9)
class ExerciseSet extends HiveObject {
  @HiveField(0)
  final int setNumber;

  @HiveField(1)
  final double? weight;

  @HiveField(2)
  final int? reps;

  @HiveField(3)
  final double? rpe;

  @HiveField(4)
  final int? restTimeSeconds;

  @HiveField(5)
  final bool isCompleted;

  @HiveField(6)
  final bool isWarmup;

  ExerciseSet({
    required this.setNumber,
    this.weight,
    this.reps,
    this.rpe,
    this.restTimeSeconds,
    this.isCompleted = false,
    this.isWarmup = false,
  });

  /// Rest time as a [Duration].
  Duration? get restTime =>
      restTimeSeconds != null ? Duration(seconds: restTimeSeconds!) : null;

  /// Total volume for this set (weight x reps). Returns 0 if either is null.
  double get volume => (weight ?? 0) * (reps ?? 0);

  ExerciseSet copyWith({
    int? setNumber,
    double? weight,
    int? reps,
    double? rpe,
    int? restTimeSeconds,
    bool? isCompleted,
    bool? isWarmup,
  }) {
    return ExerciseSet(
      setNumber: setNumber ?? this.setNumber,
      weight: weight ?? this.weight,
      reps: reps ?? this.reps,
      rpe: rpe ?? this.rpe,
      restTimeSeconds: restTimeSeconds ?? this.restTimeSeconds,
      isCompleted: isCompleted ?? this.isCompleted,
      isWarmup: isWarmup ?? this.isWarmup,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'setNumber': setNumber,
      'weight': weight,
      'reps': reps,
      'rpe': rpe,
      'restTimeSeconds': restTimeSeconds,
      'isCompleted': isCompleted,
      'isWarmup': isWarmup,
    };
  }

  factory ExerciseSet.fromJson(Map<String, dynamic> json) {
    return ExerciseSet(
      setNumber: json['setNumber'] as int,
      weight: (json['weight'] as num?)?.toDouble(),
      reps: json['reps'] as int?,
      rpe: (json['rpe'] as num?)?.toDouble(),
      restTimeSeconds: json['restTimeSeconds'] as int?,
      isCompleted: json['isCompleted'] as bool? ?? false,
      isWarmup: json['isWarmup'] as bool? ?? false,
    );
  }

  @override
  String toString() =>
      'ExerciseSet(set: $setNumber, weight: $weight, reps: $reps, rpe: $rpe)';
}

class ExerciseSetAdapter extends TypeAdapter<ExerciseSet> {
  @override
  final int typeId = 9;

  @override
  ExerciseSet read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      final key = reader.readByte();
      final value = reader.read();
      fields[key] = value;
    }
    return ExerciseSet(
      setNumber: fields[0] as int,
      weight: fields[1] as double?,
      reps: fields[2] as int?,
      rpe: fields[3] as double?,
      restTimeSeconds: fields[4] as int?,
      isCompleted: fields[5] as bool? ?? false,
      isWarmup: fields[6] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, ExerciseSet obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.setNumber)
      ..writeByte(1)
      ..write(obj.weight)
      ..writeByte(2)
      ..write(obj.reps)
      ..writeByte(3)
      ..write(obj.rpe)
      ..writeByte(4)
      ..write(obj.restTimeSeconds)
      ..writeByte(5)
      ..write(obj.isCompleted)
      ..writeByte(6)
      ..write(obj.isWarmup);
  }
}
