import 'package:alfanutrition/data/models/exercise_set.dart';
import 'package:alfanutrition/data/models/workout.dart';
import 'package:alfanutrition/data/models/workout_exercise.dart';

import 'enum_mappers.dart';

/// Maps between Supabase `workouts` / `workout_exercises` / `exercise_sets`
/// rows and the app-side [Workout], [WorkoutExercise], [ExerciseSet] models.
abstract final class WorkoutMapper {
  // ─────────────────────────── Workout ────────────────────────────────────

  /// Converts a Supabase row (with nested `workout_exercises` and
  /// `exercise_sets`) into a [Workout].
  static Workout fromRow(Map<String, dynamic> row) {
    final exerciseRows = row['workout_exercises'] as List? ?? [];
    return Workout(
      id: row['id'] as String,
      name: row['name'] as String,
      date: DateTime.parse(row['date'] as String),
      durationSeconds: row['duration_seconds'] as int? ?? 0,
      exercises: exerciseRows
          .map((e) => workoutExerciseFromRow(e as Map<String, dynamic>))
          .toList(),
      notes: row['notes'] as String?,
      isCompleted: row['is_completed'] as bool? ?? false,
    );
  }

  /// Converts a [Workout] into a Supabase-ready row `Map`.
  ///
  /// Does NOT include nested exercises — those are inserted separately.
  static Map<String, dynamic> toRow(Workout workout, {required String userId}) {
    return {
      'id': workout.id,
      'user_id': userId,
      'name': workout.name,
      'date': workout.date.toIso8601String(),
      'duration_seconds': workout.durationSeconds,
      'notes': workout.notes,
      'is_completed': workout.isCompleted,
    };
  }

  // ─────────────────────────── WorkoutExercise ───────────────────────────

  static WorkoutExercise workoutExerciseFromRow(Map<String, dynamic> row) {
    final setRows = row['exercise_sets'] as List? ?? [];
    return WorkoutExercise(
      id: row['id'] as String,
      exerciseId: row['exercise_id'] as String,
      exerciseName: row['exercise_name'] as String,
      sets: setRows
          .map((s) => exerciseSetFromRow(s as Map<String, dynamic>))
          .toList(),
      notes: row['notes'] as String?,
      primaryMuscle:
          EnumMappers.muscleGroupFromDb(row['primary_muscle'] as String),
    );
  }

  static Map<String, dynamic> workoutExerciseToRow(
    WorkoutExercise exercise, {
    required String workoutId,
  }) {
    return {
      'id': exercise.id,
      'workout_id': workoutId,
      'exercise_id': exercise.exerciseId,
      'exercise_name': exercise.exerciseName,
      'notes': exercise.notes,
      'primary_muscle': EnumMappers.muscleGroupToDb(exercise.primaryMuscle),
    };
  }

  // ─────────────────────────── ExerciseSet ───────────────────────────────

  static ExerciseSet exerciseSetFromRow(Map<String, dynamic> row) {
    return ExerciseSet(
      setNumber: row['set_number'] as int,
      weight: (row['weight_kg'] as num?)?.toDouble(),
      reps: row['reps'] as int?,
      rpe: (row['rpe'] as num?)?.toDouble(),
      restTimeSeconds: row['rest_time_seconds'] as int?,
      isCompleted: row['is_completed'] as bool? ?? false,
      isWarmup: row['is_warmup'] as bool? ?? false,
    );
  }

  static Map<String, dynamic> exerciseSetToRow(
    ExerciseSet set, {
    required String workoutExerciseId,
  }) {
    return {
      'workout_exercise_id': workoutExerciseId,
      'set_number': set.setNumber,
      'weight_kg': set.weight,
      'reps': set.reps,
      'rpe': set.rpe,
      'rest_time_seconds': set.restTimeSeconds,
      'is_completed': set.isCompleted,
      'is_warmup': set.isWarmup,
    };
  }
}
