import 'package:hive/hive.dart';

import 'enums.dart';

@HiveType(typeId: 18)
class UserProfile extends HiveObject {
  @HiveField(0)
  final String? name;

  @HiveField(1)
  final double? height;

  @HiveField(2)
  final double? weight;

  @HiveField(3)
  final int? age;

  @HiveField(4)
  final WorkoutGoal goal;

  @HiveField(5)
  final ExperienceLevel level;

  @HiveField(6)
  final double? _storedCalorieTarget;

  @HiveField(7)
  final double? _storedProteinTarget;

  @HiveField(8)
  final double? _storedCarbsTarget;

  @HiveField(9)
  final double? _storedFatsTarget;

  @HiveField(10)
  final int workoutDaysPerWeek;

  @HiveField(11)
  final DateTime? joinDate;

  @HiveField(12)
  final int currentStreak;

  @HiveField(13)
  final int longestStreak;

  @HiveField(14)
  final Gender? gender;

  @HiveField(15)
  final ActivityLevel? activityLevel;

  @HiveField(16)
  final DateTime? dateOfBirth;

  @HiveField(17)
  final double? targetWeight;

  UserProfile({
    this.name,
    this.height,
    this.weight,
    this.age,
    this.goal = WorkoutGoal.generalFitness,
    this.level = ExperienceLevel.beginner,
    double? dailyCalorieTarget,
    double? proteinTarget,
    double? carbsTarget,
    double? fatsTarget,
    this.workoutDaysPerWeek = 4,
    this.joinDate,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.gender,
    this.activityLevel,
    this.dateOfBirth,
    this.targetWeight,
  })  : _storedCalorieTarget = dailyCalorieTarget,
        _storedProteinTarget = proteinTarget,
        _storedCarbsTarget = carbsTarget,
        _storedFatsTarget = fatsTarget;

  /// Age computed from [dateOfBirth] if available, otherwise falls back to
  /// the stored [age] field.
  int? get computedAge {
    if (dateOfBirth != null) {
      final now = DateTime.now();
      int years = now.year - dateOfBirth!.year;
      if (now.month < dateOfBirth!.month ||
          (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
        years--;
      }
      return years;
    }
    return age;
  }

  /// User initials derived from name.
  String get initials {
    if (name == null || name!.isEmpty) return '?';
    final parts = name!.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name![0].toUpperCase();
  }

  /// BMI calculation (requires height in cm and weight in kg).
  double? get bmi {
    if (height != null && weight != null && height! > 0) {
      final heightInMeters = height! / 100;
      return weight! / (heightInMeters * heightInMeters);
    }
    return null;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Science-backed computed nutrition targets
  // ─────────────────────────────────────────────────────────────────────────

  /// Basal Metabolic Rate using Mifflin-St Jeor equation.
  /// Men: (10 x weight_kg) + (6.25 x height_cm) - (5 x age) + 5
  /// Women: (10 x weight_kg) + (6.25 x height_cm) - (5 x age) - 161
  /// Other/Unknown: average of male and female formulas
  double get bmr {
    final w = weight ?? 70.0;
    final h = height ?? 170.0;
    final a = (computedAge ?? 25).toDouble();

    return switch (gender) {
      Gender.male => (10 * w) + (6.25 * h) - (5 * a) + 5,
      Gender.female => (10 * w) + (6.25 * h) - (5 * a) - 161,
      Gender.other || null => (10 * w) + (6.25 * h) - (5 * a) - 78, // midpoint
    };
  }

  /// Total Daily Energy Expenditure = BMR x activity multiplier
  double get tdee => bmr * (activityLevel?.multiplier ?? 1.55);

  /// Daily calorie target adjusted for goal:
  /// Fat Loss: TDEE - 500 (moderate deficit)
  /// Hypertrophy: TDEE + 300 (lean bulk surplus)
  /// Maintenance: TDEE
  double get _computedCalorieTarget => switch (goal) {
    WorkoutGoal.fatLoss => (tdee - 500).clamp(1200, 5000),
    WorkoutGoal.hypertrophy => tdee + 300,
    WorkoutGoal.generalFitness => tdee,
    _ => tdee,
  };

  /// Protein target:
  /// Fat Loss: 2.2g/kg (high to preserve muscle in deficit)
  /// Hypertrophy: 2.0g/kg
  /// Maintenance: 1.8g/kg
  double get _computedProteinTarget {
    final w = weight ?? 70.0;
    return switch (goal) {
      WorkoutGoal.fatLoss => (w * 2.2).roundToDouble(),
      WorkoutGoal.hypertrophy => (w * 2.0).roundToDouble(),
      WorkoutGoal.generalFitness => (w * 1.8).roundToDouble(),
      _ => (w * 1.8).roundToDouble(),
    };
  }

  /// Fat target: 25% of total calories / 9 cal per gram
  double get _computedFatsTarget =>
      ((dailyCalorieTarget * 0.25) / 9).roundToDouble();

  /// Carbs target: remaining calories after protein and fat
  double get _computedCarbsTarget {
    final proteinCals = proteinTarget * 4;
    final fatCals = fatsTarget * 9;
    final remaining = dailyCalorieTarget - proteinCals - fatCals;
    return (remaining / 4).clamp(50, 800).roundToDouble();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Public getters — stored override takes priority, computed as fallback
  // ─────────────────────────────────────────────────────────────────────────

  double get dailyCalorieTarget =>
      _storedCalorieTarget ?? _computedCalorieTarget;

  double get proteinTarget => _storedProteinTarget ?? _computedProteinTarget;

  double get fatsTarget => _storedFatsTarget ?? _computedFatsTarget;

  double get carbsTarget => _storedCarbsTarget ?? _computedCarbsTarget;

  /// Total daily macro target in grams.
  double get totalMacroTarget => proteinTarget + carbsTarget + fatsTarget;

  /// Whether the user has manually set any nutrition overrides.
  bool get hasStoredNutritionOverrides =>
      _storedCalorieTarget != null ||
      _storedProteinTarget != null ||
      _storedCarbsTarget != null ||
      _storedFatsTarget != null;

  /// Target weight: user-set value takes priority, otherwise computed from goal.
  /// Fat Loss: current - 5%, Hypertrophy: current + 3%, Maintenance: same.
  double? get computedTargetWeight {
    if (targetWeight != null) return targetWeight;
    if (weight == null) return null;
    return switch (goal) {
      WorkoutGoal.fatLoss => weight! * 0.95,
      WorkoutGoal.hypertrophy => weight! * 1.03,
      WorkoutGoal.generalFitness => weight,
      _ => weight,
    };
  }

  UserProfile copyWith({
    String? name,
    double? height,
    double? weight,
    int? age,
    WorkoutGoal? goal,
    ExperienceLevel? level,
    double? dailyCalorieTarget,
    double? proteinTarget,
    double? carbsTarget,
    double? fatsTarget,
    int? workoutDaysPerWeek,
    DateTime? joinDate,
    int? currentStreak,
    int? longestStreak,
    Gender? gender,
    ActivityLevel? activityLevel,
    DateTime? dateOfBirth,
    double? targetWeight,
    bool clearTargetWeight = false,
    bool clearCalorieTarget = false,
    bool clearProteinTarget = false,
    bool clearCarbsTarget = false,
    bool clearFatsTarget = false,
  }) {
    return UserProfile(
      name: name ?? this.name,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      age: age ?? this.age,
      goal: goal ?? this.goal,
      level: level ?? this.level,
      dailyCalorieTarget: clearCalorieTarget
          ? null
          : (dailyCalorieTarget ?? _storedCalorieTarget),
      proteinTarget:
          clearProteinTarget ? null : (proteinTarget ?? _storedProteinTarget),
      carbsTarget:
          clearCarbsTarget ? null : (carbsTarget ?? _storedCarbsTarget),
      fatsTarget: clearFatsTarget ? null : (fatsTarget ?? _storedFatsTarget),
      workoutDaysPerWeek: workoutDaysPerWeek ?? this.workoutDaysPerWeek,
      joinDate: joinDate ?? this.joinDate,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      gender: gender ?? this.gender,
      activityLevel: activityLevel ?? this.activityLevel,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      targetWeight:
          clearTargetWeight ? null : (targetWeight ?? this.targetWeight),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'height': height,
      'weight': weight,
      'age': age,
      'goal': goal.name,
      'level': level.name,
      'dailyCalorieTarget': _storedCalorieTarget,
      'proteinTarget': _storedProteinTarget,
      'carbsTarget': _storedCarbsTarget,
      'fatsTarget': _storedFatsTarget,
      'workoutDaysPerWeek': workoutDaysPerWeek,
      'joinDate': joinDate?.toIso8601String(),
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'gender': gender?.name,
      'activityLevel': activityLevel?.name,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'targetWeight': targetWeight,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'] as String?,
      height: (json['height'] as num?)?.toDouble(),
      weight: (json['weight'] as num?)?.toDouble(),
      age: json['age'] as int?,
      goal: WorkoutGoal.values
          .byName(json['goal'] as String? ?? 'generalFitness'),
      level: ExperienceLevel.values
          .byName(json['level'] as String? ?? 'beginner'),
      dailyCalorieTarget:
          (json['dailyCalorieTarget'] as num?)?.toDouble(),
      proteinTarget: (json['proteinTarget'] as num?)?.toDouble(),
      carbsTarget: (json['carbsTarget'] as num?)?.toDouble(),
      fatsTarget: (json['fatsTarget'] as num?)?.toDouble(),
      workoutDaysPerWeek: json['workoutDaysPerWeek'] as int? ?? 4,
      joinDate: json['joinDate'] != null
          ? DateTime.parse(json['joinDate'] as String)
          : null,
      currentStreak: json['currentStreak'] as int? ?? 0,
      longestStreak: json['longestStreak'] as int? ?? 0,
      gender: json['gender'] != null
          ? Gender.values.byName(json['gender'] as String)
          : null,
      activityLevel: json['activityLevel'] != null
          ? ActivityLevel.values.byName(json['activityLevel'] as String)
          : null,
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.parse(json['dateOfBirth'] as String)
          : null,
      targetWeight: (json['targetWeight'] as num?)?.toDouble(),
    );
  }

  @override
  String toString() =>
      'UserProfile(name: $name, goal: ${goal.displayName})';
}

class UserProfileAdapter extends TypeAdapter<UserProfile> {
  @override
  final int typeId = 18;

  @override
  UserProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      final key = reader.readByte();
      final value = reader.read();
      fields[key] = value;
    }
    return UserProfile(
      name: fields[0] as String?,
      height: fields[1] as double?,
      weight: fields[2] as double?,
      age: fields[3] as int?,
      goal: fields[4] as WorkoutGoal,
      level: fields[5] as ExperienceLevel,
      dailyCalorieTarget: fields[6] as double?,
      proteinTarget: fields[7] as double?,
      carbsTarget: fields[8] as double?,
      fatsTarget: fields[9] as double?,
      workoutDaysPerWeek: fields[10] as int? ?? 4,
      joinDate: fields[11] as DateTime?,
      currentStreak: fields[12] as int? ?? 0,
      longestStreak: fields[13] as int? ?? 0,
      gender: fields.containsKey(14) && fields[14] != null
          ? Gender.values.byName(fields[14] as String)
          : null,
      activityLevel: fields.containsKey(15) && fields[15] != null
          ? ActivityLevel.values.byName(fields[15] as String)
          : null,
      dateOfBirth: fields.containsKey(16) ? fields[16] as DateTime? : null,
      targetWeight: fields.containsKey(17) ? fields[17] as double? : null,
    );
  }

  @override
  void write(BinaryWriter writer, UserProfile obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.height)
      ..writeByte(2)
      ..write(obj.weight)
      ..writeByte(3)
      ..write(obj.age)
      ..writeByte(4)
      ..write(obj.goal)
      ..writeByte(5)
      ..write(obj.level)
      ..writeByte(6)
      ..write(obj._storedCalorieTarget)
      ..writeByte(7)
      ..write(obj._storedProteinTarget)
      ..writeByte(8)
      ..write(obj._storedCarbsTarget)
      ..writeByte(9)
      ..write(obj._storedFatsTarget)
      ..writeByte(10)
      ..write(obj.workoutDaysPerWeek)
      ..writeByte(11)
      ..write(obj.joinDate)
      ..writeByte(12)
      ..write(obj.currentStreak)
      ..writeByte(13)
      ..write(obj.longestStreak)
      ..writeByte(14)
      ..write(obj.gender?.name)
      ..writeByte(15)
      ..write(obj.activityLevel?.name)
      ..writeByte(16)
      ..write(obj.dateOfBirth)
      ..writeByte(17)
      ..write(obj.targetWeight);
  }
}
