import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:alfanutrition/data/models/workout.dart';
import 'package:alfanutrition/data/models/workout_exercise.dart';
import 'package:alfanutrition/data/models/exercise_set.dart';
import 'package:alfanutrition/data/models/enums.dart';
import 'package:alfanutrition/data/repositories/workout_repository.dart';
import 'package:alfanutrition/data/supabase/data_source.dart';
import 'package:alfanutrition/data/supabase/supabase_providers.dart';

// ─────────────────────────── Repository ───────────────────────────

final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  return WorkoutRepository();
});

// ─────────────────────────── Workout History ───────────────────────────

final workoutHistoryProvider =
    StateNotifierProvider<WorkoutHistoryNotifier, AsyncValue<List<Workout>>>(
  (ref) {
    final source = ref.watch(dataSourceProvider);
    return WorkoutHistoryNotifier(
      ref.watch(workoutRepositoryProvider),
      source == DataSourceType.supabase
          ? ref.watch(sbWorkoutRepositoryProvider)
          : null,
    );
  },
);

class WorkoutHistoryNotifier extends StateNotifier<AsyncValue<List<Workout>>> {
  final WorkoutRepository _localRepo;
  final dynamic _sbRepo; // SbWorkoutRepository or null

  WorkoutHistoryNotifier(this._localRepo, this._sbRepo)
      : super(const AsyncValue.loading()) {
    loadWorkouts();
  }

  Future<void> loadWorkouts() async {
    state = const AsyncValue.loading();
    try {
      if (_sbRepo != null) {
        final workouts = await _sbRepo.getWorkouts();
        state = AsyncValue.data(workouts);
      } else {
        final maps = await _localRepo.getAllWorkouts();
        final workouts = maps.map((m) => Workout.fromJson(m)).toList()
          ..sort((a, b) => b.date.compareTo(a.date));
        state = AsyncValue.data(workouts);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addWorkout(Workout workout) async {
    if (_sbRepo != null) {
      await _sbRepo.saveWorkout(workout);
    } else {
      await _localRepo.saveWorkout(workout.toJson());
    }
    await loadWorkouts();
  }

  Future<void> deleteWorkout(String id) async {
    if (_sbRepo != null) {
      await _sbRepo.deleteWorkout(id);
    } else {
      await _localRepo.deleteWorkout(id);
    }
    await loadWorkouts();
  }
}

// ─────────────────────────── Workout Stats ───────────────────────────

class WorkoutStats {
  final int totalWorkouts;
  final int thisWeek;
  final int streak;

  const WorkoutStats({
    required this.totalWorkouts,
    required this.thisWeek,
    required this.streak,
  });
}

final workoutStatsProvider = Provider<WorkoutStats>((ref) {
  final historyAsync = ref.watch(workoutHistoryProvider);
  return historyAsync.when(
    data: (workouts) {
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final weekStart = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);

      final thisWeek = workouts
          .where((w) => w.date.isAfter(weekStart) && w.isCompleted)
          .length;

      // Calculate streak (consecutive days with workouts, going backwards)
      int streak = 0;
      var checkDate = DateTime(now.year, now.month, now.day);
      final workoutDates = workouts
          .where((w) => w.isCompleted)
          .map((w) => DateTime(w.date.year, w.date.month, w.date.day))
          .toSet();

      while (workoutDates.contains(checkDate)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      }

      return WorkoutStats(
        totalWorkouts: workouts.where((w) => w.isCompleted).length,
        thisWeek: thisWeek,
        streak: streak,
      );
    },
    loading: () => const WorkoutStats(totalWorkouts: 0, thisWeek: 0, streak: 0),
    error: (_, _) => const WorkoutStats(totalWorkouts: 0, thisWeek: 0, streak: 0),
  );
});

// ─────────────────────────── Active Workout ───────────────────────────

class ActiveWorkoutState {
  final String id;
  final String name;
  final DateTime startTime;
  final List<WorkoutExercise> exercises;
  final String? notes;
  final bool isActive;

  ActiveWorkoutState({
    required this.id,
    required this.name,
    required this.startTime,
    required this.exercises,
    this.notes,
    this.isActive = true,
  });

  ActiveWorkoutState copyWith({
    String? id,
    String? name,
    DateTime? startTime,
    List<WorkoutExercise>? exercises,
    String? notes,
    bool? isActive,
  }) {
    return ActiveWorkoutState(
      id: id ?? this.id,
      name: name ?? this.name,
      startTime: startTime ?? this.startTime,
      exercises: exercises ?? this.exercises,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
    );
  }
}

final activeWorkoutProvider =
    StateNotifierProvider<ActiveWorkoutNotifier, ActiveWorkoutState?>((ref) {
  return ActiveWorkoutNotifier();
});

class ActiveWorkoutNotifier extends StateNotifier<ActiveWorkoutState?> {
  ActiveWorkoutNotifier() : super(null);

  static const _uuid = Uuid();

  void startWorkout({String name = 'Workout'}) {
    state = ActiveWorkoutState(
      id: _uuid.v4(),
      name: name,
      startTime: DateTime.now(),
      exercises: [],
    );
  }

  void updateName(String name) {
    if (state == null) return;
    state = state!.copyWith(name: name);
  }

  void updateNotes(String notes) {
    if (state == null) return;
    state = state!.copyWith(notes: notes);
  }

  void addExercise({
    required String exerciseId,
    required String exerciseName,
    required MuscleGroup primaryMuscle,
  }) {
    if (state == null) return;
    final exercise = WorkoutExercise(
      id: _uuid.v4(),
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      sets: [
        ExerciseSet(setNumber: 1),
      ],
      primaryMuscle: primaryMuscle,
    );
    state = state!.copyWith(
      exercises: [...state!.exercises, exercise],
    );
  }

  void removeExercise(int exerciseIndex) {
    if (state == null) return;
    final exercises = List<WorkoutExercise>.from(state!.exercises);
    exercises.removeAt(exerciseIndex);
    state = state!.copyWith(exercises: exercises);
  }

  void addSet(int exerciseIndex) {
    if (state == null) return;
    final exercises = List<WorkoutExercise>.from(state!.exercises);
    final exercise = exercises[exerciseIndex];
    final newSetNumber = exercise.sets.length + 1;

    // Copy weight/reps from the last set if available
    final lastSet = exercise.sets.isNotEmpty ? exercise.sets.last : null;
    final newSet = ExerciseSet(
      setNumber: newSetNumber,
      weight: lastSet?.weight,
      reps: lastSet?.reps,
    );

    exercises[exerciseIndex] = exercise.copyWith(
      sets: [...exercise.sets, newSet],
    );
    state = state!.copyWith(exercises: exercises);
  }

  void removeSet(int exerciseIndex, int setIndex) {
    if (state == null) return;
    final exercises = List<WorkoutExercise>.from(state!.exercises);
    final exercise = exercises[exerciseIndex];
    final sets = List<ExerciseSet>.from(exercise.sets);
    sets.removeAt(setIndex);

    // Re-number sets
    for (int i = 0; i < sets.length; i++) {
      sets[i] = sets[i].copyWith(setNumber: i + 1);
    }

    exercises[exerciseIndex] = exercise.copyWith(sets: sets);
    state = state!.copyWith(exercises: exercises);
  }

  void updateSet(int exerciseIndex, int setIndex, ExerciseSet updatedSet) {
    if (state == null) return;
    final exercises = List<WorkoutExercise>.from(state!.exercises);
    final exercise = exercises[exerciseIndex];
    final sets = List<ExerciseSet>.from(exercise.sets);
    sets[setIndex] = updatedSet;
    exercises[exerciseIndex] = exercise.copyWith(sets: sets);
    state = state!.copyWith(exercises: exercises);
  }

  void updateExerciseNotes(int exerciseIndex, String notes) {
    if (state == null) return;
    final exercises = List<WorkoutExercise>.from(state!.exercises);
    exercises[exerciseIndex] = exercises[exerciseIndex].copyWith(notes: notes);
    state = state!.copyWith(exercises: exercises);
  }

  Workout? finishWorkout() {
    if (state == null) return null;
    final elapsed = DateTime.now().difference(state!.startTime);
    final workout = Workout(
      id: state!.id,
      name: state!.name,
      date: state!.startTime,
      durationSeconds: elapsed.inSeconds,
      exercises: state!.exercises,
      notes: state!.notes,
      isCompleted: true,
    );
    state = null;
    return workout;
  }

  void cancelWorkout() {
    state = null;
  }
}

// ─────────────────────────── Selected Workout Date ───────────────────────────

/// Currently selected date in the workout diary.
final selectedWorkoutDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

/// Workouts for the selected date.
final workoutsForDateProvider = Provider<List<Workout>>((ref) {
  final date = ref.watch(selectedWorkoutDateProvider);
  final historyAsync = ref.watch(workoutHistoryProvider);
  return historyAsync.when(
    data: (workouts) => workouts.where((w) {
      return w.date.year == date.year &&
          w.date.month == date.month &&
          w.date.day == date.day;
    }).toList(),
    loading: () => [],
    error: (_, _) => [],
  );
});

/// Daily workout summary for the selected date.
class DailyWorkoutSummary {
  final int workoutCount;
  final int totalSets;
  final double totalVolume;
  final int totalDurationSeconds;
  final Set<MuscleGroup> musclesHit;

  const DailyWorkoutSummary({
    required this.workoutCount,
    required this.totalSets,
    required this.totalVolume,
    required this.totalDurationSeconds,
    required this.musclesHit,
  });

  String get formattedDuration {
    final d = Duration(seconds: totalDurationSeconds);
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }
}

final dailyWorkoutSummaryProvider = Provider<DailyWorkoutSummary>((ref) {
  final workouts = ref.watch(workoutsForDateProvider);
  if (workouts.isEmpty) {
    return const DailyWorkoutSummary(
      workoutCount: 0,
      totalSets: 0,
      totalVolume: 0,
      totalDurationSeconds: 0,
      musclesHit: {},
    );
  }
  return DailyWorkoutSummary(
    workoutCount: workouts.length,
    totalSets: workouts.fold(0, (s, w) => s + w.totalSets),
    totalVolume: workouts.fold(0.0, (s, w) => s + w.totalVolume),
    totalDurationSeconds: workouts.fold(0, (s, w) => s + w.durationSeconds),
    musclesHit: workouts.fold<Set<MuscleGroup>>(
        {}, (s, w) => s..addAll(w.musclesHit)),
  );
});

// ─────────────────────────── Single Workout Lookup ───────────────────────────

final workoutByIdProvider =
    FutureProvider.family<Workout?, String>((ref, id) async {
  final source = ref.watch(dataSourceProvider);

  // Try Supabase first if configured
  if (source == DataSourceType.supabase) {
    try {
      final sbRepo = ref.watch(sbWorkoutRepositoryProvider);
      final workouts = await sbRepo.getWorkouts();
      final match = workouts.where((w) => w.id == id);
      if (match.isNotEmpty) return match.first;
    } catch (_) {
      // Fall through to local
    }
  }

  // Local Hive lookup
  final repo = ref.watch(workoutRepositoryProvider);
  final map = await repo.getWorkout(id);
  if (map == null) return null;
  return Workout.fromJson(map);
});
