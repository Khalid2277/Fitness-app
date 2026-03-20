import 'package:alfanutrition/data/models/enums.dart';
import 'package:alfanutrition/data/models/plan_day.dart';
import 'package:alfanutrition/data/models/plan_exercise.dart';
import 'package:alfanutrition/data/models/workout_plan.dart';

import 'enum_mappers.dart';

/// Maps between Supabase `workout_plans` / `plan_days` / `plan_exercises`
/// rows and the app-side [WorkoutPlan], [PlanDay], [PlanExercise] models.
abstract final class PlanMapper {
  // ─────────────────────────── WorkoutPlan ───────────────────────────────

  /// Converts a Supabase row (with nested `plan_days` -> `plan_exercises`)
  /// into a [WorkoutPlan].
  static WorkoutPlan fromRow(Map<String, dynamic> row) {
    final dayRows = row['plan_days'] as List? ?? [];
    return WorkoutPlan(
      id: row['id'] as String,
      name: row['name'] as String,
      description: row['description'] as String? ?? '',
      splitType: EnumMappers.splitTypeFromDb(row['split_type'] as String),
      goal: EnumMappers.workoutGoalFromDb(row['goal'] as String),
      level:
          EnumMappers.experienceLevelFromDb(row['experience_level'] as String),
      daysPerWeek: row['days_per_week'] as int,
      days: dayRows
          .map((d) => planDayFromRow(d as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  /// Converts a [WorkoutPlan] into a Supabase-ready row `Map`.
  ///
  /// Does NOT include nested days — those are inserted separately.
  static Map<String, dynamic> toRow(
    WorkoutPlan plan, {
    required String userId,
  }) {
    return {
      'id': plan.id,
      'user_id': userId,
      'name': plan.name,
      'description': plan.description,
      'split_type': EnumMappers.splitTypeToDb(plan.splitType),
      'goal': EnumMappers.workoutGoalToDb(plan.goal),
      'experience_level': EnumMappers.experienceLevelToDb(plan.level),
      'days_per_week': plan.daysPerWeek,
      'created_at': plan.createdAt.toIso8601String(),
    };
  }

  // ─────────────────────────── PlanDay ───────────────────────────────────

  static PlanDay planDayFromRow(Map<String, dynamic> row) {
    final exerciseRows = row['plan_exercises'] as List? ?? [];
    return PlanDay(
      name: row['name'] as String,
      dayNumber: row['day_number'] as int,
      exercises: exerciseRows
          .map((e) => planExerciseFromRow(e as Map<String, dynamic>))
          .toList(),
      focus: row['focus'] as String?,
      targetMuscles: _muscleList(row['target_muscles']),
    );
  }

  static Map<String, dynamic> planDayToRow(
    PlanDay day, {
    required String planId,
  }) {
    return {
      'plan_id': planId,
      'name': day.name,
      'day_number': day.dayNumber,
      'focus': day.focus,
      'target_muscles':
          day.targetMuscles.map((m) => EnumMappers.muscleGroupToDb(m)).toList(),
    };
  }

  // ─────────────────────────── PlanExercise ──────────────────────────────

  static PlanExercise planExerciseFromRow(Map<String, dynamic> row) {
    return PlanExercise(
      exerciseId: row['exercise_id'] as String,
      exerciseName: row['exercise_name'] as String,
      sets: row['sets'] as int,
      reps: row['reps'] as int,
      notes: row['notes'] as String?,
      restSeconds: row['rest_seconds'] as int? ?? 90,
      primaryMuscle:
          EnumMappers.muscleGroupFromDb(row['primary_muscle'] as String),
    );
  }

  static Map<String, dynamic> planExerciseToRow(
    PlanExercise exercise, {
    required String planDayId,
  }) {
    return {
      'plan_day_id': planDayId,
      'exercise_id': exercise.exerciseId,
      'exercise_name': exercise.exerciseName,
      'sets': exercise.sets,
      'reps': exercise.reps,
      'notes': exercise.notes,
      'rest_seconds': exercise.restSeconds,
      'primary_muscle': EnumMappers.muscleGroupToDb(exercise.primaryMuscle),
    };
  }

  // ──────────────────────── Helpers ──────────────────────────────────────

  static List<MuscleGroup> _muscleList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value
          .cast<String>()
          .map((s) => EnumMappers.muscleGroupFromDb(s))
          .toList();
    }
    return [];
  }
}
