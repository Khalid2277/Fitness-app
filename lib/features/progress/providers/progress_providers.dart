import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alfanutrition/data/models/body_metric.dart';
import 'package:alfanutrition/data/repositories/body_metric_repository.dart';
import 'package:alfanutrition/data/models/workout.dart';
import 'package:alfanutrition/data/supabase/data_source.dart';
import 'package:alfanutrition/data/supabase/supabase_providers.dart';
import 'package:alfanutrition/features/workouts/providers/workout_providers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Repositories
// ─────────────────────────────────────────────────────────────────────────────

final bodyMetricRepositoryProvider = Provider<BodyMetricRepository>((ref) {
  return BodyMetricRepository();
});

// ─────────────────────────────────────────────────────────────────────────────
// Body Metrics — auto-selects Supabase or Hive
// ─────────────────────────────────────────────────────────────────────────────

final bodyMetricsProvider =
    FutureProvider<List<BodyMetric>>((ref) async {
  final source = ref.watch(dataSourceProvider);

  if (source == DataSourceType.supabase) {
    final sbRepo = ref.watch(sbBodyMetricRepositoryProvider);
    return sbRepo.getAllMetrics();
  }

  final repo = ref.watch(bodyMetricRepositoryProvider);
  final rawMetrics = await repo.getAllMetrics();
  return rawMetrics.map((m) => BodyMetric.fromJson(m)).toList();
});

/// Most recent body metric entry.
final latestMetricProvider = FutureProvider<BodyMetric?>((ref) async {
  final source = ref.watch(dataSourceProvider);

  if (source == DataSourceType.supabase) {
    final sbRepo = ref.watch(sbBodyMetricRepositoryProvider);
    return sbRepo.getLatestMetric();
  }

  final repo = ref.watch(bodyMetricRepositoryProvider);
  final raw = await repo.getLatestMetric();
  return raw != null ? BodyMetric.fromJson(raw) : null;
});

/// Weight data points for charting, sorted chronologically.
final weightHistoryProvider =
    FutureProvider<List<WeightDataPoint>>((ref) async {
  final source = ref.watch(dataSourceProvider);

  List<BodyMetric> metrics;
  if (source == DataSourceType.supabase) {
    final sbRepo = ref.watch(sbBodyMetricRepositoryProvider);
    metrics = await sbRepo.getAllMetrics();
  } else {
    final repo = ref.watch(bodyMetricRepositoryProvider);
    final rawMetrics = await repo.getAllMetrics();
    metrics = rawMetrics.map((m) => BodyMetric.fromJson(m)).toList();
  }

  // Sort chronologically (oldest first) for chart
  metrics.sort((a, b) => a.date.compareTo(b.date));
  return metrics
      .where((m) => m.weight != null)
      .map((m) => WeightDataPoint(date: m.date, weight: m.weight!))
      .toList();
});

// ─────────────────────────────────────────────────────────────────────────────
// Personal Records (from workout history)
// ─────────────────────────────────────────────────────────────────────────────

/// Personal records derived from all workout history.
final personalRecordsProvider =
    FutureProvider<List<PersonalRecord>>((ref) async {
  final source = ref.watch(dataSourceProvider);

  List<Workout> workouts;
  if (source == DataSourceType.supabase) {
    final sbRepo = ref.watch(sbWorkoutRepositoryProvider);
    workouts = await sbRepo.getWorkouts();
  } else {
    final repo = ref.watch(workoutRepositoryProvider);
    final rawWorkouts = await repo.getAllWorkouts();
    workouts = rawWorkouts.map((w) => Workout.fromJson(w)).toList();
  }

  // Track best weight per exercise
  final Map<String, PersonalRecord> bestByExercise = {};

  for (final workout in workouts) {
    for (final exercise in workout.exercises) {
      for (final set in exercise.sets) {
        if (set.isCompleted && !set.isWarmup && set.weight != null) {
          final key = exercise.exerciseName;
          final existing = bestByExercise[key];
          if (existing == null || set.weight! > existing.weight) {
            bestByExercise[key] = PersonalRecord(
              exerciseName: exercise.exerciseName,
              weight: set.weight!,
              reps: set.reps ?? 1,
              date: workout.date,
            );
          }
        }
      }
    }
  }

  final records = bestByExercise.values.toList();
  records.sort((a, b) => b.weight.compareTo(a.weight));
  return records;
});

// ─────────────────────────────────────────────────────────────────────────────
// Training Stats (aggregate)
// ─────────────────────────────────────────────────────────────────────────────

/// Aggregate training statistics.
final trainingStatsProvider =
    FutureProvider<TrainingStats>((ref) async {
  final source = ref.watch(dataSourceProvider);

  List<Workout> workouts;
  if (source == DataSourceType.supabase) {
    final sbRepo = ref.watch(sbWorkoutRepositoryProvider);
    workouts = await sbRepo.getWorkouts();
  } else {
    final repo = ref.watch(workoutRepositoryProvider);
    final rawWorkouts = await repo.getAllWorkouts();
    workouts = rawWorkouts.map((w) => Workout.fromJson(w)).toList();
  }

  if (workouts.isEmpty) {
    return TrainingStats.empty();
  }

  final completedWorkouts =
      workouts.where((w) => w.isCompleted).toList();

  final totalVolume =
      completedWorkouts.fold<double>(0, (sum, w) => sum + w.totalVolume);

  final totalDurationMinutes = completedWorkouts.fold<int>(
    0,
    (sum, w) => sum + (w.durationSeconds ~/ 60),
  );

  final avgDuration = completedWorkouts.isNotEmpty
      ? totalDurationMinutes ~/ completedWorkouts.length
      : 0;

  // Calculate streak
  completedWorkouts.sort((a, b) => b.date.compareTo(a.date));
  int streak = 0;
  if (completedWorkouts.isNotEmpty) {
    DateTime checkDate = DateTime.now();
    for (int i = 0; i < 365; i++) {
      final dayStart = DateTime(checkDate.year, checkDate.month, checkDate.day);
      final hasWorkout = completedWorkouts.any((w) {
        final wd = DateTime(w.date.year, w.date.month, w.date.day);
        return wd == dayStart;
      });
      if (hasWorkout) {
        streak++;
      } else if (i > 0) {
        break;
      }
      checkDate = checkDate.subtract(const Duration(days: 1));
    }
  }

  // Most trained muscle
  final Map<String, int> muscleCount = {};
  for (final w in completedWorkouts) {
    for (final e in w.exercises) {
      final name = e.primaryMuscle.displayName;
      muscleCount[name] = (muscleCount[name] ?? 0) + e.completedSets;
    }
  }
  String mostTrained = 'N/A';
  if (muscleCount.isNotEmpty) {
    mostTrained = muscleCount.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;
  }

  // Days since started
  final earliest =
      completedWorkouts.isNotEmpty ? completedWorkouts.last.date : DateTime.now();
  final daysSinceStart =
      DateTime.now().difference(earliest).inDays;

  return TrainingStats(
    totalWorkouts: completedWorkouts.length,
    totalVolume: totalVolume,
    trainingStreak: streak,
    averageDurationMinutes: avgDuration,
    mostTrainedMuscle: mostTrained,
    daysSinceStarted: daysSinceStart,
  );
});

// ─────────────────────────────────────────────────────────────────────────────
// Data Models
// ─────────────────────────────────────────────────────────────────────────────

class WeightDataPoint {
  final DateTime date;
  final double weight;

  const WeightDataPoint({required this.date, required this.weight});
}

class PersonalRecord {
  final String exerciseName;
  final double weight;
  final int reps;
  final DateTime date;

  const PersonalRecord({
    required this.exerciseName,
    required this.weight,
    required this.reps,
    required this.date,
  });
}

class TrainingStats {
  final int totalWorkouts;
  final double totalVolume;
  final int trainingStreak;
  final int averageDurationMinutes;
  final String mostTrainedMuscle;
  final int daysSinceStarted;

  const TrainingStats({
    required this.totalWorkouts,
    required this.totalVolume,
    required this.trainingStreak,
    required this.averageDurationMinutes,
    required this.mostTrainedMuscle,
    required this.daysSinceStarted,
  });

  factory TrainingStats.empty() => const TrainingStats(
        totalWorkouts: 0,
        totalVolume: 0,
        trainingStreak: 0,
        averageDurationMinutes: 0,
        mostTrainedMuscle: 'N/A',
        daysSinceStarted: 0,
      );
}
