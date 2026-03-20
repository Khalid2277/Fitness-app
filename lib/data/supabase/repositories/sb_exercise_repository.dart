import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:alfanutrition/data/models/exercise.dart';
import 'package:alfanutrition/data/supabase/supabase_config.dart';
import 'package:alfanutrition/data/supabase/mappers/exercise_mapper.dart';

class SbExerciseRepository {
  final SupabaseClient _client;

  SbExerciseRepository(this._client);

  String get _uid => _client.auth.currentUser!.id;

  /// Returns all exercises visible to the current user:
  /// global exercises (user_id IS NULL) plus the user's custom exercises.
  Future<List<Exercise>> getAllExercises() async {
    final rows = await _client
        .from(SupabaseConfig.exercisesTable)
        .select()
        .or('user_id.is.null,user_id.eq.$_uid')
        .order('name');
    return rows.map((r) => ExerciseMapper.fromRow(r)).toList();
  }

  /// Returns a single exercise by its ID.
  Future<Exercise?> getExerciseById(String id) async {
    final row = await _client
        .from(SupabaseConfig.exercisesTable)
        .select()
        .eq('id', id)
        .maybeSingle();
    if (row == null) return null;
    return ExerciseMapper.fromRow(row);
  }

  /// Adds a custom exercise owned by the current user.
  Future<void> addCustomExercise(Exercise exercise) async {
    final data = ExerciseMapper.toRow(exercise, userId: _uid);
    await _client.from(SupabaseConfig.exercisesTable).insert(data);
  }

  /// Deletes a custom exercise owned by the current user.
  Future<void> deleteCustomExercise(String id) async {
    await _client
        .from(SupabaseConfig.exercisesTable)
        .delete()
        .eq('id', id)
        .eq('user_id', _uid);
  }
}
