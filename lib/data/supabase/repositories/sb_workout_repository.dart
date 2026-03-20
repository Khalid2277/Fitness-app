import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:alfanutrition/data/models/workout.dart';
import 'package:alfanutrition/data/supabase/supabase_config.dart';
import 'package:alfanutrition/data/supabase/mappers/workout_mapper.dart';

class SbWorkoutRepository {
  final SupabaseClient _client;

  SbWorkoutRepository(this._client);

  String get _uid => _client.auth.currentUser!.id;

  static const _nestedSelect =
      '*, workout_exercises(*, exercise_sets(*))';

  /// Returns workouts with optional date-range filtering.
  Future<List<Workout>> getWorkouts({DateTime? from, DateTime? to}) async {
    var query = _client
        .from(SupabaseConfig.workoutsTable)
        .select(_nestedSelect)
        .eq('user_id', _uid);

    if (from != null) {
      query = query.gte('date', from.toIso8601String());
    }
    if (to != null) {
      query = query.lte('date', to.toIso8601String());
    }

    final rows = await query.order('date', ascending: false);
    return rows.map((r) => WorkoutMapper.fromRow(r)).toList();
  }

  /// Returns a single workout by ID with all nested data.
  Future<Workout?> getWorkoutById(String id) async {
    final row = await _client
        .from(SupabaseConfig.workoutsTable)
        .select(_nestedSelect)
        .eq('id', id)
        .eq('user_id', _uid)
        .maybeSingle();
    if (row == null) return null;
    return WorkoutMapper.fromRow(row);
  }

  /// Saves a workout with all nested exercises and sets.
  ///
  /// Uses upserts so this handles both create and update.
  Future<void> saveWorkout(Workout workout) async {
    // 1. Upsert the workout row.
    final workoutRow = WorkoutMapper.toRow(workout, userId: _uid);
    await _client.from(SupabaseConfig.workoutsTable).upsert(workoutRow);

    // 2. Remove old exercises for this workout so we can re-insert cleanly.
    await _client
        .from(SupabaseConfig.workoutExercisesTable)
        .delete()
        .eq('workout_id', workout.id);

    // 3. Insert each exercise and its sets.
    for (final exercise in workout.exercises) {
      final exerciseRow = WorkoutMapper.workoutExerciseToRow(
        exercise,
        workoutId: workout.id,
      );
      await _client
          .from(SupabaseConfig.workoutExercisesTable)
          .insert(exerciseRow);

      // Insert sets for this exercise.
      for (final set in exercise.sets) {
        final setRow = WorkoutMapper.exerciseSetToRow(
          set,
          workoutExerciseId: exercise.id,
        );
        await _client.from(SupabaseConfig.exerciseSetsTable).insert(setRow);
      }
    }
  }

  /// Deletes a workout. Cascading foreign keys handle nested rows.
  Future<void> deleteWorkout(String id) async {
    await _client
        .from(SupabaseConfig.workoutsTable)
        .delete()
        .eq('id', id)
        .eq('user_id', _uid);
  }

  /// Convenience wrapper for fetching workouts in a date range.
  Future<List<Workout>> getWorkoutsForDateRange(
    DateTime from,
    DateTime to,
  ) async {
    return getWorkouts(from: from, to: to);
  }
}
