import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Supabase configuration loaded from environment variables.
///
/// Reads `SUPABASE_URL` and `SUPABASE_ANON_KEY` from the `.env` file
/// via the `flutter_dotenv` package. If either is missing the app
/// falls back to local-only (Hive) storage.
abstract final class SupabaseConfig {
  // ──────────────────────── Connection credentials ────────────────────────

  /// The Supabase project URL (e.g. `https://xyzxyz.supabase.co`).
  static String get url => dotenv.env['SUPABASE_URL'] ?? '';

  /// The anonymous (public) API key for the Supabase project.
  static String get anonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  /// Returns `true` when both URL and anon key are present and non-empty.
  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;

  // ──────────────────────── Storage bucket names ──────────────────────────

  /// Bucket for user profile avatars.
  static const String avatarsBucket = 'avatars';

  /// Bucket for progress photos.
  static const String progressPhotosBucket = 'progress-photos';

  /// Bucket for exercise illustration images (admin-uploaded).
  static const String exerciseImagesBucket = 'exercise-images';

  // ──────────────────────── Table names ────────────────────────────────────

  static const String profilesTable = 'profiles';
  static const String exercisesTable = 'exercises';
  static const String workoutsTable = 'workouts';
  static const String workoutExercisesTable = 'workout_exercises';
  static const String exerciseSetsTable = 'exercise_sets';
  static const String mealsTable = 'meals';
  static const String bodyMetricsTable = 'body_metrics';
  static const String workoutPlansTable = 'workout_plans';
  static const String planDaysTable = 'plan_days';
  static const String planExercisesTable = 'plan_exercises';
  static const String aiChatMessagesTable = 'ai_chat_messages';
  static const String progressPhotosTable = 'progress_photos';
  static const String foodItemsTable = 'food_items';
  static const String foodUsageLogTable = 'food_usage_log';
  static const String userSettingsTable = 'app_settings';

  // ──────────────────────── Views ──────────────────────────────────────────

  static const String dailyNutritionSummaryView = 'daily_nutrition_summary';
}
