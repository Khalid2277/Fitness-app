import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:alfanutrition/data/models/meal.dart';
import 'package:alfanutrition/data/supabase/supabase_config.dart';
import 'package:alfanutrition/data/supabase/mappers/nutrition_mapper.dart';

class SbNutritionRepository {
  final SupabaseClient _client;

  SbNutritionRepository(this._client);

  String get _uid => _client.auth.currentUser!.id;

  /// Returns all meals for a given date, ordered by time.
  Future<List<Meal>> getMealsForDate(DateTime date) async {
    final dateStr =
        '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';

    final rows = await _client
        .from(SupabaseConfig.mealsTable)
        .select()
        .eq('user_id', _uid)
        .gte('date_time', '${dateStr}T00:00:00')
        .lte('date_time', '${dateStr}T23:59:59')
        .order('date_time');
    return rows.map((r) => NutritionMapper.mealFromRow(r)).toList();
  }

  /// Returns a single meal by ID.
  Future<Meal?> getMealById(String id) async {
    final row = await _client
        .from(SupabaseConfig.mealsTable)
        .select()
        .eq('id', id)
        .eq('user_id', _uid)
        .maybeSingle();
    if (row == null) return null;
    return NutritionMapper.mealFromRow(row);
  }

  /// Adds a new meal.
  Future<void> addMeal(Meal meal) async {
    final data = NutritionMapper.mealToRow(meal, userId: _uid);
    await _client.from(SupabaseConfig.mealsTable).insert(data);
  }

  /// Updates an existing meal.
  Future<void> updateMeal(Meal meal) async {
    final data = NutritionMapper.mealToRow(meal, userId: _uid);
    await _client
        .from(SupabaseConfig.mealsTable)
        .update(data)
        .eq('id', meal.id)
        .eq('user_id', _uid);
  }

  /// Deletes a meal.
  Future<void> deleteMeal(String id) async {
    await _client
        .from(SupabaseConfig.mealsTable)
        .delete()
        .eq('id', id)
        .eq('user_id', _uid);
  }

  /// Returns meals within a date range.
  Future<List<Meal>> getMealsForDateRange(DateTime from, DateTime to) async {
    final rows = await _client
        .from(SupabaseConfig.mealsTable)
        .select()
        .eq('user_id', _uid)
        .gte('date_time', from.toIso8601String())
        .lte('date_time', to.toIso8601String())
        .order('date_time');
    return rows.map((r) => NutritionMapper.mealFromRow(r)).toList();
  }
}
