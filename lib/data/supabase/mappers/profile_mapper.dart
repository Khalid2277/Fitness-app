import 'package:alfanutrition/data/models/enums.dart';
import 'package:alfanutrition/data/models/user_profile.dart';

import 'enum_mappers.dart';

/// Maps between a Supabase `profiles` row and the app-side [UserProfile].
abstract final class ProfileMapper {
  /// Converts a Supabase row `Map` into a [UserProfile].
  static UserProfile fromRow(Map<String, dynamic> row) {
    return UserProfile(
      name: row['name'] as String?,
      height: (row['height_cm'] as num?)?.toDouble(),
      weight: (row['weight_kg'] as num?)?.toDouble(),
      age: row['age'] as int?,
      goal: row['goal'] != null
          ? EnumMappers.workoutGoalFromDb(row['goal'] as String)
          : WorkoutGoal.generalFitness,
      level: row['experience_level'] != null
          ? EnumMappers.experienceLevelFromDb(row['experience_level'] as String)
          : ExperienceLevel.beginner,
      dailyCalorieTarget:
          (row['daily_calorie_target'] as num?)?.toDouble(),
      proteinTarget: (row['protein_target'] as num?)?.toDouble(),
      carbsTarget: (row['carbs_target'] as num?)?.toDouble(),
      fatsTarget: (row['fats_target'] as num?)?.toDouble(),
      workoutDaysPerWeek: row['workout_days_per_week'] as int? ?? 4,
      joinDate: row['join_date'] != null
          ? DateTime.parse(row['join_date'] as String)
          : null,
      currentStreak: row['current_streak'] as int? ?? 0,
      longestStreak: row['longest_streak'] as int? ?? 0,
      gender: row['gender'] != null
          ? EnumMappers.genderFromDb(row['gender'] as String)
          : null,
      activityLevel: row['activity_level'] != null
          ? EnumMappers.activityLevelFromDb(row['activity_level'] as String)
          : null,
      dateOfBirth: row['date_of_birth'] != null
          ? DateTime.parse(row['date_of_birth'] as String)
          : null,
      targetWeight: (row['target_weight'] as num?)?.toDouble(),
    );
  }

  /// Converts a [UserProfile] into a Supabase-ready row `Map`.
  ///
  /// The `user_id` column is intentionally omitted here because it is set
  /// by the repository (from `auth.currentUser.id`).
  static Map<String, dynamic> toRow(UserProfile profile) {
    return {
      'name': profile.name,
      'height_cm': profile.height,
      'weight_kg': profile.weight,
      'age': profile.computedAge,
      'goal': EnumMappers.workoutGoalToDb(profile.goal),
      'experience_level': EnumMappers.experienceLevelToDb(profile.level),
      'daily_calorie_target': profile.dailyCalorieTarget,
      'protein_target': profile.proteinTarget,
      'carbs_target': profile.carbsTarget,
      'fats_target': profile.fatsTarget,
      'workout_days_per_week': profile.workoutDaysPerWeek,
      'join_date': profile.joinDate?.toIso8601String(),
      'current_streak': profile.currentStreak,
      'longest_streak': profile.longestStreak,
      'gender': profile.gender != null
          ? EnumMappers.genderToDb(profile.gender!)
          : null,
      'activity_level': profile.activityLevel != null
          ? EnumMappers.activityLevelToDb(profile.activityLevel!)
          : null,
      'date_of_birth': profile.dateOfBirth != null
          ? '${profile.dateOfBirth!.year}-${profile.dateOfBirth!.month.toString().padLeft(2, '0')}-${profile.dateOfBirth!.day.toString().padLeft(2, '0')}'
          : null,
      'target_weight': profile.targetWeight,
    };
  }
}
