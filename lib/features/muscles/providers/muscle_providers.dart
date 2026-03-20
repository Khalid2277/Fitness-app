import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alfanutrition/data/models/enums.dart';
import 'package:alfanutrition/data/models/exercise.dart';
import 'package:alfanutrition/data/models/workout.dart';
import 'package:alfanutrition/data/repositories/workout_repository.dart';
import 'package:alfanutrition/data/services/muscle_analysis_service.dart';
import 'package:alfanutrition/data/seed/exercise_database.dart';
import 'package:alfanutrition/data/supabase/data_source.dart';
import 'package:alfanutrition/data/supabase/supabase_providers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Selected muscle (tapped on body map)
// ─────────────────────────────────────────────────────────────────────────────

final selectedMuscleProvider = StateProvider<MuscleGroup?>((ref) => null);

// ─────────────────────────────────────────────────────────────────────────────
// Weekly volume per muscle (sets this week)
// ─────────────────────────────────────────────────────────────────────────────

/// Internal async loader — fetches real workout data from Hive for the
/// current week (Monday to Sunday) and counts sets per primary muscle group.
final _weeklyVolumeLoader =
    FutureProvider<Map<MuscleGroup, int>>((ref) async {
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

  final Map<MuscleGroup, int> setsByMuscle = {
    for (final muscle in MuscleGroup.values) muscle: 0,
  };

  for (final workout in workouts) {
    for (final exercise in workout.exercises) {
      final sets = exercise.completedSets;
      setsByMuscle[exercise.primaryMuscle] =
          (setsByMuscle[exercise.primaryMuscle] ?? 0) + sets;
    }
  }

  return setsByMuscle;
});

/// Synchronous view of weekly volume data.
/// Returns an empty-zeroed map while the async loader is still pending.
final muscleVolumeProvider =
    Provider<Map<MuscleGroup, int>>((ref) {
  final asyncValue = ref.watch(_weeklyVolumeLoader);
  return asyncValue.when(
    data: (volume) => volume,
    loading: () => {for (final m in MuscleGroup.values) m: 0},
    error: (_, _) => {for (final m in MuscleGroup.values) m: 0},
  );
});

// ─────────────────────────────────────────────────────────────────────────────
// Muscle analysis (undertrained / overtrained / balance score)
// ─────────────────────────────────────────────────────────────────────────────

final muscleAnalysisProvider = Provider<MuscleAnalysisResult>((ref) {
  final volume = ref.watch(muscleVolumeProvider);
  final service = MuscleAnalysisService();

  // Convert our volume map into the format the service expects.
  final workouts = <Map<String, dynamic>>[
    {
      'exercises': volume.entries.map((e) {
        return {
          'primaryMuscle': e.key.name,
          'secondaryMuscles': <String>[],
          'sets': e.value,
        };
      }).toList(),
    },
  ];

  return service.analyze(workouts);
});

// ─────────────────────────────────────────────────────────────────────────────
// Exercises for a specific muscle group
// ─────────────────────────────────────────────────────────────────────────────

final exercisesForMuscleProvider =
    Provider.family<List<Exercise>, MuscleGroup>((ref, muscle) {
  return exercisesForMuscle(muscle);
});

// ─────────────────────────────────────────────────────────────────────────────
// Muscle status helper
// ─────────────────────────────────────────────────────────────────────────────

final muscleStatusProvider =
    Provider.family<String, MuscleGroup>((ref, muscle) {
  final analysis = ref.watch(muscleAnalysisProvider);
  final allStatuses = [
    ...analysis.undertrainedMuscles,
    ...analysis.optimalMuscles,
    ...analysis.overtrainedMuscles,
  ];
  try {
    return allStatuses.firstWhere((s) => s.muscle == muscle).status;
  } catch (_) {
    return 'undertrained';
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// Analysis sort mode
// ─────────────────────────────────────────────────────────────────────────────

enum AnalysisSortMode { mostTrained, leastTrained }

final analysisSortModeProvider =
    StateProvider<AnalysisSortMode>((ref) => AnalysisSortMode.leastTrained);

/// Sorted muscle statuses for the analysis view.
final sortedMuscleStatusesProvider =
    Provider<List<MuscleGroupStatus>>((ref) {
  final analysis = ref.watch(muscleAnalysisProvider);
  final sortMode = ref.watch(analysisSortModeProvider);
  final all = [
    ...analysis.undertrainedMuscles,
    ...analysis.optimalMuscles,
    ...analysis.overtrainedMuscles,
  ];

  switch (sortMode) {
    case AnalysisSortMode.mostTrained:
      all.sort((a, b) => b.currentSets.compareTo(a.currentSets));
    case AnalysisSortMode.leastTrained:
      all.sort((a, b) => a.currentSets.compareTo(b.currentSets));
  }

  return all;
});
