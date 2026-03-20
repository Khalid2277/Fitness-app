import 'package:hive/hive.dart';

import 'enums.dart';
import 'plan_day.dart';

@HiveType(typeId: 15)
class WorkoutPlan extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final SplitType splitType;

  @HiveField(4)
  final WorkoutGoal goal;

  @HiveField(5)
  final ExperienceLevel level;

  @HiveField(6)
  final int daysPerWeek;

  @HiveField(7)
  final List<PlanDay> days;

  @HiveField(8)
  final DateTime createdAt;

  WorkoutPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.splitType,
    required this.goal,
    required this.level,
    required this.daysPerWeek,
    required this.days,
    required this.createdAt,
  });

  /// Total exercises across all days.
  int get totalExercises =>
      days.fold(0, (sum, d) => sum + d.exercises.length);

  /// Total sets across all days.
  int get totalSets => days.fold(0, (sum, d) => sum + d.totalSets);

  /// All unique muscle groups targeted across the entire plan.
  Set<MuscleGroup> get allTargetMuscles =>
      days.expand((d) => d.targetMuscles).toSet();

  WorkoutPlan copyWith({
    String? id,
    String? name,
    String? description,
    SplitType? splitType,
    WorkoutGoal? goal,
    ExperienceLevel? level,
    int? daysPerWeek,
    List<PlanDay>? days,
    DateTime? createdAt,
  }) {
    return WorkoutPlan(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      splitType: splitType ?? this.splitType,
      goal: goal ?? this.goal,
      level: level ?? this.level,
      daysPerWeek: daysPerWeek ?? this.daysPerWeek,
      days: days ?? this.days,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'splitType': splitType.name,
      'goal': goal.name,
      'level': level.name,
      'daysPerWeek': daysPerWeek,
      'days': days.map((d) => d.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory WorkoutPlan.fromJson(Map<String, dynamic> json) {
    return WorkoutPlan(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      splitType: SplitType.values.byName(json['splitType'] as String),
      goal: WorkoutGoal.values.byName(json['goal'] as String),
      level: ExperienceLevel.values.byName(json['level'] as String),
      daysPerWeek: json['daysPerWeek'] as int,
      days: (json['days'] as List)
          .map((d) => PlanDay.fromJson(d as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is WorkoutPlan && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'WorkoutPlan(id: $id, name: $name, split: ${splitType.displayName})';
}

class WorkoutPlanAdapter extends TypeAdapter<WorkoutPlan> {
  @override
  final int typeId = 15;

  @override
  WorkoutPlan read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      final key = reader.readByte();
      final value = reader.read();
      fields[key] = value;
    }
    return WorkoutPlan(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String,
      splitType: fields[3] as SplitType,
      goal: fields[4] as WorkoutGoal,
      level: fields[5] as ExperienceLevel,
      daysPerWeek: fields[6] as int,
      days: (fields[7] as List).cast<PlanDay>(),
      createdAt: fields[8] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, WorkoutPlan obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.splitType)
      ..writeByte(4)
      ..write(obj.goal)
      ..writeByte(5)
      ..write(obj.level)
      ..writeByte(6)
      ..write(obj.daysPerWeek)
      ..writeByte(7)
      ..write(obj.days)
      ..writeByte(8)
      ..write(obj.createdAt);
  }
}
