import 'package:hive/hive.dart';

import 'enums.dart';
import 'workout_exercise.dart';

@HiveType(typeId: 11)
class Workout extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final DateTime date;

  @HiveField(3)
  final int durationSeconds;

  @HiveField(4)
  final List<WorkoutExercise> exercises;

  @HiveField(5)
  final String? notes;

  @HiveField(6)
  final bool isCompleted;

  Workout({
    required this.id,
    required this.name,
    required this.date,
    required this.durationSeconds,
    required this.exercises,
    this.notes,
    this.isCompleted = false,
  });

  /// Duration as a [Duration] object.
  Duration get duration => Duration(seconds: durationSeconds);

  /// Total volume across all exercises.
  double get totalVolume =>
      exercises.fold(0.0, (sum, e) => sum + e.totalVolume);

  /// Total number of completed working sets.
  int get totalCompletedSets =>
      exercises.fold(0, (sum, e) => sum + e.completedSets);

  /// Total number of sets across all exercises.
  int get totalSets => exercises.fold(0, (sum, e) => sum + e.sets.length);

  /// Unique muscle groups hit in this workout.
  Set<MuscleGroup> get musclesHit =>
      exercises.map((e) => e.primaryMuscle).toSet();

  /// Formatted duration string (e.g. "1h 23m").
  String get formattedDuration {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }

  Workout copyWith({
    String? id,
    String? name,
    DateTime? date,
    int? durationSeconds,
    List<WorkoutExercise>? exercises,
    String? notes,
    bool? isCompleted,
  }) {
    return Workout(
      id: id ?? this.id,
      name: name ?? this.name,
      date: date ?? this.date,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      exercises: exercises ?? this.exercises,
      notes: notes ?? this.notes,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'date': date.toIso8601String(),
      'durationSeconds': durationSeconds,
      'exercises': exercises.map((e) => e.toJson()).toList(),
      'notes': notes,
      'isCompleted': isCompleted,
    };
  }

  factory Workout.fromJson(Map<String, dynamic> json) {
    return Workout(
      id: json['id'] as String,
      name: json['name'] as String,
      date: DateTime.parse(json['date'] as String),
      durationSeconds: json['durationSeconds'] as int,
      exercises: (json['exercises'] as List)
          .map((e) => WorkoutExercise.fromJson(e as Map<String, dynamic>))
          .toList(),
      notes: json['notes'] as String?,
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Workout && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Workout(id: $id, name: $name, exercises: ${exercises.length})';
}

class WorkoutAdapter extends TypeAdapter<Workout> {
  @override
  final int typeId = 11;

  @override
  Workout read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      final key = reader.readByte();
      final value = reader.read();
      fields[key] = value;
    }
    return Workout(
      id: fields[0] as String,
      name: fields[1] as String,
      date: fields[2] as DateTime,
      durationSeconds: fields[3] as int,
      exercises: (fields[4] as List).cast<WorkoutExercise>(),
      notes: fields[5] as String?,
      isCompleted: fields[6] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, Workout obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.durationSeconds)
      ..writeByte(4)
      ..write(obj.exercises)
      ..writeByte(5)
      ..write(obj.notes)
      ..writeByte(6)
      ..write(obj.isCompleted);
  }
}
