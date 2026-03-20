import 'package:alfanutrition/data/models/exercise.dart';

import 'enum_mappers.dart';

/// Maps between a Supabase `exercises` row and the app-side [Exercise].
abstract final class ExerciseMapper {
  /// Converts a Supabase row `Map` into an [Exercise].
  static Exercise fromRow(Map<String, dynamic> row) {
    return Exercise(
      id: row['id'] as String,
      name: row['name'] as String,
      description: row['description'] as String? ?? '',
      instructions: row['instructions'] as String? ?? '',
      tips: _textArray(row['tips']),
      commonMistakes: _textArray(row['common_mistakes']),
      primaryMuscle: EnumMappers.muscleGroupFromDb(row['primary_muscle'] as String),
      secondaryMuscles: _textArray(row['secondary_muscles'])
          .map((s) => EnumMappers.muscleGroupFromDb(s))
          .toList(),
      equipment: EnumMappers.equipmentTypeFromDb(row['equipment'] as String),
      difficulty:
          EnumMappers.exerciseDifficultyFromDb(row['difficulty'] as String),
      category:
          EnumMappers.exerciseCategoryFromDb(row['category'] as String),
      videoUrl: row['video_url'] as String?,
      imageUrl: row['image_url'] as String?,
      bestForGoals: _textArray(row['best_for_goals']),
      setupInstructions: row['setup_instructions'] as String?,
      safetyTips: row['safety_tips'] as String?,
      suggestedRepRange: row['suggested_rep_range'] as String? ?? '8-12',
    );
  }

  /// Converts an [Exercise] into a Supabase-ready row `Map`.
  static Map<String, dynamic> toRow(Exercise exercise, {String? userId}) {
    final map = <String, dynamic>{
      'id': exercise.id,
      'name': exercise.name,
      'description': exercise.description,
      'instructions': exercise.instructions,
      'tips': exercise.tips,
      'common_mistakes': exercise.commonMistakes,
      'primary_muscle': EnumMappers.muscleGroupToDb(exercise.primaryMuscle),
      'secondary_muscles': exercise.secondaryMuscles
          .map((m) => EnumMappers.muscleGroupToDb(m))
          .toList(),
      'equipment': EnumMappers.equipmentTypeToDb(exercise.equipment),
      'difficulty': EnumMappers.exerciseDifficultyToDb(exercise.difficulty),
      'category': EnumMappers.exerciseCategoryToDb(exercise.category),
      'video_url': exercise.videoUrl,
      'image_url': exercise.imageUrl,
      'best_for_goals': exercise.bestForGoals,
      'setup_instructions': exercise.setupInstructions,
      'safety_tips': exercise.safetyTips,
      'suggested_rep_range': exercise.suggestedRepRange,
    };
    if (userId != null) {
      map['user_id'] = userId;
    }
    return map;
  }

  // ──────────────────────── Helpers ──────────────────────────────────────

  /// Safely casts a Postgres `text[]` or JSON array to `List<String>`.
  static List<String> _textArray(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.cast<String>();
    return [];
  }
}
