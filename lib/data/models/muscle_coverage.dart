import 'enums.dart';

/// Muscle analysis data for tracking training balance and volume distribution.
///
/// This model is not persisted to Hive directly -- it is computed
/// on the fly from workout history. It provides methods to identify
/// undertrained/overtrained muscles and an overall balance score.
class MuscleCoverage {
  final Map<MuscleGroup, int> weeklySetCount;
  final Map<MuscleGroup, int> monthlySetCount;

  const MuscleCoverage({
    required this.weeklySetCount,
    required this.monthlySetCount,
  });

  // ──────────────────────── Recommended weekly set ranges ────────────────────

  /// Minimum recommended weekly sets per muscle group for growth.
  static const int _minWeeklySets = 10;

  /// Maximum productive weekly sets per muscle group before junk volume.
  static const int _maxWeeklySets = 20;

  // ──────────────────────── Analysis methods ────────────────────────────────

  /// Muscles receiving fewer than the minimum recommended weekly sets.
  List<MuscleGroup> get undertrainedMuscles {
    return MuscleGroup.values.where((muscle) {
      final sets = weeklySetCount[muscle] ?? 0;
      return sets < _minWeeklySets;
    }).toList();
  }

  /// Muscles receiving more than the maximum recommended weekly sets.
  List<MuscleGroup> get overtrainedMuscles {
    return MuscleGroup.values.where((muscle) {
      final sets = weeklySetCount[muscle] ?? 0;
      return sets > _maxWeeklySets;
    }).toList();
  }

  /// Muscles within the optimal weekly set range.
  List<MuscleGroup> get optimalMuscles {
    return MuscleGroup.values.where((muscle) {
      final sets = weeklySetCount[muscle] ?? 0;
      return sets >= _minWeeklySets && sets <= _maxWeeklySets;
    }).toList();
  }

  /// Muscles with zero weekly sets (completely neglected).
  List<MuscleGroup> get neglectedMuscles {
    return MuscleGroup.values.where((muscle) {
      return (weeklySetCount[muscle] ?? 0) == 0;
    }).toList();
  }

  /// Overall balance score from 0.0 (completely imbalanced) to 1.0 (perfect).
  ///
  /// The score is calculated as the ratio of muscles in the optimal range
  /// versus total muscle groups, with partial credit for undertrained muscles
  /// that are at least partially trained.
  double get balanceScore {
    if (MuscleGroup.values.isEmpty) return 1.0;

    double score = 0;
    for (final muscle in MuscleGroup.values) {
      final sets = weeklySetCount[muscle] ?? 0;
      if (sets >= _minWeeklySets && sets <= _maxWeeklySets) {
        // Optimal range: full credit
        score += 1.0;
      } else if (sets > 0 && sets < _minWeeklySets) {
        // Partially trained: partial credit proportional to minimum
        score += sets / _minWeeklySets;
      } else if (sets > _maxWeeklySets) {
        // Overtrained: diminishing credit beyond max
        final overBy = sets - _maxWeeklySets;
        score += (1.0 - (overBy / _maxWeeklySets)).clamp(0.3, 1.0);
      }
      // Zero sets: no credit
    }

    return (score / MuscleGroup.values.length).clamp(0.0, 1.0);
  }

  /// Weekly sets for a specific muscle group.
  int weeklySetsFor(MuscleGroup muscle) => weeklySetCount[muscle] ?? 0;

  /// Monthly sets for a specific muscle group.
  int monthlySetsFor(MuscleGroup muscle) => monthlySetCount[muscle] ?? 0;

  /// Status label for a muscle group: "Neglected", "Under", "Optimal", "Over".
  String statusFor(MuscleGroup muscle) {
    final sets = weeklySetCount[muscle] ?? 0;
    if (sets == 0) return 'Neglected';
    if (sets < _minWeeklySets) return 'Under';
    if (sets > _maxWeeklySets) return 'Over';
    return 'Optimal';
  }

  /// Progress ratio for a muscle group (0.0 to 1.0+ based on minimum target).
  double progressFor(MuscleGroup muscle) {
    final sets = weeklySetCount[muscle] ?? 0;
    return sets / _minWeeklySets;
  }

  MuscleCoverage copyWith({
    Map<MuscleGroup, int>? weeklySetCount,
    Map<MuscleGroup, int>? monthlySetCount,
  }) {
    return MuscleCoverage(
      weeklySetCount: weeklySetCount ?? this.weeklySetCount,
      monthlySetCount: monthlySetCount ?? this.monthlySetCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'weeklySetCount': weeklySetCount
          .map((key, value) => MapEntry(key.name, value)),
      'monthlySetCount': monthlySetCount
          .map((key, value) => MapEntry(key.name, value)),
    };
  }

  factory MuscleCoverage.fromJson(Map<String, dynamic> json) {
    return MuscleCoverage(
      weeklySetCount: (json['weeklySetCount'] as Map<String, dynamic>).map(
        (key, value) =>
            MapEntry(MuscleGroup.values.byName(key), value as int),
      ),
      monthlySetCount: (json['monthlySetCount'] as Map<String, dynamic>).map(
        (key, value) =>
            MapEntry(MuscleGroup.values.byName(key), value as int),
      ),
    );
  }

  /// Creates an empty coverage with zero sets for all muscles.
  factory MuscleCoverage.empty() {
    final zeroCounts = {
      for (final muscle in MuscleGroup.values) muscle: 0,
    };
    return MuscleCoverage(
      weeklySetCount: Map.unmodifiable(zeroCounts),
      monthlySetCount: Map.unmodifiable(zeroCounts),
    );
  }

  @override
  String toString() =>
      'MuscleCoverage(balance: ${(balanceScore * 100).toStringAsFixed(1)}%, '
      'optimal: ${optimalMuscles.length}, '
      'under: ${undertrainedMuscles.length}, '
      'over: ${overtrainedMuscles.length})';
}
