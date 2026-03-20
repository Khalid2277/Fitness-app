/// App-wide constants for AlfaNutrition.
abstract final class AppConstants {
  // ──────────────────────── App identity ──────────────────────────────────

  static const String appName = 'AlfaNutrition';
  static const String appTagline = 'Forge Your Best Self';
  static const String appVersion = '1.1.3';

  // ──────────────────────── Animation durations ──────────────────────────

  static const Duration animFast = Duration(milliseconds: 150);
  static const Duration animDefault = Duration(milliseconds: 300);
  static const Duration animSlow = Duration(milliseconds: 500);
  static const Duration animPageTransition = Duration(milliseconds: 350);

  // ──────────────────────── Layout breakpoints ───────────────────────────

  static const double breakpointSm = 360;
  static const double breakpointMd = 600;
  static const double breakpointLg = 900;
  static const double breakpointXl = 1200;

  // ──────────────────────── Default nutrition targets ────────────────────

  static const double defaultCalorieTarget = 2200;
  static const double defaultProteinTarget = 150;
  static const double defaultCarbsTarget = 250;
  static const double defaultFatsTarget = 70;

  // ──────────────────────── Pagination / Limits ──────────────────────────

  static const int defaultPageSize = 20;
  static const int maxRecentWorkouts = 10;
  static const int maxExerciseSets = 20;

  // ──────────────────────── Workout defaults ─────────────────────────────

  static const int defaultRestSeconds = 90;
  static const int minRestSeconds = 15;
  static const int maxRestSeconds = 600;

  static const double defaultWeightKg = 20.0;
  static const int defaultReps = 10;
  static const int defaultSets = 3;

  // ──────────────────────── Volume thresholds ────────────────────────────

  /// Sets per week per muscle group.
  static const int minimumWeeklyVolume = 10;
  static const int optimalWeeklyVolume = 15;
  static const int maximumWeeklyVolume = 20;

  // ──────────────────────── Body / Health ─────────────────────────────────

  static const double minWeightKg = 20.0;
  static const double maxWeightKg = 300.0;
  static const double minHeightCm = 100.0;
  static const double maxHeightCm = 250.0;

  // ──────────────────────── Storage / Hive box names ─────────────────────

  static const String workoutsBox = 'workouts';
  static const String mealsBox = 'meals';
  static const String bodyMetricsBox = 'body_metrics';
  static const String plansBox = 'plans';
  static const String userProfileBox = 'user_profile';
  static const String settingsBox = 'app_settings';
  static const String foodCacheBox = 'foodCache';
  static const String progressPhotosBox = 'progress_photos';
  static const String remindersBox = 'reminders';
  static const String chatSessionsBox = 'chat_sessions';
  static const String userMemoriesBox = 'user_memories';
  static const String bodyAnalysesBox = 'body_analyses';

  static const String storageKeyThemeMode = 'theme_mode';
  static const String storageKeyOnboarded = 'onboarded';
  static const String storageKeyUnit = 'unit_system';
  static const String storageKeyRestTimer = 'rest_timer_seconds';

  // ──────────────────────── Muscle group names ───────────────────────────

  static const List<String> muscleGroups = [
    'Chest',
    'Back',
    'Shoulders',
    'Biceps',
    'Triceps',
    'Forearms',
    'Core',
    'Quadriceps',
    'Hamstrings',
    'Glutes',
    'Calves',
  ];

  // ──────────────────────── Unit systems ─────────────────────────────────

  static const String unitMetric = 'metric';
  static const String unitImperial = 'imperial';

  // ──────────────────────── Date / Time formats ──────────────────────────

  static const String dateFormatFull = 'EEEE, MMMM d, yyyy';
  static const String dateFormat = 'MMM d, yyyy';
  static const String shortDateFormat = 'MMM d';
  static const String timeFormat = 'h:mm a';
  static const String durationFormat = 'HH:mm:ss';

  // ──────────────────────── Misc ─────────────────────────────────────────

  static const double minSearchQueryLength = 2;
  static const int debounceMilliseconds = 400;
}
