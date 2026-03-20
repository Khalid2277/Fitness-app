import 'package:alfanutrition/data/models/enums.dart';
import 'package:alfanutrition/data/models/exercise.dart';
import 'package:alfanutrition/data/seed/exercise_database.dart';
import 'package:uuid/uuid.dart';

// ── Configuration types ──────────────────────────────────────────────────────

enum TrainingGoal { strength, hypertrophy, endurance, fatLoss }

enum ExperienceLevel { beginner, intermediate, advanced }

enum SplitType { pushPullLegs, upperLower, broSplit, fullBody, arnoldSplit }

/// Input configuration for plan generation.
class PlanConfig {
  final TrainingGoal goal;
  final ExperienceLevel experience;
  final int daysPerWeek;
  final SplitType splitType;
  final List<EquipmentType> availableEquipment;

  const PlanConfig({
    required this.goal,
    required this.experience,
    required this.daysPerWeek,
    required this.splitType,
    required this.availableEquipment,
  });
}

/// A single workout day within a plan.
class PlanDay {
  final String name;
  final List<PlannedExercise> exercises;

  const PlanDay({required this.name, required this.exercises});

  Map<String, dynamic> toMap() => {
        'name': name,
        'exercises': exercises.map((e) => e.toMap()).toList(),
      };
}

/// A single exercise entry in a plan day.
class PlannedExercise {
  final String exerciseId;
  final String exerciseName;
  final int sets;
  final String repRange;
  final int restSeconds;
  final String? notes;

  const PlannedExercise({
    required this.exerciseId,
    required this.exerciseName,
    required this.sets,
    required this.repRange,
    required this.restSeconds,
    this.notes,
  });

  Map<String, dynamic> toMap() => {
        'exerciseId': exerciseId,
        'exerciseName': exerciseName,
        'sets': sets,
        'repRange': repRange,
        'restSeconds': restSeconds,
        if (notes != null) 'notes': notes,
      };
}

// ── Service ──────────────────────────────────────────────────────────────────

/// Generates periodized workout plans based on user configuration.
class PlanGeneratorService {
  static const _uuid = Uuid();

  /// Generate a full workout plan and return it as a storable map.
  Map<String, dynamic> generatePlan(PlanConfig config) {
    final days = _buildSplit(config);

    return {
      'id': _uuid.v4(),
      'name': _planName(config),
      'goal': config.goal.name,
      'experience': config.experience.name,
      'splitType': config.splitType.name,
      'daysPerWeek': config.daysPerWeek,
      'days': days.map((d) => d.toMap()).toList(),
      'isActive': false,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  // ── Split builders ───────────────────────────────────────────────────────

  List<PlanDay> _buildSplit(PlanConfig config) {
    switch (config.splitType) {
      case SplitType.pushPullLegs:
        return _pushPullLegs(config);
      case SplitType.upperLower:
        return _upperLower(config);
      case SplitType.broSplit:
        return _broSplit(config);
      case SplitType.fullBody:
        return _fullBody(config);
      case SplitType.arnoldSplit:
        return _arnoldSplit(config);
    }
  }

  // ── Push / Pull / Legs ─────────────────────────────────────────────────

  List<PlanDay> _pushPullLegs(PlanConfig config) {
    final push = _buildDay(
      'Push (Chest / Shoulders / Triceps)',
      [MuscleGroup.chest, MuscleGroup.shoulders, MuscleGroup.triceps],
      config,
      compoundCount: 2,
      isolationCount: 3,
    );
    final pull = _buildDay(
      'Pull (Back / Biceps)',
      [MuscleGroup.back, MuscleGroup.lats, MuscleGroup.biceps, MuscleGroup.traps],
      config,
      compoundCount: 2,
      isolationCount: 3,
    );
    final legs = _buildDay(
      'Legs',
      [
        MuscleGroup.quadriceps,
        MuscleGroup.hamstrings,
        MuscleGroup.glutes,
        MuscleGroup.calves,
      ],
      config,
      compoundCount: 2,
      isolationCount: 3,
    );

    final cycle = [push, pull, legs];
    return _repeatToFit(cycle, config.daysPerWeek);
  }

  // ── Upper / Lower ─────────────────────────────────────────────────────

  List<PlanDay> _upperLower(PlanConfig config) {
    final upper = _buildDay(
      'Upper Body',
      [
        MuscleGroup.chest,
        MuscleGroup.back,
        MuscleGroup.shoulders,
        MuscleGroup.biceps,
        MuscleGroup.triceps,
      ],
      config,
      compoundCount: 3,
      isolationCount: 3,
    );
    final lower = _buildDay(
      'Lower Body',
      [
        MuscleGroup.quadriceps,
        MuscleGroup.hamstrings,
        MuscleGroup.glutes,
        MuscleGroup.calves,
        MuscleGroup.core,
      ],
      config,
      compoundCount: 3,
      isolationCount: 2,
    );

    final cycle = [upper, lower];
    return _repeatToFit(cycle, config.daysPerWeek);
  }

  // ── Bro Split ─────────────────────────────────────────────────────────

  List<PlanDay> _broSplit(PlanConfig config) {
    final chest = _buildDay(
      'Chest Day',
      [MuscleGroup.chest],
      config,
      compoundCount: 2,
      isolationCount: 3,
    );
    final back = _buildDay(
      'Back Day',
      [MuscleGroup.back, MuscleGroup.lats, MuscleGroup.traps],
      config,
      compoundCount: 2,
      isolationCount: 3,
    );
    final shoulders = _buildDay(
      'Shoulder Day',
      [MuscleGroup.shoulders],
      config,
      compoundCount: 2,
      isolationCount: 3,
    );
    final arms = _buildDay(
      'Arm Day',
      [MuscleGroup.biceps, MuscleGroup.triceps, MuscleGroup.forearms],
      config,
      compoundCount: 1,
      isolationCount: 4,
    );
    final legs = _buildDay(
      'Leg Day',
      [
        MuscleGroup.quadriceps,
        MuscleGroup.hamstrings,
        MuscleGroup.glutes,
        MuscleGroup.calves,
      ],
      config,
      compoundCount: 2,
      isolationCount: 3,
    );

    final cycle = [chest, back, shoulders, arms, legs];
    return _repeatToFit(cycle, config.daysPerWeek);
  }

  // ── Full Body ─────────────────────────────────────────────────────────

  List<PlanDay> _fullBody(PlanConfig config) {
    final days = <PlanDay>[];
    for (int i = 0; i < config.daysPerWeek; i++) {
      days.add(_buildDay(
        'Full Body – Day ${i + 1}',
        [
          MuscleGroup.chest,
          MuscleGroup.back,
          MuscleGroup.shoulders,
          MuscleGroup.quadriceps,
          MuscleGroup.hamstrings,
          MuscleGroup.core,
        ],
        config,
        compoundCount: 4,
        isolationCount: 2,
      ));
    }
    return days;
  }

  // ── Arnold Split ──────────────────────────────────────────────────────

  List<PlanDay> _arnoldSplit(PlanConfig config) {
    final chestBack = _buildDay(
      'Chest & Back',
      [MuscleGroup.chest, MuscleGroup.back, MuscleGroup.lats],
      config,
      compoundCount: 3,
      isolationCount: 3,
    );
    final shouldersArms = _buildDay(
      'Shoulders & Arms',
      [
        MuscleGroup.shoulders,
        MuscleGroup.biceps,
        MuscleGroup.triceps,
        MuscleGroup.forearms,
      ],
      config,
      compoundCount: 2,
      isolationCount: 4,
    );
    final legs = _buildDay(
      'Legs',
      [
        MuscleGroup.quadriceps,
        MuscleGroup.hamstrings,
        MuscleGroup.glutes,
        MuscleGroup.calves,
      ],
      config,
      compoundCount: 3,
      isolationCount: 2,
    );

    final cycle = [chestBack, shouldersArms, legs];
    return _repeatToFit(cycle, config.daysPerWeek);
  }

  // ── Core day-building logic ───────────────────────────────────────────

  PlanDay _buildDay(
    String name,
    List<MuscleGroup> targetMuscles,
    PlanConfig config, {
    required int compoundCount,
    required int isolationCount,
  }) {
    final scheme = _repScheme(config.goal);
    final availableExercises = exerciseDatabase.where((e) {
      final muscleMatch = targetMuscles.contains(e.primaryMuscle);
      final equipmentMatch = config.availableEquipment.contains(e.equipment);
      final difficultyMatch = _difficultyAllowed(e.difficulty, config.experience);
      return muscleMatch && equipmentMatch && difficultyMatch;
    }).toList();

    final compounds = availableExercises
        .where((e) => e.category == ExerciseCategory.compound)
        .toList();
    final isolations = availableExercises
        .where((e) => e.category == ExerciseCategory.isolation)
        .toList();

    final selected = <Exercise>[];

    // Pick compounds first (priority: cover different muscles).
    _pickExercises(compounds, targetMuscles, compoundCount, selected);
    // Fill remaining with isolations.
    _pickExercises(isolations, targetMuscles, isolationCount, selected);

    // If we didn't fill the quota, relax equipment constraint.
    if (selected.length < compoundCount + isolationCount) {
      final fallback = exerciseDatabase.where((e) {
        return targetMuscles.contains(e.primaryMuscle) &&
            _difficultyAllowed(e.difficulty, config.experience) &&
            !selected.contains(e);
      }).toList();
      final remaining = (compoundCount + isolationCount) - selected.length;
      _pickExercises(fallback, targetMuscles, remaining, selected);
    }

    final exercises = selected.map((e) {
      return PlannedExercise(
        exerciseId: e.id,
        exerciseName: e.name,
        sets: scheme.sets,
        repRange: scheme.repRange,
        restSeconds: scheme.restSeconds,
      );
    }).toList();

    return PlanDay(name: name, exercises: exercises);
  }

  void _pickExercises(
    List<Exercise> pool,
    List<MuscleGroup> targetMuscles,
    int count,
    List<Exercise> selected,
  ) {
    // Sort pool so each target muscle gets coverage before duplicating muscles.
    final coveredMuscles = <MuscleGroup>{};
    final sorted = List<Exercise>.from(pool);
    sorted.sort((a, b) {
      final aNew = coveredMuscles.contains(a.primaryMuscle) ? 1 : 0;
      final bNew = coveredMuscles.contains(b.primaryMuscle) ? 1 : 0;
      return aNew.compareTo(bNew);
    });

    for (final exercise in sorted) {
      if (selected.length >= selected.length + count &&
          selected.where((e) => pool.contains(e)).length >= count) {
        break;
      }
      if (selected.any((e) => e.id == exercise.id)) continue;
      selected.add(exercise);
      coveredMuscles.add(exercise.primaryMuscle);
      if (selected.where((e) => pool.contains(e)).length >= count) break;
    }
  }

  bool _difficultyAllowed(
    ExerciseDifficulty exerciseDifficulty,
    ExperienceLevel experience,
  ) {
    switch (experience) {
      case ExperienceLevel.beginner:
        return exerciseDifficulty == ExerciseDifficulty.beginner;
      case ExperienceLevel.intermediate:
        return exerciseDifficulty == ExerciseDifficulty.beginner ||
            exerciseDifficulty == ExerciseDifficulty.intermediate;
      case ExperienceLevel.advanced:
        return true;
    }
  }

  // ── Rep scheme per goal ───────────────────────────────────────────────

  _RepScheme _repScheme(TrainingGoal goal) {
    switch (goal) {
      case TrainingGoal.strength:
        return const _RepScheme(sets: 5, repRange: '3-5', restSeconds: 180);
      case TrainingGoal.hypertrophy:
        return const _RepScheme(sets: 4, repRange: '8-12', restSeconds: 90);
      case TrainingGoal.endurance:
        return const _RepScheme(sets: 3, repRange: '15-20', restSeconds: 45);
      case TrainingGoal.fatLoss:
        return const _RepScheme(sets: 3, repRange: '12-15', restSeconds: 30);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  List<PlanDay> _repeatToFit(List<PlanDay> cycle, int daysPerWeek) {
    final result = <PlanDay>[];
    for (int i = 0; i < daysPerWeek; i++) {
      result.add(cycle[i % cycle.length]);
    }
    return result;
  }

  String _planName(PlanConfig config) {
    final splitName = switch (config.splitType) {
      SplitType.pushPullLegs => 'Push/Pull/Legs',
      SplitType.upperLower => 'Upper/Lower',
      SplitType.broSplit => 'Bro Split',
      SplitType.fullBody => 'Full Body',
      SplitType.arnoldSplit => 'Arnold Split',
    };
    final goalName = switch (config.goal) {
      TrainingGoal.strength => 'Strength',
      TrainingGoal.hypertrophy => 'Hypertrophy',
      TrainingGoal.endurance => 'Endurance',
      TrainingGoal.fatLoss => 'Fat Loss',
    };
    return '$splitName – $goalName (${config.daysPerWeek}x/week)';
  }
}

class _RepScheme {
  final int sets;
  final String repRange;
  final int restSeconds;

  const _RepScheme({
    required this.sets,
    required this.repRange,
    required this.restSeconds,
  });
}
