import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:alfanutrition/data/models/body_metric.dart';
import 'package:alfanutrition/data/models/enums.dart';
import 'package:alfanutrition/data/models/exercise_set.dart';
import 'package:alfanutrition/data/models/meal.dart';
import 'package:alfanutrition/data/models/user_profile.dart';
import 'package:alfanutrition/data/models/workout.dart';
import 'package:alfanutrition/data/models/workout_exercise.dart';
import 'package:alfanutrition/data/services/ai_service.dart';
import 'package:alfanutrition/data/supabase/data_source.dart';
import 'package:alfanutrition/data/supabase/supabase_providers.dart';
import 'package:alfanutrition/features/home/providers/home_providers.dart';
import 'package:alfanutrition/features/nutrition/providers/nutrition_providers.dart';
import 'package:alfanutrition/features/profile/providers/profile_providers.dart';
import 'package:alfanutrition/features/progress/providers/progress_providers.dart';
import 'package:alfanutrition/features/workouts/providers/workout_providers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Supported AI action types
// ─────────────────────────────────────────────────────────────────────────────

/// All action types the AI can execute on behalf of the user.
///
/// The AI returns structured JSON actions like:
/// ```json
/// { "type": "log_meal", "label": "Log Chicken Breast", "data": { ... } }
/// ```
///
/// This executor interprets and runs them against either Supabase or local
/// Hive repositories depending on the current data source.
abstract final class AiActionTypes {
  static const logMeal = 'log_meal';
  static const logWorkout = 'log_workout';
  static const logBodyMetric = 'log_body_metric';
  static const updateWeight = 'update_weight';
  static const updateProfile = 'update_profile';
}

// ─────────────────────────────────────────────────────────────────────────────
// Action result
// ─────────────────────────────────────────────────────────────────────────────

/// Result of executing an AI action.
class AiActionResult {
  final bool success;
  final String message;
  final String? errorDetail;

  const AiActionResult({
    required this.success,
    required this.message,
    this.errorDetail,
  });

  factory AiActionResult.ok(String message) =>
      AiActionResult(success: true, message: message);

  factory AiActionResult.error(String message, [String? detail]) =>
      AiActionResult(success: false, message: message, errorDetail: detail);
}

// ─────────────────────────────────────────────────────────────────────────────
// Executor
// ─────────────────────────────────────────────────────────────────────────────

/// Executes structured [AiAction]s by calling the appropriate repository
/// methods — either Supabase (when signed in) or local Hive storage.
class AiActionExecutor {
  final Ref _ref;
  static const _uuid = Uuid();

  AiActionExecutor(this._ref);

  bool get _isSupabase =>
      _ref.read(dataSourceProvider) == DataSourceType.supabase;

  /// Execute a single [AiAction] and return the result.
  Future<AiActionResult> execute(AiAction action) async {
    try {
      debugPrint('[AiAction] Executing: ${action.type} — ${action.label}');
      final result = switch (action.type) {
        AiActionTypes.logMeal => await _logMeal(action.data),
        AiActionTypes.logWorkout => await _logWorkout(action.data),
        AiActionTypes.logBodyMetric => await _logBodyMetric(action.data),
        AiActionTypes.updateWeight => await _updateWeight(action.data),
        AiActionTypes.updateProfile => await _updateProfile(action.data),
        // UI-only action types — these are handled by the chat UI, not the executor
        'navigate' || 'view_exercise' || 'view_food' =>
          AiActionResult.ok(action.label),
        _ => AiActionResult.error(
            'Unsupported action: ${action.type}',
            'Action type "${action.type}" is not recognized. '
            'Supported types: log_meal, log_workout, log_body_metric, '
            'update_weight, update_profile.',
          ),
      };
      if (result.success) {
        debugPrint('[AiAction] ✓ Success: ${result.message}');
      } else {
        debugPrint('[AiAction] ✗ Failed: ${result.message} — ${result.errorDetail}');
      }
      return result;
    } catch (e, st) {
      debugPrint('[AiAction] ✗ Exception executing ${action.type}: $e\n$st');
      return AiActionResult.error(
        'Failed to ${action.label.toLowerCase()}',
        e.toString(),
      );
    }
  }

  /// Execute multiple actions and return all results.
  Future<List<AiActionResult>> executeAll(List<AiAction> actions) async {
    final results = <AiActionResult>[];
    for (final action in actions) {
      results.add(await execute(action));
    }
    return results;
  }

  // ─────────────────────────── Log Meal ────────────────────────────────────

  /// Expected data:
  /// ```json
  /// {
  ///   "name": "Chicken Breast",
  ///   "calories": 165,
  ///   "protein": 31,
  ///   "carbs": 0,
  ///   "fats": 3.6,
  ///   "fiber": 0,
  ///   "meal_type": "lunch",       // breakfast, lunch, dinner, snack
  ///   "serving_size": 100,
  ///   "serving_unit": "g",
  ///   "date": "2026-03-20T12:00:00",  // optional, defaults to now
  ///   "notes": "Grilled, no skin"
  /// }
  /// ```
  Future<AiActionResult> _logMeal(Map<String, dynamic> data) async {
    final name = data['name'] as String? ?? 'Unnamed meal';
    final mealTypeStr = (data['meal_type'] as String? ?? 'snack').toLowerCase();
    final mealType = MealType.values.firstWhere(
      (m) => m.name.toLowerCase() == mealTypeStr,
      orElse: () => MealType.snack,
    );

    final dateTime = _parseDate(data['date']) ?? DateTime.now();

    final meal = Meal(
      id: _uuid.v4(),
      name: name,
      mealType: mealType,
      calories: _toDouble(data['calories']),
      protein: _toDouble(data['protein']),
      carbs: _toDouble(data['carbs']),
      fats: _toDouble(data['fats']),
      fiber: _toDouble(data['fiber']),
      dateTime: dateTime,
      servingSize: _toDouble(data['serving_size'], fallback: 1.0),
      servingUnit: data['serving_unit'] as String?,
      notes: data['notes'] as String?,
    );

    if (_isSupabase) {
      final repo = _ref.read(sbNutritionRepositoryProvider);
      await repo.addMeal(meal);
    } else {
      final repo = _ref.read(nutritionRepositoryProvider);
      final map = meal.toJson();
      map['date'] = meal.dateTime.toIso8601String();
      map['mealType'] = meal.mealType.index;
      await repo.saveMeal(map);
    }

    // Refresh nutrition UI — both the nutrition tab and the home dashboard
    _ref.invalidate(dailyNutritionProvider);
    _ref.invalidate(todaysNutritionProvider);

    final macroDetail = <String>[];
    if (meal.protein > 0) macroDetail.add('${meal.protein.round()}g P');
    if (meal.carbs > 0) macroDetail.add('${meal.carbs.round()}g C');
    if (meal.fats > 0) macroDetail.add('${meal.fats.round()}g F');

    return AiActionResult.ok(
      '✅ Logged "$name" — ${meal.calories.round()} kcal${macroDetail.isNotEmpty ? ' (${macroDetail.join(', ')})' : ''}',
    );
  }

  // ─────────────────────────── Log Workout ─────────────────────────────────

  /// Expected data:
  /// ```json
  /// {
  ///   "name": "Push Day",
  ///   "duration_minutes": 60,
  ///   "date": "2026-03-20T10:00:00",   // optional, defaults to now
  ///   "notes": "Felt strong today",
  ///   "exercises": [
  ///     {
  ///       "name": "Bench Press",
  ///       "exercise_id": "barbell-bench-press",
  ///       "primary_muscle": "chest",
  ///       "sets": [
  ///         { "weight": 80, "reps": 5 },
  ///         { "weight": 80, "reps": 5 },
  ///         { "weight": 80, "reps": 5 }
  ///       ]
  ///     }
  ///   ]
  /// }
  /// ```
  Future<AiActionResult> _logWorkout(Map<String, dynamic> data) async {
    final name = data['name'] as String? ?? 'Workout';
    final durationMin = _toInt(data['duration_minutes'], fallback: 60);
    final exercisesRaw = data['exercises'] as List? ?? [];
    final date = _parseDate(data['date']) ?? DateTime.now();

    final exercises = <WorkoutExercise>[];
    for (final eData in exercisesRaw) {
      final eMap = eData as Map<String, dynamic>;
      final setsRaw = eMap['sets'] as List? ?? [];
      final muscleStr = (eMap['primary_muscle'] as String? ?? 'chest').toLowerCase();
      final muscle = MuscleGroup.values.firstWhere(
        (m) => m.name.toLowerCase() == muscleStr,
        orElse: () => MuscleGroup.chest,
      );

      final sets = <ExerciseSet>[];
      for (int i = 0; i < setsRaw.length; i++) {
        final sMap = setsRaw[i] as Map<String, dynamic>;
        sets.add(ExerciseSet(
          setNumber: i + 1,
          weight: _toDoubleOrNull(sMap['weight']),
          reps: _toIntOrNull(sMap['reps']),
          rpe: _toDoubleOrNull(sMap['rpe']),
          isCompleted: true,
          isWarmup: sMap['is_warmup'] as bool? ?? false,
        ));
      }

      exercises.add(WorkoutExercise(
        id: _uuid.v4(),
        exerciseId: eMap['exercise_id'] as String? ?? _uuid.v4(),
        exerciseName: eMap['name'] as String? ?? 'Unknown',
        sets: sets,
        notes: eMap['notes'] as String?,
        primaryMuscle: muscle,
      ));
    }

    final workout = Workout(
      id: _uuid.v4(),
      name: name,
      date: date,
      durationSeconds: durationMin * 60,
      exercises: exercises,
      notes: data['notes'] as String?,
      isCompleted: true,
    );

    if (_isSupabase) {
      final repo = _ref.read(sbWorkoutRepositoryProvider);
      await repo.saveWorkout(workout);
    } else {
      final repo = _ref.read(workoutRepositoryProvider);
      await repo.saveWorkout(workout.toJson());
    }

    // Refresh workout history UI and home dashboard
    _ref.invalidate(workoutHistoryProvider);
    _ref.invalidate(todaysWorkoutProvider);
    _ref.invalidate(weeklyWorkoutSummaryProvider);
    _ref.invalidate(recentWorkoutsProvider);

    final totalSets = exercises.fold<int>(0, (s, e) => s + e.sets.length);
    return AiActionResult.ok(
      '✅ Logged "$name" — ${exercises.length} exercises, $totalSets sets, '
      '${durationMin}min',
    );
  }

  // ─────────────────────────── Log Body Metric ─────────────────────────────

  /// Expected data:
  /// ```json
  /// {
  ///   "weight": 80.5,
  ///   "body_fat_percentage": 15.0,
  ///   "chest": 100,
  ///   "waist": 82,
  ///   "hips": 95,
  ///   "bicep_left": 35,
  ///   "bicep_right": 35.5,
  ///   "thigh_left": 58,
  ///   "thigh_right": 58,
  ///   "neck": 38,
  ///   "notes": "Morning measurement"
  /// }
  /// ```
  Future<AiActionResult> _logBodyMetric(Map<String, dynamic> data) async {
    final metric = BodyMetric(
      id: _uuid.v4(),
      date: DateTime.now(),
      weight: _toDoubleOrNull(data['weight']),
      bodyFatPercentage: _toDoubleOrNull(data['body_fat_percentage']),
      chest: _toDoubleOrNull(data['chest']),
      waist: _toDoubleOrNull(data['waist']),
      hips: _toDoubleOrNull(data['hips']),
      bicepLeft: _toDoubleOrNull(data['bicep_left']),
      bicepRight: _toDoubleOrNull(data['bicep_right']),
      thighLeft: _toDoubleOrNull(data['thigh_left']),
      thighRight: _toDoubleOrNull(data['thigh_right']),
      neck: _toDoubleOrNull(data['neck']),
      notes: data['notes'] as String?,
    );

    if (_isSupabase) {
      final repo = _ref.read(sbBodyMetricRepositoryProvider);
      await repo.addMetric(metric);
    } else {
      final repo = _ref.read(bodyMetricRepositoryProvider);
      await repo.saveMetric(metric.toJson());
    }

    // Refresh progress UI
    _ref.invalidate(bodyMetricsProvider);

    final parts = <String>[];
    if (metric.weight != null) parts.add('${metric.weight}kg');
    if (metric.bodyFatPercentage != null) parts.add('${metric.bodyFatPercentage}% BF');

    return AiActionResult.ok(
      '✅ Logged body metrics${parts.isNotEmpty ? " — ${parts.join(', ')}" : ""}',
    );
  }

  // ─────────────────────────── Update Weight (shortcut) ────────────────────

  /// Quick shortcut for just logging weight.
  /// Expected data: `{ "weight": 80.5 }`
  Future<AiActionResult> _updateWeight(Map<String, dynamic> data) async {
    final weight = _toDoubleOrNull(data['weight']);
    if (weight == null) {
      return AiActionResult.error('No weight value provided');
    }

    return _logBodyMetric({'weight': weight, 'notes': 'Logged via AI Coach'});
  }

  // ─────────────────────────── Estimate Workout Calories ─────────────────────

  /// Estimate calories burned during a workout based on MET values.
  /// MET values: weight training=5.0, HIIT=8.0, cardio=7.0, general=4.0
  static double estimateWorkoutCalories({
    required double weightKg,
    required int durationMinutes,
    String workoutType = 'general',
  }) {
    final met = switch (workoutType.toLowerCase()) {
      'weight_training' || 'strength' || 'weights' => 5.0,
      'hiit' || 'circuit' || 'crossfit' => 8.0,
      'cardio' || 'running' || 'cycling' || 'swimming' => 7.0,
      'yoga' || 'stretching' || 'mobility' => 2.5,
      'walking' => 3.5,
      _ => 4.0,
    };
    return met * weightKg * (durationMinutes / 60.0);
  }

  // ─────────────────────────── Update Profile ──────────────────────────────

  /// Expected data: partial profile fields to update.
  /// ```json
  /// {
  ///   "weight": 80,
  ///   "height": 180,
  ///   "goal": "fatLoss",
  ///   "workout_days_per_week": 5
  /// }
  /// ```
  Future<AiActionResult> _updateProfile(Map<String, dynamic> data) async {
    if (_isSupabase) {
      final repo = _ref.read(sbProfileRepositoryProvider);
      final current = await repo.getProfile();
      if (current == null) {
        return AiActionResult.error('No profile found');
      }

      final updated = current.copyWith(
        weight: _toDoubleOrNull(data['weight']) ?? current.weight,
        height: _toDoubleOrNull(data['height']) ?? current.height,
        age: _toIntOrNull(data['age']) ?? current.age,
        workoutDaysPerWeek: _toIntOrNull(data['workout_days_per_week']) ??
            current.workoutDaysPerWeek,
      );

      await repo.updateProfile(updated);
    } else {
      final repo = _ref.read(userRepositoryProvider);
      final raw = await repo.getProfile();
      if (raw == null) {
        return AiActionResult.error('No profile found');
      }
      final current = UserProfile.fromJson(raw);
      final updated = current.copyWith(
        weight: _toDoubleOrNull(data['weight']) ?? current.weight,
        height: _toDoubleOrNull(data['height']) ?? current.height,
        age: _toIntOrNull(data['age']) ?? current.age,
        workoutDaysPerWeek: _toIntOrNull(data['workout_days_per_week']) ??
            current.workoutDaysPerWeek,
      );
      await repo.saveProfile(updated.toJson());
    }

    _ref.invalidate(userProfileProvider);
    return AiActionResult.ok('Profile updated');
  }

  // ─────────────────────────── Helpers ──────────────────────────────────────

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static double _toDouble(dynamic value, {double fallback = 0.0}) {
    if (value == null) return fallback;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? fallback;
  }

  static double? _toDoubleOrNull(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static int _toInt(dynamic value, {int fallback = 0}) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? fallback;
  }

  static int? _toIntOrNull(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

final aiActionExecutorProvider = Provider<AiActionExecutor>((ref) {
  return AiActionExecutor(ref);
});
