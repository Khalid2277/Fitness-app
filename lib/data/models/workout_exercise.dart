import 'package:hive/hive.dart';

import 'enums.dart';
import 'exercise_set.dart';

@HiveType(typeId: 10)
class WorkoutExercise extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String exerciseId;

  @HiveField(2)
  final String exerciseName;

  @HiveField(3)
  final List<ExerciseSet> sets;

  @HiveField(4)
  final String? notes;

  @HiveField(5)
  final MuscleGroup primaryMuscle;

  WorkoutExercise({
    required this.id,
    required this.exerciseId,
    required this.exerciseName,
    required this.sets,
    this.notes,
    required this.primaryMuscle,
  });

  /// Total volume (weight x reps) across all completed working sets.
  double get totalVolume => sets
      .where((s) => s.isCompleted && !s.isWarmup)
      .fold(0.0, (sum, s) => sum + s.volume);

  /// Number of working (non-warmup) sets that are completed.
  int get completedSets =>
      sets.where((s) => s.isCompleted && !s.isWarmup).length;

  /// Total working sets (excludes warmup).
  int get workingSets => sets.where((s) => !s.isWarmup).length;

  /// Best set by volume (weight x reps).
  ExerciseSet? get bestSet {
    final working = sets.where((s) => s.isCompleted && !s.isWarmup);
    if (working.isEmpty) return null;
    return working.reduce((a, b) => a.volume >= b.volume ? a : b);
  }

  WorkoutExercise copyWith({
    String? id,
    String? exerciseId,
    String? exerciseName,
    List<ExerciseSet>? sets,
    String? notes,
    MuscleGroup? primaryMuscle,
  }) {
    return WorkoutExercise(
      id: id ?? this.id,
      exerciseId: exerciseId ?? this.exerciseId,
      exerciseName: exerciseName ?? this.exerciseName,
      sets: sets ?? this.sets,
      notes: notes ?? this.notes,
      primaryMuscle: primaryMuscle ?? this.primaryMuscle,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'exerciseId': exerciseId,
      'exerciseName': exerciseName,
      'sets': sets.map((s) => s.toJson()).toList(),
      'notes': notes,
      'primaryMuscle': primaryMuscle.name,
    };
  }

  factory WorkoutExercise.fromJson(Map<String, dynamic> json) {
    return WorkoutExercise(
      id: json['id'] as String,
      exerciseId: json['exerciseId'] as String,
      exerciseName: json['exerciseName'] as String,
      sets: (json['sets'] as List)
          .map((s) => ExerciseSet.fromJson(s as Map<String, dynamic>))
          .toList(),
      notes: json['notes'] as String?,
      primaryMuscle:
          MuscleGroup.values.byName(json['primaryMuscle'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is WorkoutExercise && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'WorkoutExercise(id: $id, name: $exerciseName, sets: ${sets.length})';
}

class WorkoutExerciseAdapter extends TypeAdapter<WorkoutExercise> {
  @override
  final int typeId = 10;

  @override
  WorkoutExercise read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      final key = reader.readByte();
      final value = reader.read();
      fields[key] = value;
    }
    return WorkoutExercise(
      id: fields[0] as String,
      exerciseId: fields[1] as String,
      exerciseName: fields[2] as String,
      sets: (fields[3] as List).cast<ExerciseSet>(),
      notes: fields[4] as String?,
      primaryMuscle: fields[5] as MuscleGroup,
    );
  }

  @override
  void write(BinaryWriter writer, WorkoutExercise obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.exerciseId)
      ..writeByte(2)
      ..write(obj.exerciseName)
      ..writeByte(3)
      ..write(obj.sets)
      ..writeByte(4)
      ..write(obj.notes)
      ..writeByte(5)
      ..write(obj.primaryMuscle);
  }
}
