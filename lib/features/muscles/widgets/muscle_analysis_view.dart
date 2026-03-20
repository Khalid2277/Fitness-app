import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:alfanutrition/data/services/muscle_analysis_service.dart';
import 'package:alfanutrition/core/theme/app_colors.dart';
import 'package:alfanutrition/core/theme/app_spacing.dart';
import 'package:alfanutrition/features/muscles/providers/muscle_providers.dart';

class MuscleAnalysisView extends ConsumerWidget {
  const MuscleAnalysisView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cs = theme.colorScheme;
    final analysis = ref.watch(muscleAnalysisProvider);
    final sortMode = ref.watch(analysisSortModeProvider);
    final sortedStatuses = ref.watch(sortedMuscleStatusesProvider);
    final volume = ref.watch(muscleVolumeProvider);

    // Calculate body region scores
    final upperScore = _regionScore(volume, ['chest', 'shoulders', 'biceps', 'triceps', 'forearms']);
    final coreScore = _regionScore(volume, ['core', 'obliques']);
    final lowerScore = _regionScore(volume, ['quadriceps', 'hamstrings', 'glutes', 'calves']);

    // Strength peaks and focus areas
    final allStatuses = [
      ...analysis.optimalMuscles,
      ...analysis.overtrainedMuscles,
    ];
    final strengthPeaks = allStatuses
        .where((s) => s.currentSets > s.minSets)
        .toList()
      ..sort((a, b) => b.currentSets.compareTo(a.currentSets));

    final focusRequired = analysis.undertrainedMuscles.toList()
      ..sort((a, b) => (a.currentSets - a.minSets).compareTo(b.currentSets - b.minSets));

    return ListView(
      padding: AppSpacing.screenPadding,
      children: [
        const SizedBox(height: AppSpacing.sm),

        // ── Global Balance / Symmetry Profile ──
        _BalanceScoreCard(
          score: analysis.balanceScore,
          isDark: isDark,
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05),

        const SizedBox(height: AppSpacing.lg),

        // ── Body Region Bars ──
        _RegionBarsCard(
          upperScore: upperScore,
          coreScore: coreScore,
          lowerScore: lowerScore,
          isDark: isDark,
        ).animate().fadeIn(delay: 100.ms, duration: 400.ms).slideY(begin: 0.05),

        const SizedBox(height: AppSpacing.lg),

        // ── Recommendation Card ──
        if (analysis.suggestions.isNotEmpty)
          _RecommendationCard(
            suggestions: analysis.suggestions,
            isDark: isDark,
          ).animate().fadeIn(delay: 200.ms),

        if (analysis.suggestions.isNotEmpty)
          const SizedBox(height: AppSpacing.lg),

        // ── Strength Peaks ──
        if (strengthPeaks.isNotEmpty) ...[
          Text(
            'STRENGTH PEAKS',
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 1.2,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ...strengthPeaks.take(3).toList().asMap().entries.map((entry) {
            final i = entry.key;
            final s = entry.value;
            final surplus = ((s.currentSets - s.minSets) / s.minSets * 100).round();
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _PeakCard(
                muscleName: s.muscle.displayName,
                percentage: '+$surplus%',
                label: 'VS AVG',
                color: AppColors.accent,
                isDark: isDark,
              )
                  .animate()
                  .fadeIn(delay: Duration(milliseconds: (250 + 50 * i).toInt()), duration: 300.ms)
                  .slideX(begin: 0.03),
            );
          }),
          const SizedBox(height: AppSpacing.lg),
        ],

        // ── Focus Required ──
        if (focusRequired.isNotEmpty) ...[
          Text(
            'FOCUS REQUIRED',
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 1.2,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ...focusRequired.take(3).toList().asMap().entries.map((entry) {
            final i = entry.key;
            final s = entry.value;
            final deficit = ((s.minSets - s.currentSets) / s.minSets * 100).round();
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _PeakCard(
                muscleName: s.muscle.displayName,
                percentage: '-$deficit%',
                label: 'VS TARGET',
                color: AppColors.error,
                isDark: isDark,
              )
                  .animate()
                  .fadeIn(delay: Duration(milliseconds: (350 + 50 * i).toInt()), duration: 300.ms)
                  .slideX(begin: 0.03),
            );
          }),
          const SizedBox(height: AppSpacing.lg),
        ],

        // ── Training Frequency ──
        Text(
          'TRAINING FREQUENCY',
          style: theme.textTheme.labelSmall?.copyWith(
            letterSpacing: 1.2,
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Legend
        Row(
          children: [
            _FreqLegend(color: AppColors.primaryBlue, label: 'Current', isDark: isDark),
            const SizedBox(width: AppSpacing.lg),
            _FreqLegend(color: cs.onSurfaceVariant.withValues(alpha: 0.3), label: 'Target', isDark: isDark),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // Sort controls
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Muscle Groups',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Container(
              padding: const EdgeInsets.all(AppSpacing.xs),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : AppColors.surfaceLight2,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : AppColors.dividerLight,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _SortChip(
                    label: 'Least',
                    isSelected: sortMode == AnalysisSortMode.leastTrained,
                    onTap: () => ref
                        .read(analysisSortModeProvider.notifier)
                        .state = AnalysisSortMode.leastTrained,
                  ),
                  _SortChip(
                    label: 'Most',
                    isSelected: sortMode == AnalysisSortMode.mostTrained,
                    onTap: () => ref
                        .read(analysisSortModeProvider.notifier)
                        .state = AnalysisSortMode.mostTrained,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // Muscle group cards
        ...sortedStatuses.asMap().entries.map((entry) {
          final i = entry.key;
          final status = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _MuscleVolumeCard(status: status, isDark: isDark)
                .animate()
                .fadeIn(delay: Duration(milliseconds: 50 * i))
                .slideX(begin: 0.03),
          );
        }),

        const SizedBox(height: 100),
      ],
    );
  }

  double _regionScore(Map<dynamic, int> volume, List<String> muscleNames) {
    int total = 0;
    int count = 0;
    for (final entry in volume.entries) {
      if (muscleNames.contains(entry.key.name)) {
        total += entry.value;
        count++;
      }
    }
    if (count == 0) return 0;
    final avg = total / count;
    return (avg / 12 * 100).clamp(0, 100);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Balance Score Card
// ─────────────────────────────────────────────────────────────────────────────

class _BalanceScoreCard extends StatelessWidget {
  const _BalanceScoreCard({
    required this.score,
    required this.isDark,
  });

  final double score;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : AppColors.dividerLight,
        ),
      ),
      child: Column(
        children: [
          Text(
            'GLOBAL BALANCE',
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 1.2,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Symmetry Profile',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Score ring
              SizedBox(
                width: 100,
                height: 100,
                child: CustomPaint(
                  painter: _CircularScorePainter(
                    score: score,
                    isDark: isDark,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${score.round()}',
                          style: theme.textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 32,
                          ),
                        ),
                        Text(
                          '%',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xxl),
              // Range label
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: _scoreColor(score).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  _scoreLabel(score),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: _scoreColor(score),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _scoreLabel(double score) {
    if (score >= 80) return 'EXCELLENT';
    if (score >= 60) return 'OPTIMAL RANGE';
    if (score >= 40) return 'NEEDS WORK';
    return 'IMBALANCED';
  }

  Color _scoreColor(double score) {
    if (score >= 60) return AppColors.success;
    if (score >= 40) return AppColors.warning;
    return AppColors.error;
  }
}

class _CircularScorePainter extends CustomPainter {
  _CircularScorePainter({required this.score, required this.isDark});
  final double score;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;

    final bgPaint = Paint()
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.06)
          : Colors.black.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi,
      false,
      bgPaint,
    );

    final scorePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    if (score >= 60) {
      scorePaint.shader = const LinearGradient(
        colors: [AppColors.accent, AppColors.success],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    } else if (score >= 40) {
      scorePaint.color = AppColors.warning;
    } else {
      scorePaint.color = AppColors.error;
    }

    final sweepAngle = (score / 100) * 2 * math.pi;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      scorePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularScorePainter oldDelegate) =>
      oldDelegate.score != score;
}

// ─────────────────────────────────────────────────────────────────────────────
// Region Bars Card
// ─────────────────────────────────────────────────────────────────────────────

class _RegionBarsCard extends StatelessWidget {
  const _RegionBarsCard({
    required this.upperScore,
    required this.coreScore,
    required this.lowerScore,
    required this.isDark,
  });

  final double upperScore;
  final double coreScore;
  final double lowerScore;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : AppColors.dividerLight,
        ),
      ),
      child: Column(
        children: [
          _RegionBar(
            label: 'Upper Body',
            status: _statusLabel(upperScore),
            value: upperScore / 100,
            color: _barColor(upperScore),
            isDark: isDark,
          ),
          const SizedBox(height: AppSpacing.md),
          _RegionBar(
            label: 'Core',
            status: _statusLabel(coreScore),
            value: coreScore / 100,
            color: _barColor(coreScore),
            isDark: isDark,
          ),
          const SizedBox(height: AppSpacing.md),
          _RegionBar(
            label: 'Lower Body',
            status: _statusLabel(lowerScore),
            value: lowerScore / 100,
            color: _barColor(lowerScore),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  String _statusLabel(double score) {
    if (score >= 70) return 'Strong';
    if (score >= 40) return 'Balanced';
    return 'Attention';
  }

  Color _barColor(double score) {
    if (score >= 70) return AppColors.primaryBlue;
    if (score >= 40) return AppColors.textSecondaryDark;
    return AppColors.warning;
  }
}

class _RegionBar extends StatelessWidget {
  const _RegionBar({
    required this.label,
    required this.status,
    required this.value,
    required this.color,
    required this.isDark,
  });

  final String label;
  final String status;
  final double value;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              status,
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.xs),
          child: LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : AppColors.surfaceLight2,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Recommendation Card
// ─────────────────────────────────────────────────────────────────────────────

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({
    required this.suggestions,
    required this.isDark,
  });

  final List<String> suggestions;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : AppColors.dividerLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Priority badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.sm),
            ),
            child: Text(
              'HIGH PRIORITY',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ...suggestions.take(3).map((s) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Text(
                  s,
                  style: theme.textTheme.bodySmall?.copyWith(
                    height: 1.4,
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Peak/Focus Card
// ─────────────────────────────────────────────────────────────────────────────

class _PeakCard extends StatelessWidget {
  const _PeakCard({
    required this.muscleName,
    required this.percentage,
    required this.label,
    required this.color,
    required this.isDark,
  });

  final String muscleName;
  final String percentage;
  final String label;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : AppColors.dividerLight,
        ),
      ),
      child: Row(
        children: [
          // Color indicator
          Container(
            width: 4,
            height: 32,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              muscleName,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            percentage,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 0.5,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Frequency Legend
// ─────────────────────────────────────────────────────────────────────────────

class _FreqLegend extends StatelessWidget {
  const _FreqLegend({
    required this.color,
    required this.label,
    required this.isDark,
  });

  final Color color;
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Muscle Volume Card
// ─────────────────────────────────────────────────────────────────────────────

class _MuscleVolumeCard extends StatelessWidget {
  const _MuscleVolumeCard({
    required this.status,
    required this.isDark,
  });

  final MuscleGroupStatus status;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _statusColor(status.status);
    final progress =
        (status.currentSets / status.maxSets).clamp(0.0, 1.2);

    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : AppColors.dividerLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                status.muscle.icon,
                size: 18,
                color: statusColor,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  status.muscle.displayName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                ),
                child: Text(
                  _statusLabel(status.status),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                '${status.currentSets}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                ' / ${status.maxSets}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Dual progress bar (current vs target)
          Stack(
            children: [
              // Target bar (background)
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.xs),
                child: LinearProgressIndicator(
                  value: 1.0,
                  minHeight: 6,
                  backgroundColor: isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : AppColors.surfaceLight2,
                  valueColor: AlwaysStoppedAnimation(
                    isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : AppColors.surfaceLight3,
                  ),
                ),
              ),
              // Current bar
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.xs),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation(statusColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Optimal: ${status.minSets}-${status.maxSets} sets/week',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'undertrained':
        return AppColors.error;
      case 'overtrained':
        return AppColors.warning;
      default:
        return AppColors.success;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'undertrained':
        return 'UNDER';
      case 'overtrained':
        return 'OVER';
      default:
        return 'OPTIMAL';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sort Chip
// ─────────────────────────────────────────────────────────────────────────────

class _SortChip extends StatelessWidget {
  const _SortChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.sm),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? Colors.white
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
