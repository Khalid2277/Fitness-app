import 'package:alfanutrition/data/models/enums.dart';
import 'package:alfanutrition/data/models/food_item.dart';

/// Bidirectional mapping between Dart camelCase enum values and
/// Postgres snake_case enum strings.
///
/// Enums whose Dart `.name` already matches the DB value (e.g. `beginner`,
/// `compound`, `breakfast`) pass through directly. Only enums with
/// multi-word camelCase names need explicit maps.
abstract final class EnumMappers {
  // ─────────────────────────── MuscleGroup ────────────────────────────────

  static const _muscleGroupToDb = <MuscleGroup, String>{
    MuscleGroup.hipFlexors: 'hip_flexors',
  };

  static const _muscleGroupFromDb = <String, MuscleGroup>{
    'hip_flexors': MuscleGroup.hipFlexors,
  };

  static String muscleGroupToDb(MuscleGroup value) =>
      _muscleGroupToDb[value] ?? value.name;

  static MuscleGroup muscleGroupFromDb(String value) =>
      _muscleGroupFromDb[value] ?? MuscleGroup.values.byName(value);

  // ─────────────────────────── EquipmentType ─────────────────────────────

  static const _equipmentToDb = <EquipmentType, String>{
    EquipmentType.resistanceBand: 'resistance_band',
    EquipmentType.smithMachine: 'smith_machine',
    EquipmentType.ezBar: 'ez_bar',
    EquipmentType.trapBar: 'trap_bar',
  };

  static const _equipmentFromDb = <String, EquipmentType>{
    'resistance_band': EquipmentType.resistanceBand,
    'smith_machine': EquipmentType.smithMachine,
    'ez_bar': EquipmentType.ezBar,
    'trap_bar': EquipmentType.trapBar,
  };

  static String equipmentTypeToDb(EquipmentType value) =>
      _equipmentToDb[value] ?? value.name;

  static EquipmentType equipmentTypeFromDb(String value) =>
      _equipmentFromDb[value] ?? EquipmentType.values.byName(value);

  // ─────────────────────────── ExerciseDifficulty ────────────────────────

  static String exerciseDifficultyToDb(ExerciseDifficulty value) => value.name;

  static ExerciseDifficulty exerciseDifficultyFromDb(String value) =>
      ExerciseDifficulty.values.byName(value);

  // ─────────────────────────── ExerciseCategory ──────────────────────────

  static String exerciseCategoryToDb(ExerciseCategory value) => value.name;

  static ExerciseCategory exerciseCategoryFromDb(String value) =>
      ExerciseCategory.values.byName(value);

  // ─────────────────────────── MealType ──────────────────────────────────

  static String mealTypeToDb(MealType value) => value.name;

  static MealType mealTypeFromDb(String value) =>
      MealType.values.byName(value);

  // ─────────────────────────── WorkoutGoal ───────────────────────────────

  static const _goalToDb = <WorkoutGoal, String>{
    WorkoutGoal.fatLoss: 'fat_loss',
    WorkoutGoal.generalFitness: 'general_fitness',
  };

  static const _goalFromDb = <String, WorkoutGoal>{
    'fat_loss': WorkoutGoal.fatLoss,
    'general_fitness': WorkoutGoal.generalFitness,
  };

  static String workoutGoalToDb(WorkoutGoal value) =>
      _goalToDb[value] ?? value.name;

  static WorkoutGoal workoutGoalFromDb(String value) =>
      _goalFromDb[value] ?? WorkoutGoal.values.byName(value);

  // ─────────────────────────── ExperienceLevel ───────────────────────────

  static String experienceLevelToDb(ExperienceLevel value) => value.name;

  static ExperienceLevel experienceLevelFromDb(String value) =>
      ExperienceLevel.values.byName(value);

  // ─────────────────────────── SplitType ─────────────────────────────────

  static const _splitToDb = <SplitType, String>{
    SplitType.pushPullLegs: 'push_pull_legs',
    SplitType.upperLower: 'upper_lower',
    SplitType.broSplit: 'bro_split',
    SplitType.fullBody: 'full_body',
    SplitType.arnoldSplit: 'arnold_split',
  };

  static const _splitFromDb = <String, SplitType>{
    'push_pull_legs': SplitType.pushPullLegs,
    'upper_lower': SplitType.upperLower,
    'bro_split': SplitType.broSplit,
    'full_body': SplitType.fullBody,
    'arnold_split': SplitType.arnoldSplit,
  };

  static String splitTypeToDb(SplitType value) =>
      _splitToDb[value] ?? value.name;

  static SplitType splitTypeFromDb(String value) =>
      _splitFromDb[value] ?? SplitType.values.byName(value);

  // ─────────────────────────── Gender ────────────────────────────────────

  static String genderToDb(Gender value) => value.name;

  static Gender genderFromDb(String value) => Gender.values.byName(value);

  // ─────────────────────────── ActivityLevel ─────────────────────────────

  static const _activityToDb = <ActivityLevel, String>{
    ActivityLevel.lightlyActive: 'lightly_active',
    ActivityLevel.moderatelyActive: 'moderately_active',
    ActivityLevel.veryActive: 'very_active',
    ActivityLevel.extremelyActive: 'extremely_active',
  };

  static const _activityFromDb = <String, ActivityLevel>{
    'lightly_active': ActivityLevel.lightlyActive,
    'moderately_active': ActivityLevel.moderatelyActive,
    'very_active': ActivityLevel.veryActive,
    'extremely_active': ActivityLevel.extremelyActive,
  };

  static String activityLevelToDb(ActivityLevel value) =>
      _activityToDb[value] ?? value.name;

  static ActivityLevel activityLevelFromDb(String value) =>
      _activityFromDb[value] ?? ActivityLevel.values.byName(value);

  // ─────────────────────────── FoodCategory ──────────────────────────────

  static String foodCategoryToDb(FoodCategory value) => value.name;

  static FoodCategory foodCategoryFromDb(String value) =>
      FoodCategory.values.byName(value);
}
