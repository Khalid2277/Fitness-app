import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alfanutrition/data/models/enums.dart' as enums;
import 'package:alfanutrition/data/services/plan_generator_service.dart';
import 'package:alfanutrition/data/repositories/plan_repository.dart';
import 'package:alfanutrition/data/supabase/data_source.dart';
import 'package:alfanutrition/data/supabase/supabase_providers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Repository provider
// ─────────────────────────────────────────────────────────────────────────────

final planRepositoryProvider = Provider<PlanRepository>((ref) {
  return PlanRepository();
});

// ─────────────────────────────────────────────────────────────────────────────
// Saved plans provider — auto-selects Supabase or Hive
// ─────────────────────────────────────────────────────────────────────────────

final savedPlansProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final source = ref.watch(dataSourceProvider);

  if (source == DataSourceType.supabase) {
    final sbRepo = ref.watch(sbPlanRepositoryProvider);
    final plans = await sbRepo.getAllPlans();
    return plans.map((p) => p.toJson()).toList();
  }

  final repo = ref.watch(planRepositoryProvider);
  final plans = await repo.getAllPlans();
  plans.sort((a, b) {
    final aDate = DateTime.tryParse(a['createdAt'] ?? '') ?? DateTime(2000);
    final bDate = DateTime.tryParse(b['createdAt'] ?? '') ?? DateTime(2000);
    return bDate.compareTo(aDate);
  });
  return plans;
});

// ─────────────────────────────────────────────────────────────────────────────
// Plan generator form state
// ─────────────────────────────────────────────────────────────────────────────

class PlanGeneratorState {
  final enums.WorkoutGoal? goal;
  final enums.ExperienceLevel? experienceLevel;
  final int daysPerWeek;
  final enums.SplitType? splitType;
  final Set<enums.EquipmentType> equipment;
  final bool isGym;
  final bool isGenerating;
  final String? error;

  const PlanGeneratorState({
    this.goal,
    this.experienceLevel,
    this.daysPerWeek = 4,
    this.splitType,
    this.equipment = const {},
    this.isGym = true,
    this.isGenerating = false,
    this.error,
  });

  PlanGeneratorState copyWith({
    enums.WorkoutGoal? goal,
    enums.ExperienceLevel? experienceLevel,
    int? daysPerWeek,
    enums.SplitType? splitType,
    Set<enums.EquipmentType>? equipment,
    bool? isGym,
    bool? isGenerating,
    String? error,
  }) {
    return PlanGeneratorState(
      goal: goal ?? this.goal,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      daysPerWeek: daysPerWeek ?? this.daysPerWeek,
      splitType: splitType ?? this.splitType,
      equipment: equipment ?? this.equipment,
      isGym: isGym ?? this.isGym,
      isGenerating: isGenerating ?? this.isGenerating,
      error: error,
    );
  }

  bool get isValid =>
      goal != null &&
      experienceLevel != null &&
      splitType != null &&
      equipment.isNotEmpty;
}

class PlanGeneratorNotifier extends StateNotifier<PlanGeneratorState> {
  PlanGeneratorNotifier() : super(const PlanGeneratorState());

  void setGoal(enums.WorkoutGoal goal) =>
      state = state.copyWith(goal: goal);

  void setExperienceLevel(enums.ExperienceLevel level) =>
      state = state.copyWith(experienceLevel: level);

  void setDaysPerWeek(int days) =>
      state = state.copyWith(daysPerWeek: days);

  void setSplitType(enums.SplitType split) =>
      state = state.copyWith(splitType: split);

  void toggleEquipment(enums.EquipmentType type) {
    final updated = Set<enums.EquipmentType>.from(state.equipment);
    if (updated.contains(type)) {
      updated.remove(type);
    } else {
      updated.add(type);
    }
    state = state.copyWith(equipment: updated);
  }

  void setIsGym(bool isGym) {
    state = state.copyWith(isGym: isGym);
    if (!isGym) {
      // Home workout defaults
      state = state.copyWith(
        equipment: {
          enums.EquipmentType.dumbbell,
          enums.EquipmentType.bodyweight,
          enums.EquipmentType.resistanceBand,
        },
      );
    }
  }

  void setGenerating(bool generating) =>
      state = state.copyWith(isGenerating: generating);

  void setError(String? error) =>
      state = state.copyWith(error: error);

  void reset() => state = const PlanGeneratorState();
}

final planGeneratorProvider =
    StateNotifierProvider<PlanGeneratorNotifier, PlanGeneratorState>((ref) {
  return PlanGeneratorNotifier();
});

// ─────────────────────────────────────────────────────────────────────────────
// Generated plan provider
// ─────────────────────────────────────────────────────────────────────────────

final generatedPlanProvider =
    StateProvider<Map<String, dynamic>?>((ref) => null);

// ─────────────────────────────────────────────────────────────────────────────
// Service provider
// ─────────────────────────────────────────────────────────────────────────────

final planGeneratorServiceProvider = Provider<PlanGeneratorService>((ref) {
  return PlanGeneratorService();
});

// ─────────────────────────────────────────────────────────────────────────────
// Helper: convert app enums to service enums
// ─────────────────────────────────────────────────────────────────────────────

TrainingGoal toServiceGoal(enums.WorkoutGoal goal) {
  switch (goal) {
    case enums.WorkoutGoal.fatLoss:
      return TrainingGoal.fatLoss;
    case enums.WorkoutGoal.hypertrophy:
      return TrainingGoal.hypertrophy;
    case enums.WorkoutGoal.strength:
      return TrainingGoal.strength;
    case enums.WorkoutGoal.generalFitness:
      return TrainingGoal.hypertrophy;
    case enums.WorkoutGoal.endurance:
      return TrainingGoal.endurance;
  }
}

ExperienceLevel toServiceExperience(enums.ExperienceLevel level) {
  switch (level) {
    case enums.ExperienceLevel.beginner:
      return ExperienceLevel.beginner;
    case enums.ExperienceLevel.intermediate:
      return ExperienceLevel.intermediate;
    case enums.ExperienceLevel.advanced:
      return ExperienceLevel.advanced;
  }
}

SplitType toServiceSplit(enums.SplitType split) {
  switch (split) {
    case enums.SplitType.pushPullLegs:
      return SplitType.pushPullLegs;
    case enums.SplitType.upperLower:
      return SplitType.upperLower;
    case enums.SplitType.broSplit:
      return SplitType.broSplit;
    case enums.SplitType.fullBody:
      return SplitType.fullBody;
    case enums.SplitType.arnoldSplit:
      return SplitType.arnoldSplit;
    case enums.SplitType.custom:
      return SplitType.fullBody;
  }
}
