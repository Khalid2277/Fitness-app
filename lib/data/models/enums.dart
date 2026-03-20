import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MuscleGroup
// ─────────────────────────────────────────────────────────────────────────────

@HiveType(typeId: 0)
enum MuscleGroup {
  @HiveField(0)
  chest,
  @HiveField(1)
  back,
  @HiveField(2)
  shoulders,
  @HiveField(3)
  biceps,
  @HiveField(4)
  triceps,
  @HiveField(5)
  forearms,
  @HiveField(6)
  quadriceps,
  @HiveField(7)
  hamstrings,
  @HiveField(8)
  glutes,
  @HiveField(9)
  calves,
  @HiveField(10)
  core,
  @HiveField(11)
  traps,
  @HiveField(12)
  lats,
  @HiveField(13)
  obliques,
  @HiveField(14)
  hipFlexors,
  @HiveField(15)
  adductors,
  @HiveField(16)
  abductors;

  String get displayName {
    switch (this) {
      case MuscleGroup.chest:
        return 'Chest';
      case MuscleGroup.back:
        return 'Back';
      case MuscleGroup.shoulders:
        return 'Shoulders';
      case MuscleGroup.biceps:
        return 'Biceps';
      case MuscleGroup.triceps:
        return 'Triceps';
      case MuscleGroup.forearms:
        return 'Forearms';
      case MuscleGroup.quadriceps:
        return 'Quadriceps';
      case MuscleGroup.hamstrings:
        return 'Hamstrings';
      case MuscleGroup.glutes:
        return 'Glutes';
      case MuscleGroup.calves:
        return 'Calves';
      case MuscleGroup.core:
        return 'Core';
      case MuscleGroup.traps:
        return 'Traps';
      case MuscleGroup.lats:
        return 'Lats';
      case MuscleGroup.obliques:
        return 'Obliques';
      case MuscleGroup.hipFlexors:
        return 'Hip Flexors';
      case MuscleGroup.adductors:
        return 'Adductors';
      case MuscleGroup.abductors:
        return 'Abductors';
    }
  }

  IconData get icon {
    switch (this) {
      case MuscleGroup.chest:
        return Icons.expand;
      case MuscleGroup.back:
        return Icons.airline_seat_flat;
      case MuscleGroup.shoulders:
        return Icons.accessibility_new;
      case MuscleGroup.biceps:
        return Icons.fitness_center;
      case MuscleGroup.triceps:
        return Icons.sports_martial_arts;
      case MuscleGroup.forearms:
        return Icons.front_hand;
      case MuscleGroup.quadriceps:
        return Icons.directions_walk;
      case MuscleGroup.hamstrings:
        return Icons.directions_run;
      case MuscleGroup.glutes:
        return Icons.chair;
      case MuscleGroup.calves:
        return Icons.do_not_step;
      case MuscleGroup.core:
        return Icons.shield;
      case MuscleGroup.traps:
        return Icons.expand_less;
      case MuscleGroup.lats:
        return Icons.open_with;
      case MuscleGroup.obliques:
        return Icons.rotate_left;
      case MuscleGroup.hipFlexors:
        return Icons.swap_vert;
      case MuscleGroup.adductors:
        return Icons.compress;
      case MuscleGroup.abductors:
        return Icons.open_in_full;
    }
  }
}

class MuscleGroupAdapter extends TypeAdapter<MuscleGroup> {
  @override
  final int typeId = 0;

  @override
  MuscleGroup read(BinaryReader reader) {
    final index = reader.readByte();
    return MuscleGroup.values[index];
  }

  @override
  void write(BinaryWriter writer, MuscleGroup obj) {
    writer.writeByte(obj.index);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EquipmentType
// ─────────────────────────────────────────────────────────────────────────────

@HiveType(typeId: 1)
enum EquipmentType {
  @HiveField(0)
  barbell,
  @HiveField(1)
  dumbbell,
  @HiveField(2)
  cable,
  @HiveField(3)
  machine,
  @HiveField(4)
  bodyweight,
  @HiveField(5)
  kettlebell,
  @HiveField(6)
  resistanceBand,
  @HiveField(7)
  smithMachine,
  @HiveField(8)
  ezBar,
  @HiveField(9)
  trapBar;

  String get displayName {
    switch (this) {
      case EquipmentType.barbell:
        return 'Barbell';
      case EquipmentType.dumbbell:
        return 'Dumbbell';
      case EquipmentType.cable:
        return 'Cable';
      case EquipmentType.machine:
        return 'Machine';
      case EquipmentType.bodyweight:
        return 'Bodyweight';
      case EquipmentType.kettlebell:
        return 'Kettlebell';
      case EquipmentType.resistanceBand:
        return 'Resistance Band';
      case EquipmentType.smithMachine:
        return 'Smith Machine';
      case EquipmentType.ezBar:
        return 'EZ Bar';
      case EquipmentType.trapBar:
        return 'Trap Bar';
    }
  }

  IconData get icon {
    switch (this) {
      case EquipmentType.barbell:
        return Icons.fitness_center;
      case EquipmentType.dumbbell:
        return Icons.fitness_center;
      case EquipmentType.cable:
        return Icons.cable;
      case EquipmentType.machine:
        return Icons.precision_manufacturing;
      case EquipmentType.bodyweight:
        return Icons.self_improvement;
      case EquipmentType.kettlebell:
        return Icons.sports_handball;
      case EquipmentType.resistanceBand:
        return Icons.straighten;
      case EquipmentType.smithMachine:
        return Icons.view_column;
      case EquipmentType.ezBar:
        return Icons.fitness_center;
      case EquipmentType.trapBar:
        return Icons.hexagon;
    }
  }
}

class EquipmentTypeAdapter extends TypeAdapter<EquipmentType> {
  @override
  final int typeId = 1;

  @override
  EquipmentType read(BinaryReader reader) {
    final index = reader.readByte();
    return EquipmentType.values[index];
  }

  @override
  void write(BinaryWriter writer, EquipmentType obj) {
    writer.writeByte(obj.index);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ExerciseDifficulty
// ─────────────────────────────────────────────────────────────────────────────

@HiveType(typeId: 2)
enum ExerciseDifficulty {
  @HiveField(0)
  beginner,
  @HiveField(1)
  intermediate,
  @HiveField(2)
  advanced;

  String get displayName {
    switch (this) {
      case ExerciseDifficulty.beginner:
        return 'Beginner';
      case ExerciseDifficulty.intermediate:
        return 'Intermediate';
      case ExerciseDifficulty.advanced:
        return 'Advanced';
    }
  }

  IconData get icon {
    switch (this) {
      case ExerciseDifficulty.beginner:
        return Icons.signal_cellular_alt_1_bar;
      case ExerciseDifficulty.intermediate:
        return Icons.signal_cellular_alt_2_bar;
      case ExerciseDifficulty.advanced:
        return Icons.signal_cellular_alt;
    }
  }
}

class ExerciseDifficultyAdapter extends TypeAdapter<ExerciseDifficulty> {
  @override
  final int typeId = 2;

  @override
  ExerciseDifficulty read(BinaryReader reader) {
    final index = reader.readByte();
    return ExerciseDifficulty.values[index];
  }

  @override
  void write(BinaryWriter writer, ExerciseDifficulty obj) {
    writer.writeByte(obj.index);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ExerciseCategory
// ─────────────────────────────────────────────────────────────────────────────

@HiveType(typeId: 3)
enum ExerciseCategory {
  @HiveField(0)
  compound,
  @HiveField(1)
  isolation;

  String get displayName {
    switch (this) {
      case ExerciseCategory.compound:
        return 'Compound';
      case ExerciseCategory.isolation:
        return 'Isolation';
    }
  }

  IconData get icon {
    switch (this) {
      case ExerciseCategory.compound:
        return Icons.account_tree;
      case ExerciseCategory.isolation:
        return Icons.center_focus_strong;
    }
  }
}

class ExerciseCategoryAdapter extends TypeAdapter<ExerciseCategory> {
  @override
  final int typeId = 3;

  @override
  ExerciseCategory read(BinaryReader reader) {
    final index = reader.readByte();
    return ExerciseCategory.values[index];
  }

  @override
  void write(BinaryWriter writer, ExerciseCategory obj) {
    writer.writeByte(obj.index);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MealType
// ─────────────────────────────────────────────────────────────────────────────

@HiveType(typeId: 4)
enum MealType {
  @HiveField(0)
  breakfast,
  @HiveField(1)
  lunch,
  @HiveField(2)
  dinner,
  @HiveField(3)
  snack;

  String get displayName {
    switch (this) {
      case MealType.breakfast:
        return 'Breakfast';
      case MealType.lunch:
        return 'Lunch';
      case MealType.dinner:
        return 'Dinner';
      case MealType.snack:
        return 'Snack';
    }
  }

  IconData get icon {
    switch (this) {
      case MealType.breakfast:
        return Icons.free_breakfast;
      case MealType.lunch:
        return Icons.lunch_dining;
      case MealType.dinner:
        return Icons.dinner_dining;
      case MealType.snack:
        return Icons.cookie;
    }
  }
}

class MealTypeAdapter extends TypeAdapter<MealType> {
  @override
  final int typeId = 4;

  @override
  MealType read(BinaryReader reader) {
    final index = reader.readByte();
    return MealType.values[index];
  }

  @override
  void write(BinaryWriter writer, MealType obj) {
    writer.writeByte(obj.index);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WorkoutGoal
// ─────────────────────────────────────────────────────────────────────────────

@HiveType(typeId: 5)
enum WorkoutGoal {
  @HiveField(0)
  fatLoss,
  @HiveField(1)
  hypertrophy,
  @HiveField(2)
  strength,
  @HiveField(3)
  generalFitness,
  @HiveField(4)
  endurance;

  String get displayName {
    switch (this) {
      case WorkoutGoal.fatLoss:
        return 'Fat Loss';
      case WorkoutGoal.hypertrophy:
        return 'Hypertrophy';
      case WorkoutGoal.strength:
        return 'Strength';
      case WorkoutGoal.generalFitness:
        return 'General Fitness';
      case WorkoutGoal.endurance:
        return 'Endurance';
    }
  }

  IconData get icon {
    switch (this) {
      case WorkoutGoal.fatLoss:
        return Icons.local_fire_department;
      case WorkoutGoal.hypertrophy:
        return Icons.fitness_center;
      case WorkoutGoal.strength:
        return Icons.bolt;
      case WorkoutGoal.generalFitness:
        return Icons.favorite;
      case WorkoutGoal.endurance:
        return Icons.timer;
    }
  }
}

class WorkoutGoalAdapter extends TypeAdapter<WorkoutGoal> {
  @override
  final int typeId = 5;

  @override
  WorkoutGoal read(BinaryReader reader) {
    final index = reader.readByte();
    return WorkoutGoal.values[index];
  }

  @override
  void write(BinaryWriter writer, WorkoutGoal obj) {
    writer.writeByte(obj.index);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ExperienceLevel
// ─────────────────────────────────────────────────────────────────────────────

@HiveType(typeId: 6)
enum ExperienceLevel {
  @HiveField(0)
  beginner,
  @HiveField(1)
  intermediate,
  @HiveField(2)
  advanced;

  String get displayName {
    switch (this) {
      case ExperienceLevel.beginner:
        return 'Beginner';
      case ExperienceLevel.intermediate:
        return 'Intermediate';
      case ExperienceLevel.advanced:
        return 'Advanced';
    }
  }

  IconData get icon {
    switch (this) {
      case ExperienceLevel.beginner:
        return Icons.star_border;
      case ExperienceLevel.intermediate:
        return Icons.star_half;
      case ExperienceLevel.advanced:
        return Icons.star;
    }
  }
}

class ExperienceLevelAdapter extends TypeAdapter<ExperienceLevel> {
  @override
  final int typeId = 6;

  @override
  ExperienceLevel read(BinaryReader reader) {
    final index = reader.readByte();
    return ExperienceLevel.values[index];
  }

  @override
  void write(BinaryWriter writer, ExperienceLevel obj) {
    writer.writeByte(obj.index);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SplitType
// ─────────────────────────────────────────────────────────────────────────────

@HiveType(typeId: 7)
enum SplitType {
  @HiveField(0)
  pushPullLegs,
  @HiveField(1)
  upperLower,
  @HiveField(2)
  broSplit,
  @HiveField(3)
  fullBody,
  @HiveField(4)
  arnoldSplit,
  @HiveField(5)
  custom;

  String get displayName {
    switch (this) {
      case SplitType.pushPullLegs:
        return 'Push / Pull / Legs';
      case SplitType.upperLower:
        return 'Upper / Lower';
      case SplitType.broSplit:
        return 'Bro Split';
      case SplitType.fullBody:
        return 'Full Body';
      case SplitType.arnoldSplit:
        return 'Arnold Split';
      case SplitType.custom:
        return 'Custom';
    }
  }

  IconData get icon {
    switch (this) {
      case SplitType.pushPullLegs:
        return Icons.view_week;
      case SplitType.upperLower:
        return Icons.swap_vert;
      case SplitType.broSplit:
        return Icons.calendar_view_week;
      case SplitType.fullBody:
        return Icons.accessibility;
      case SplitType.arnoldSplit:
        return Icons.military_tech;
      case SplitType.custom:
        return Icons.tune;
    }
  }
}

class SplitTypeAdapter extends TypeAdapter<SplitType> {
  @override
  final int typeId = 7;

  @override
  SplitType read(BinaryReader reader) {
    final index = reader.readByte();
    return SplitType.values[index];
  }

  @override
  void write(BinaryWriter writer, SplitType obj) {
    writer.writeByte(obj.index);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Gender
// ─────────────────────────────────────────────────────────────────────────────

enum Gender {
  male,
  female,
  other;

  String get displayName => switch (this) {
    Gender.male => 'Male',
    Gender.female => 'Female',
    Gender.other => 'Other',
  };

  IconData get icon => switch (this) {
    Gender.male => Icons.male_rounded,
    Gender.female => Icons.female_rounded,
    Gender.other => Icons.transgender_rounded,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// ActivityLevel
// ─────────────────────────────────────────────────────────────────────────────

enum ActivityLevel {
  sedentary,
  lightlyActive,
  moderatelyActive,
  veryActive,
  extremelyActive;

  String get displayName => switch (this) {
    ActivityLevel.sedentary => 'Sedentary',
    ActivityLevel.lightlyActive => 'Lightly Active',
    ActivityLevel.moderatelyActive => 'Moderately Active',
    ActivityLevel.veryActive => 'Very Active',
    ActivityLevel.extremelyActive => 'Extremely Active',
  };

  String get description => switch (this) {
    ActivityLevel.sedentary => 'Desk job, little to no exercise',
    ActivityLevel.lightlyActive => 'Light exercise 1-3 days/week',
    ActivityLevel.moderatelyActive => 'Moderate exercise 3-5 days/week',
    ActivityLevel.veryActive => 'Hard exercise 6-7 days/week',
    ActivityLevel.extremelyActive => 'Very hard exercise, physical job',
  };

  IconData get icon => switch (this) {
    ActivityLevel.sedentary => Icons.weekend_rounded,
    ActivityLevel.lightlyActive => Icons.directions_walk_rounded,
    ActivityLevel.moderatelyActive => Icons.directions_run_rounded,
    ActivityLevel.veryActive => Icons.sports_gymnastics_rounded,
    ActivityLevel.extremelyActive => Icons.local_fire_department_rounded,
  };

  /// Activity multiplier for TDEE calculation (Mifflin-St Jeor).
  double get multiplier => switch (this) {
    ActivityLevel.sedentary => 1.2,
    ActivityLevel.lightlyActive => 1.375,
    ActivityLevel.moderatelyActive => 1.55,
    ActivityLevel.veryActive => 1.725,
    ActivityLevel.extremelyActive => 1.9,
  };
}
