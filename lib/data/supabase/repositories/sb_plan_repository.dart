import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:alfanutrition/data/models/workout_plan.dart';
import 'package:alfanutrition/data/supabase/supabase_config.dart';
import 'package:alfanutrition/data/supabase/mappers/plan_mapper.dart';

class SbPlanRepository {
  final SupabaseClient _client;

  SbPlanRepository(this._client);

  String get _uid => _client.auth.currentUser!.id;

  static const _nestedSelect =
      '*, plan_days(*, plan_exercises(*))';

  /// Returns all workout plans with nested days and exercises.
  Future<List<WorkoutPlan>> getAllPlans() async {
    final rows = await _client
        .from(SupabaseConfig.workoutPlansTable)
        .select(_nestedSelect)
        .eq('user_id', _uid)
        .order('created_at', ascending: false);
    return rows.map((r) => PlanMapper.fromRow(r)).toList();
  }

  /// Returns a single plan by ID with all nested data.
  Future<WorkoutPlan?> getPlanById(String id) async {
    final row = await _client
        .from(SupabaseConfig.workoutPlansTable)
        .select(_nestedSelect)
        .eq('id', id)
        .eq('user_id', _uid)
        .maybeSingle();
    if (row == null) return null;
    return PlanMapper.fromRow(row);
  }

  /// Saves a workout plan with all nested days and exercises.
  ///
  /// Uses upserts so this handles both create and update.
  Future<void> savePlan(WorkoutPlan plan) async {
    // 1. Upsert the plan row.
    final planRow = PlanMapper.toRow(plan, userId: _uid);
    await _client.from(SupabaseConfig.workoutPlansTable).upsert(planRow);

    // 2. Remove old days for this plan so we can re-insert cleanly.
    await _client
        .from(SupabaseConfig.planDaysTable)
        .delete()
        .eq('plan_id', plan.id);

    // 3. Insert each day and its exercises.
    for (final day in plan.days) {
      final dayRow = PlanMapper.planDayToRow(day, planId: plan.id);
      final insertedDay = await _client
          .from(SupabaseConfig.planDaysTable)
          .insert(dayRow)
          .select('id')
          .single();

      final dayId = insertedDay['id'] as String;

      // Insert exercises for this day.
      for (final exercise in day.exercises) {
        final exerciseRow =
            PlanMapper.planExerciseToRow(exercise, planDayId: dayId);
        await _client
            .from(SupabaseConfig.planExercisesTable)
            .insert(exerciseRow);
      }
    }
  }

  /// Deletes a plan. Cascading foreign keys handle nested rows.
  Future<void> deletePlan(String id) async {
    await _client
        .from(SupabaseConfig.workoutPlansTable)
        .delete()
        .eq('id', id)
        .eq('user_id', _uid);
  }

  /// Sets the given plan as the active plan and deactivates all others.
  Future<void> setActivePlan(String id) async {
    // Deactivate all plans for this user.
    await _client
        .from(SupabaseConfig.workoutPlansTable)
        .update({'is_active': false})
        .eq('user_id', _uid);

    // Activate the selected plan.
    await _client
        .from(SupabaseConfig.workoutPlansTable)
        .update({'is_active': true})
        .eq('id', id)
        .eq('user_id', _uid);
  }
}
