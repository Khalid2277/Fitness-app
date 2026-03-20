import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alfanutrition/core/constants/app_constants.dart';
import 'package:alfanutrition/data/models/enums.dart';
import 'package:alfanutrition/data/models/user_profile.dart';
import 'package:alfanutrition/data/repositories/nutrition_repository.dart';
import 'package:alfanutrition/data/repositories/workout_repository.dart';
import 'package:alfanutrition/data/repositories/user_repository.dart';
import 'package:alfanutrition/data/models/workout.dart';
import 'package:alfanutrition/data/supabase/data_source.dart';
import 'package:alfanutrition/data/supabase/supabase_providers.dart';
import 'package:alfanutrition/features/profile/providers/profile_providers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data models for the home dashboard
// ─────────────────────────────────────────────────────────────────────────────

class DailyNutrition {
  final double caloriesConsumed;
  final double caloriesTarget;
  final double proteinConsumed;
  final double proteinTarget;
  final double carbsConsumed;
  final double carbsTarget;
  final double fatsConsumed;
  final double fatsTarget;

  const DailyNutrition({
    required this.caloriesConsumed,
    required this.caloriesTarget,
    required this.proteinConsumed,
    required this.proteinTarget,
    required this.carbsConsumed,
    required this.carbsTarget,
    required this.fatsConsumed,
    required this.fatsTarget,
  });

  double get caloriesRemaining => caloriesTarget - caloriesConsumed;
  double get caloriesPercent =>
      (caloriesConsumed / caloriesTarget).clamp(0.0, 1.0);
  double get proteinPercent =>
      (proteinConsumed / proteinTarget).clamp(0.0, 1.0);
  double get carbsPercent => (carbsConsumed / carbsTarget).clamp(0.0, 1.0);
  double get fatsPercent => (fatsConsumed / fatsTarget).clamp(0.0, 1.0);
}

class TodaysWorkout {
  final String id;
  final String name;
  final List<MuscleGroup> muscleGroups;
  final int durationMinutes;
  final bool isCompleted;
  final int exerciseCount;
  final String? focus;

  const TodaysWorkout({
    required this.id,
    required this.name,
    required this.muscleGroups,
    required this.durationMinutes,
    required this.isCompleted,
    required this.exerciseCount,
    this.focus,
  });
}

class WeeklyWorkoutSummary {
  /// Mon=0, Tue=1, ... Sun=6. True if trained that day.
  final List<bool> trainedDays;
  final int totalWorkouts;
  final int totalMinutes;
  final int streak;

  const WeeklyWorkoutSummary({
    required this.trainedDays,
    required this.totalWorkouts,
    required this.totalMinutes,
    this.streak = 0,
  });

  int get daysTrained => trainedDays.where((d) => d).length;
}

class RecentWorkout {
  final String id;
  final String name;
  final List<MuscleGroup> muscleGroups;
  final int durationMinutes;
  final DateTime date;
  final int exerciseCount;
  final int totalSets;

  const RecentWorkout({
    required this.id,
    required this.name,
    required this.muscleGroups,
    required this.durationMinutes,
    required this.date,
    required this.exerciseCount,
    required this.totalSets,
  });
}

class MuscleCoverageSummary {
  final Map<MuscleGroup, int> weeklySetsByMuscle;

  const MuscleCoverageSummary({required this.weeklySetsByMuscle});

  int get totalMusclesTrained =>
      weeklySetsByMuscle.values.where((s) => s > 0).length;
  int get totalMuscleGroups => MuscleGroup.values.length;

  /// Returns a percentage (0-100) for the given muscle category.
  /// Categories: upper (chest, back, shoulders, biceps, triceps, traps, lats, forearms),
  /// core (core, obliques), lower (quadriceps, hamstrings, glutes, calves, hipFlexors, adductors, abductors).
  int categoryPercent(String category) {
    final List<MuscleGroup> muscles;
    switch (category) {
      case 'upper':
        muscles = [
          MuscleGroup.chest,
          MuscleGroup.back,
          MuscleGroup.shoulders,
          MuscleGroup.biceps,
          MuscleGroup.triceps,
          MuscleGroup.traps,
          MuscleGroup.lats,
          MuscleGroup.forearms,
        ];
      case 'core':
        muscles = [MuscleGroup.core, MuscleGroup.obliques];
      case 'lower':
        muscles = [
          MuscleGroup.quadriceps,
          MuscleGroup.hamstrings,
          MuscleGroup.glutes,
          MuscleGroup.calves,
          MuscleGroup.hipFlexors,
          MuscleGroup.adductors,
          MuscleGroup.abductors,
        ];
      default:
        return 0;
    }
    if (muscles.isEmpty) return 0;
    final trained = muscles.where((m) {
      final sets = weeklySetsByMuscle[m] ?? 0;
      return sets > 0;
    }).length;
    return ((trained / muscles.length) * 100).round();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Today's nutrition data: calories + macros consumed.
/// Reads from Hive meals box and aggregates today's entries.
/// Targets come from the user profile (computed from BMR/TDEE or manual
/// overrides). Falls back to AppConstants only when the profile hasn't loaded.
final todaysNutritionProvider = FutureProvider<DailyNutrition>((ref) async {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final source = ref.watch(dataSourceProvider);

  double calories = 0, protein = 0, carbs = 0, fats = 0;

  if (source == DataSourceType.supabase) {
    final sbRepo = ref.read(sbNutritionRepositoryProvider);
    final meals = await sbRepo.getMealsForDate(today);
    for (final meal in meals) {
      calories += meal.calories;
      protein += meal.protein;
      carbs += meal.carbs;
      fats += meal.fats;
    }
  } else {
    final repo = NutritionRepository();
    final rawMeals = await repo.getMealsForDate(today);
    for (final raw in rawMeals) {
      calories += (raw['calories'] as num?)?.toDouble() ?? 0;
      protein += (raw['protein'] as num?)?.toDouble() ?? 0;
      carbs += (raw['carbs'] as num?)?.toDouble() ?? 0;
      fats += (raw['fats'] as num?)?.toDouble() ?? 0;
    }
  }

  // Await the profile so we never flash default values while loading.
  final profile = await ref.watch(userProfileProvider.future);

  final calorieTarget =
      profile.dailyCalorieTarget ?? AppConstants.defaultCalorieTarget;
  final proteinTarget =
      profile.proteinTarget ?? AppConstants.defaultProteinTarget;
  final carbsTarget =
      profile.carbsTarget ?? AppConstants.defaultCarbsTarget;
  final fatsTarget =
      profile.fatsTarget ?? AppConstants.defaultFatsTarget;

  return DailyNutrition(
    caloriesConsumed: calories,
    caloriesTarget: calorieTarget,
    proteinConsumed: protein,
    proteinTarget: proteinTarget,
    carbsConsumed: carbs,
    carbsTarget: carbsTarget,
    fatsConsumed: fats,
    fatsTarget: fatsTarget,
  );
});

/// Today's scheduled/completed workout.
final todaysWorkoutProvider = FutureProvider<TodaysWorkout?>((ref) async {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final tomorrow = today.add(const Duration(days: 1));
  final source = ref.watch(dataSourceProvider);

  final Workout w;

  if (source == DataSourceType.supabase) {
    final sbRepo = ref.read(sbWorkoutRepositoryProvider);
    final workouts = await sbRepo.getWorkoutsForDateRange(today, tomorrow);
    if (workouts.isEmpty) return null;
    w = workouts.first;
  } else {
    final repo = WorkoutRepository();
    final rawWorkouts = await repo.getWorkoutsInRange(today, tomorrow);
    if (rawWorkouts.isEmpty) return null;
    w = Workout.fromJson(rawWorkouts.first);
  }

  // Get user's goal for the workout focus label
  final profile = await ref.watch(userProfileProvider.future);
  final focusLabel = profile.goal.displayName;

  return TodaysWorkout(
    id: w.id,
    name: w.name,
    muscleGroups: w.exercises.map((e) => e.primaryMuscle).toSet().toList(),
    durationMinutes: w.durationSeconds ~/ 60,
    isCompleted: w.isCompleted,
    exerciseCount: w.exercises.length,
    focus: focusLabel,
  );
});

/// Weekly training summary with dot-per-day visualization data.
final weeklyWorkoutSummaryProvider =
    FutureProvider<WeeklyWorkoutSummary>((ref) async {
  final now = DateTime.now();
  // Monday of this week
  final monday = now.subtract(Duration(days: now.weekday - 1));
  final weekStart = DateTime(monday.year, monday.month, monday.day);
  final weekEnd = weekStart.add(const Duration(days: 7));
  final source = ref.watch(dataSourceProvider);

  List<Workout> workouts;
  List<Workout> allWorkouts;

  if (source == DataSourceType.supabase) {
    final sbRepo = ref.read(sbWorkoutRepositoryProvider);
    workouts = await sbRepo.getWorkoutsForDateRange(weekStart, weekEnd);
    allWorkouts = await sbRepo.getWorkouts();
    allWorkouts.sort((a, b) => b.date.compareTo(a.date));
  } else {
    final repo = WorkoutRepository();
    final rawWorkouts = await repo.getWorkoutsInRange(weekStart, weekEnd);
    workouts = rawWorkouts.map((w) => Workout.fromJson(w)).toList();

    final allRaw = await repo.getAllWorkouts();
    allWorkouts = allRaw.map((w) => Workout.fromJson(w)).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  // Build trained days array (Mon=0 ... Sun=6)
  final trainedDays = List<bool>.filled(7, false);
  int totalMinutes = 0;

  for (final w in workouts) {
    if (w.isCompleted) {
      final dayIndex = w.date.weekday - 1; // 1=Mon -> 0
      trainedDays[dayIndex] = true;
      totalMinutes += w.durationSeconds ~/ 60;
    }
  }

  int streak = 0;
  DateTime checkDate = DateTime(now.year, now.month, now.day);
  for (int i = 0; i < 365; i++) {
    final hasWorkout = allWorkouts.any((w) {
      final wDate = DateTime(w.date.year, w.date.month, w.date.day);
      return wDate == checkDate && w.isCompleted;
    });
    if (hasWorkout) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    } else {
      break;
    }
  }

  return WeeklyWorkoutSummary(
    trainedDays: trainedDays,
    totalWorkouts: workouts.where((w) => w.isCompleted).length,
    totalMinutes: totalMinutes,
    streak: streak,
  );
});

/// Last 3 completed workouts.
final recentWorkoutsProvider =
    FutureProvider<List<RecentWorkout>>((ref) async {
  final source = ref.watch(dataSourceProvider);

  List<Workout> workouts;

  if (source == DataSourceType.supabase) {
    final sbRepo = ref.read(sbWorkoutRepositoryProvider);
    workouts = await sbRepo.getWorkouts();
  } else {
    final repo = WorkoutRepository();
    final rawWorkouts = await repo.getAllWorkouts();
    workouts = rawWorkouts.map((w) => Workout.fromJson(w)).toList();
  }
  workouts.sort((a, b) => b.date.compareTo(a.date));

  return workouts
      .take(3)
      .map((w) => RecentWorkout(
            id: w.id,
            name: w.name,
            muscleGroups:
                w.exercises.map((e) => e.primaryMuscle).toSet().toList(),
            durationMinutes: w.durationSeconds ~/ 60,
            date: w.date,
            exerciseCount: w.exercises.length,
            totalSets: w.exercises.fold(0, (sum, e) => sum + e.sets.length),
          ))
      .toList();
});

/// Muscle coverage summary for the week.
final muscleCoverageProvider =
    FutureProvider<MuscleCoverageSummary>((ref) async {
  final now = DateTime.now();
  final monday = now.subtract(Duration(days: now.weekday - 1));
  final weekStart = DateTime(monday.year, monday.month, monday.day);
  final weekEnd = weekStart.add(const Duration(days: 7));
  final source = ref.watch(dataSourceProvider);

  List<Workout> workouts;

  if (source == DataSourceType.supabase) {
    final sbRepo = ref.read(sbWorkoutRepositoryProvider);
    workouts = await sbRepo.getWorkoutsForDateRange(weekStart, weekEnd);
  } else {
    final repo = WorkoutRepository();
    final rawWorkouts = await repo.getWorkoutsInRange(weekStart, weekEnd);
    workouts = rawWorkouts.map((w) => Workout.fromJson(w)).toList();
  }

  final Map<MuscleGroup, int> setsByMuscle = {};
  for (final w in workouts) {
    for (final e in w.exercises) {
      setsByMuscle[e.primaryMuscle] =
          (setsByMuscle[e.primaryMuscle] ?? 0) + e.completedSets;
    }
  }

  return MuscleCoverageSummary(weeklySetsByMuscle: setsByMuscle);
});

/// User display name for the greeting header.
final userNameProvider = FutureProvider<String>((ref) async {
  final source = ref.watch(dataSourceProvider);

  if (source == DataSourceType.supabase) {
    final sbRepo = ref.read(sbProfileRepositoryProvider);
    final profile = await sbRepo.getProfile();
    if (profile != null && profile.name != null && profile.name!.isNotEmpty) {
      return profile.name!;
    }
    return '';
  }

  final repo = UserRepository();
  final raw = await repo.getProfile();
  if (raw != null && raw['name'] != null) {
    return raw['name'] as String;
  }
  return '';
});
