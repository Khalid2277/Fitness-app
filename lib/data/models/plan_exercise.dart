import 'package:hive/hive.dart';

import 'enums.dart';

@HiveType(typeId: 17)
class PlanExercise extends HiveObject {
  @HiveField(0)
  final String exerciseId;

  @HiveField(1)
  final String exerciseName;

  @HiveField(2)
  final int sets;

  @HiveField(3)
  final int reps;

  @HiveField(4)
  final String? notes;

  @HiveField(5)
  final int restSeconds;

  @HiveField(6)
  final MuscleGroup primaryMuscle;

  PlanExercise({
    required this.exerciseId,
    required this.exerciseName,
    required this.sets,
    required this.reps,
    this.notes,
    this.restSeconds = 90,
    required this.primaryMuscle,
  });

  /// Rest duration as a [Duration] object.
  Duration get restDuration => Duration(seconds: restSeconds);

  /// Formatted rest time (e.g. "1:30").
  String get formattedRest {
    final minutes = restSeconds ~/ 60;
    final seconds = restSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// Summary string (e.g. "4x10").
  String get setsRepsLabel => '${sets}x$reps';

  PlanExercise copyWith({
    String? exerciseId,
    String? exerciseName,
    int? sets,
    int? reps,
    String? notes,
    int? restSeconds,
    MuscleGroup? primaryMuscle,
  }) {
    return PlanExercise(
      exerciseId: exerciseId ?? this.exerciseId,
      exerciseName: exerciseName ?? this.exerciseName,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      notes: notes ?? this.notes,
      restSeconds: restSeconds ?? this.restSeconds,
      primaryMuscle: primaryMuscle ?? this.primaryMuscle,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exerciseId': exerciseId,
      'exerciseName': exerciseName,
      'sets': sets,
      'reps': reps,
      'notes': notes,
      'restSeconds': restSeconds,
      'primaryMuscle': primaryMuscle.name,
    };
  }

  factory PlanExercise.fromJson(Map<String, dynamic> json) {
    return PlanExercise(
      exerciseId: json['exerciseId'] as String,
      exerciseName: json['exerciseName'] as String,
      sets: json['sets'] as int,
      reps: json['reps'] as int,
      notes: json['notes'] as String?,
      restSeconds: json['restSeconds'] as int? ?? 90,
      primaryMuscle:
          MuscleGroup.values.byName(json['primaryMuscle'] as String),
    );
  }

  @override
  String toString() =>
      'PlanExercise(name: $exerciseName, $setsRepsLabel)';
}

class PlanExerciseAdapter extends TypeAdapter<PlanExercise> {
  @override
  final int typeId = 17;

  @override
  PlanExercise read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      final key = reader.readByte();
      final value = reader.read();
      fields[key] = value;
    }
    return PlanExercise(
      exerciseId: fields[0] as String,
      exerciseName: fields[1] as String,
      sets: fields[2] as int,
      reps: fields[3] as int,
      notes: fields[4] as String?,
      restSeconds: fields[5] as int? ?? 90,
      primaryMuscle: fields[6] as MuscleGroup,
    );
  }

  @override
  void write(BinaryWriter writer, PlanExercise obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.exerciseId)
      ..writeByte(1)
      ..write(obj.exerciseName)
      ..writeByte(2)
      ..write(obj.sets)
      ..writeByte(3)
      ..write(obj.reps)
      ..writeByte(4)
      ..write(obj.notes)
      ..writeByte(5)
      ..write(obj.restSeconds)
      ..writeByte(6)
      ..write(obj.primaryMuscle);
  }
}
