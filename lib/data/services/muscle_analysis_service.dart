import 'package:alfanutrition/data/models/enums.dart';

/// Result of a full muscle-group analysis.
class MuscleAnalysisResult {
  /// Weekly sets per muscle group.
  final Map<MuscleGroup, int> weeklySetsPerMuscle;

  /// Muscles below their minimum effective volume.
  final List<MuscleGroupStatus> undertrainedMuscles;

  /// Muscles above their maximum recoverable volume.
  final List<MuscleGroupStatus> overtrainedMuscles;

  /// Muscles within the optimal training range.
  final List<MuscleGroupStatus> optimalMuscles;

  /// 0-100 score representing overall muscle balance.
  final double balanceScore;

  /// Actionable suggestions to improve coverage.
  final List<String> suggestions;

  const MuscleAnalysisResult({
    required this.weeklySetsPerMuscle,
    required this.undertrainedMuscles,
    required this.overtrainedMuscles,
    required this.optimalMuscles,
    required this.balanceScore,
    required this.suggestions,
  });
}

/// Status details for a single muscle group.
class MuscleGroupStatus {
  final MuscleGroup muscle;
  final int currentSets;
  final int minSets;
  final int maxSets;
  final String status; // 'undertrained', 'optimal', 'overtrained'

  const MuscleGroupStatus({
    required this.muscle,
    required this.currentSets,
    required this.minSets,
    required this.maxSets,
    required this.status,
  });
}

/// Science-based muscle analysis service.
///
/// Volume thresholds are drawn from hypertrophy research (Schoenfeld et al.)
/// and represent weekly direct sets per muscle group.
class MuscleAnalysisService {
  // ── Volume thresholds (sets per week) ──────────────────────────────────
  // Keys: MuscleGroup → (minEffectiveVolume, maxRecoverableVolume)
  static const Map<MuscleGroup, (int, int)> _volumeThresholds = {
    MuscleGroup.chest: (10, 20),
    MuscleGroup.back: (10, 20),
    MuscleGroup.shoulders: (8, 18),
    MuscleGroup.biceps: (6, 16),
    MuscleGroup.triceps: (6, 16),
    MuscleGroup.forearms: (4, 12),
    MuscleGroup.quadriceps: (10, 20),
    MuscleGroup.hamstrings: (8, 18),
    MuscleGroup.glutes: (8, 18),
    MuscleGroup.calves: (8, 16),
    MuscleGroup.core: (6, 16),
    MuscleGroup.traps: (6, 16),
    MuscleGroup.lats: (10, 20),
    MuscleGroup.obliques: (4, 12),
    MuscleGroup.hipFlexors: (4, 10),
    MuscleGroup.adductors: (4, 12),
    MuscleGroup.abductors: (4, 12),
  };

  /// Analyze a list of completed workouts (Maps) within a 7-day window.
  ///
  /// Each workout map is expected to contain an `exercises` list, where each
  /// exercise has `primaryMuscle` (String matching MuscleGroup name),
  /// `secondaryMuscles` (`List<String>`), and `sets` (int).
  MuscleAnalysisResult analyze(List<Map<String, dynamic>> workouts) {
    final setsPerMuscle = _calculateWeeklySets(workouts);
    final undertrained = <MuscleGroupStatus>[];
    final overtrained = <MuscleGroupStatus>[];
    final optimal = <MuscleGroupStatus>[];

    for (final muscle in MuscleGroup.values) {
      final current = setsPerMuscle[muscle] ?? 0;
      final thresholds = _volumeThresholds[muscle] ?? (6, 16);
      final (minSets, maxSets) = thresholds;

      final status = MuscleGroupStatus(
        muscle: muscle,
        currentSets: current,
        minSets: minSets,
        maxSets: maxSets,
        status: current < minSets
            ? 'undertrained'
            : current > maxSets
                ? 'overtrained'
                : 'optimal',
      );

      if (current < minSets) {
        undertrained.add(status);
      } else if (current > maxSets) {
        overtrained.add(status);
      } else {
        optimal.add(status);
      }
    }

    final balanceScore = _calculateBalanceScore(setsPerMuscle);
    final suggestions = _generateSuggestions(undertrained, overtrained);

    return MuscleAnalysisResult(
      weeklySetsPerMuscle: setsPerMuscle,
      undertrainedMuscles: undertrained,
      overtrainedMuscles: overtrained,
      optimalMuscles: optimal,
      balanceScore: balanceScore,
      suggestions: suggestions,
    );
  }

  // ── Private helpers ────────────────────────────────────────────────────

  Map<MuscleGroup, int> _calculateWeeklySets(
    List<Map<String, dynamic>> workouts,
  ) {
    final sets = <MuscleGroup, int>{};

    for (final workout in workouts) {
      final exercises = workout['exercises'] as List<dynamic>? ?? [];
      for (final exercise in exercises) {
        final ex = exercise is Map ? Map<String, dynamic>.from(exercise) : null;
        if (ex == null) continue;

        final numSets = (ex['sets'] as num?)?.toInt() ?? 0;

        // Primary muscle – counts full sets.
        final primaryName = ex['primaryMuscle'] as String?;
        final primary = _parseMuscleGroup(primaryName);
        if (primary != null) {
          sets[primary] = (sets[primary] ?? 0) + numSets;
        }

        // Secondary muscles – count at half weight (rounded up).
        final secondaryNames =
            (ex['secondaryMuscles'] as List<dynamic>?)?.cast<String>() ?? [];
        for (final name in secondaryNames) {
          final muscle = _parseMuscleGroup(name);
          if (muscle != null) {
            final halfSets = (numSets / 2).ceil();
            sets[muscle] = (sets[muscle] ?? 0) + halfSets;
          }
        }
      }
    }

    return sets;
  }

  MuscleGroup? _parseMuscleGroup(String? name) {
    if (name == null) return null;
    final lower = name.toLowerCase();
    for (final mg in MuscleGroup.values) {
      if (mg.name.toLowerCase() == lower) return mg;
    }
    return null;
  }

  double _calculateBalanceScore(Map<MuscleGroup, int> setsPerMuscle) {
    int musclesInRange = 0;
    int totalMuscles = MuscleGroup.values.length;

    for (final muscle in MuscleGroup.values) {
      final current = setsPerMuscle[muscle] ?? 0;
      final thresholds = _volumeThresholds[muscle] ?? (6, 16);
      final (minSets, maxSets) = thresholds;

      if (current >= minSets && current <= maxSets) {
        musclesInRange++;
      } else if (current > 0) {
        // Partial credit for muscles that are trained but outside range.
        final midpoint = (minSets + maxSets) / 2;
        final deviation = (current - midpoint).abs() / midpoint;
        // Give partial score inversely proportional to deviation.
        musclesInRange += (1 - deviation.clamp(0.0, 1.0)).toInt();
      }
    }

    return (musclesInRange / totalMuscles * 100).clamp(0, 100);
  }

  List<String> _generateSuggestions(
    List<MuscleGroupStatus> undertrained,
    List<MuscleGroupStatus> overtrained,
  ) {
    final suggestions = <String>[];

    if (undertrained.isEmpty && overtrained.isEmpty) {
      suggestions.add(
        'Your training volume is well balanced across all muscle groups.',
      );
      return suggestions;
    }

    // Sort undertrained by deficit (biggest gap first).
    final sortedUnder = List.of(undertrained)
      ..sort((a, b) => (a.minSets - a.currentSets)
          .compareTo(b.minSets - b.currentSets));

    for (final status in sortedUnder) {
      final deficit = status.minSets - status.currentSets;
      final name = _formatMuscleGroupName(status.muscle);
      suggestions.add(
        'Add $deficit more weekly sets for $name to reach the minimum '
        'effective volume of ${status.minSets} sets/week.',
      );
    }

    for (final status in overtrained) {
      final excess = status.currentSets - status.maxSets;
      final name = _formatMuscleGroupName(status.muscle);
      suggestions.add(
        'Reduce $name volume by $excess sets/week. You are exceeding the '
        'maximum recoverable volume of ${status.maxSets} sets/week.',
      );
    }

    // Push/pull/upper/lower imbalance checks.
    return suggestions;
  }

  String _formatMuscleGroupName(MuscleGroup muscle) {
    // Convert camelCase enum name to readable form.
    final name = muscle.name;
    final buffer = StringBuffer();
    for (int i = 0; i < name.length; i++) {
      final char = name[i];
      if (char == char.toUpperCase() && i > 0) {
        buffer.write(' ');
      }
      buffer.write(i == 0 ? char.toUpperCase() : char.toLowerCase());
    }
    return buffer.toString();
  }
}
