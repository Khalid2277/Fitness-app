import 'package:hive/hive.dart';

import 'enums.dart';
import 'plan_exercise.dart';

@HiveType(typeId: 16)
class PlanDay extends HiveObject {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final int dayNumber;

  @HiveField(2)
  final List<PlanExercise> exercises;

  @HiveField(3)
  final String? focus;

  @HiveField(4)
  final List<MuscleGroup> targetMuscles;

  PlanDay({
    required this.name,
    required this.dayNumber,
    required this.exercises,
    this.focus,
    required this.targetMuscles,
  });

  /// Total number of sets across all exercises in this day.
  int get totalSets => exercises.fold(0, (sum, e) => sum + e.sets);

  /// Total number of exercises.
  int get exerciseCount => exercises.length;

  /// Estimated workout duration in minutes (based on sets and rest).
  int get estimatedDurationMinutes {
    int totalSeconds = 0;
    for (final exercise in exercises) {
      // ~40 seconds per set for actual lifting + rest between sets
      totalSeconds += exercise.sets * 40;
      totalSeconds += (exercise.sets - 1) * exercise.restSeconds;
    }
    return (totalSeconds / 60).ceil();
  }

  PlanDay copyWith({
    String? name,
    int? dayNumber,
    List<PlanExercise>? exercises,
    String? focus,
    List<MuscleGroup>? targetMuscles,
  }) {
    return PlanDay(
      name: name ?? this.name,
      dayNumber: dayNumber ?? this.dayNumber,
      exercises: exercises ?? this.exercises,
      focus: focus ?? this.focus,
      targetMuscles: targetMuscles ?? this.targetMuscles,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'dayNumber': dayNumber,
      'exercises': exercises.map((e) => e.toJson()).toList(),
      'focus': focus,
      'targetMuscles': targetMuscles.map((m) => m.name).toList(),
    };
  }

  factory PlanDay.fromJson(Map<String, dynamic> json) {
    return PlanDay(
      name: json['name'] as String,
      dayNumber: json['dayNumber'] as int,
      exercises: (json['exercises'] as List)
          .map((e) => PlanExercise.fromJson(e as Map<String, dynamic>))
          .toList(),
      focus: json['focus'] as String?,
      targetMuscles: (json['targetMuscles'] as List)
          .map((m) => MuscleGroup.values.byName(m as String))
          .toList(),
    );
  }

  @override
  String toString() =>
      'PlanDay(day: $dayNumber, name: $name, exercises: ${exercises.length})';
}

class PlanDayAdapter extends TypeAdapter<PlanDay> {
  @override
  final int typeId = 16;

  @override
  PlanDay read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      final key = reader.readByte();
      final value = reader.read();
      fields[key] = value;
    }
    return PlanDay(
      name: fields[0] as String,
      dayNumber: fields[1] as int,
      exercises: (fields[2] as List).cast<PlanExercise>(),
      focus: fields[3] as String?,
      targetMuscles: (fields[4] as List).cast<MuscleGroup>(),
    );
  }

  @override
  void write(BinaryWriter writer, PlanDay obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.dayNumber)
      ..writeByte(2)
      ..write(obj.exercises)
      ..writeByte(3)
      ..write(obj.focus)
      ..writeByte(4)
      ..write(obj.targetMuscles);
  }
}
