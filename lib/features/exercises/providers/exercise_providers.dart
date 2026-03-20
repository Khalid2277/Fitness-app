import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alfanutrition/data/models/enums.dart';
import 'package:alfanutrition/data/models/exercise.dart';
import 'package:alfanutrition/data/seed/exercise_database.dart';
import 'package:alfanutrition/data/supabase/data_source.dart';
import 'package:alfanutrition/data/supabase/supabase_providers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Search query state
// ─────────────────────────────────────────────────────────────────────────────

final exerciseSearchProvider = StateProvider<String>((ref) => '');

// ─────────────────────────────────────────────────────────────────────────────
// Filter state
// ─────────────────────────────────────────────────────────────────────────────

class ExerciseFilter {
  final MuscleGroup? muscleGroup;
  final EquipmentType? equipment;
  final ExerciseDifficulty? difficulty;

  const ExerciseFilter({
    this.muscleGroup,
    this.equipment,
    this.difficulty,
  });

  ExerciseFilter copyWith({
    MuscleGroup? muscleGroup,
    EquipmentType? equipment,
    ExerciseDifficulty? difficulty,
    bool clearMuscle = false,
    bool clearEquipment = false,
    bool clearDifficulty = false,
  }) {
    return ExerciseFilter(
      muscleGroup: clearMuscle ? null : (muscleGroup ?? this.muscleGroup),
      equipment: clearEquipment ? null : (equipment ?? this.equipment),
      difficulty: clearDifficulty ? null : (difficulty ?? this.difficulty),
    );
  }

  bool get hasActiveFilters =>
      muscleGroup != null || equipment != null || difficulty != null;
}

final exerciseFilterProvider =
    StateProvider<ExerciseFilter>((ref) => const ExerciseFilter());

// ─────────────────────────────────────────────────────────────────────────────
// Sort mode
// ─────────────────────────────────────────────────────────────────────────────

enum ExerciseSortMode { alphabetical, muscleGroup, difficulty }

final exerciseSortProvider =
    StateProvider<ExerciseSortMode>((ref) => ExerciseSortMode.alphabetical);

// ─────────────────────────────────────────────────────────────────────────────
// Master exercise list — Supabase if online, local seed if offline
// ─────────────────────────────────────────────────────────────────────────────

final allExercisesProvider = FutureProvider<List<Exercise>>((ref) async {
  final source = ref.watch(dataSourceProvider);

  if (source == DataSourceType.supabase) {
    try {
      final sbRepo = ref.watch(sbExerciseRepositoryProvider);
      return await sbRepo.getAllExercises();
    } catch (_) {
      // Fallback to local on error
    }
  }

  return exerciseDatabase;
});

// ─────────────────────────────────────────────────────────────────────────────
// Filtered + sorted exercise list
// ─────────────────────────────────────────────────────────────────────────────

final exerciseListProvider = Provider<List<Exercise>>((ref) {
  final query = ref.watch(exerciseSearchProvider).toLowerCase();
  final filter = ref.watch(exerciseFilterProvider);
  final sortMode = ref.watch(exerciseSortProvider);

  // Use Supabase exercises if available, otherwise local database
  final allExercises = ref.watch(allExercisesProvider);
  var list = List<Exercise>.from(
    allExercises.valueOrNull ?? exerciseDatabase,
  );

  // Search filter
  if (query.isNotEmpty) {
    list = list
        .where((e) =>
            e.name.toLowerCase().contains(query) ||
            e.primaryMuscle.displayName.toLowerCase().contains(query) ||
            e.description.toLowerCase().contains(query))
        .toList();
  }

  // Muscle group filter
  if (filter.muscleGroup != null) {
    list = list
        .where((e) =>
            e.primaryMuscle == filter.muscleGroup ||
            e.secondaryMuscles.contains(filter.muscleGroup))
        .toList();
  }

  // Equipment filter
  if (filter.equipment != null) {
    list = list.where((e) => e.equipment == filter.equipment).toList();
  }

  // Difficulty filter
  if (filter.difficulty != null) {
    list = list.where((e) => e.difficulty == filter.difficulty).toList();
  }

  // Sort
  switch (sortMode) {
    case ExerciseSortMode.alphabetical:
      list.sort((a, b) => a.name.compareTo(b.name));
    case ExerciseSortMode.muscleGroup:
      list.sort((a, b) =>
          a.primaryMuscle.displayName.compareTo(b.primaryMuscle.displayName));
    case ExerciseSortMode.difficulty:
      list.sort((a, b) => a.difficulty.index.compareTo(b.difficulty.index));
  }

  return list;
});

// ─────────────────────────────────────────────────────────────────────────────
// Single exercise by ID
// ─────────────────────────────────────────────────────────────────────────────

final exerciseByIdProvider =
    Provider.family<Exercise?, String>((ref, id) {
  return findExerciseById(id);
});
