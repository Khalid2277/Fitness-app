import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:alfanutrition/data/models/enums.dart';
import 'package:alfanutrition/core/theme/app_colors.dart';
import 'package:alfanutrition/core/theme/app_spacing.dart';
import 'package:alfanutrition/features/muscles/providers/muscle_providers.dart';

/// Shows a bottom sheet with details about a selected muscle group.
void showMuscleDetailSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const _MuscleDetailSheet(),
  );
}

class _MuscleDetailSheet extends ConsumerWidget {
  const _MuscleDetailSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cs = theme.colorScheme;
    final muscle = ref.watch(selectedMuscleProvider);

    if (muscle == null) return const SizedBox.shrink();

    final volume = ref.watch(muscleVolumeProvider);
    final status = ref.watch(muscleStatusProvider(muscle));
    final exercises = ref.watch(exercisesForMuscleProvider(muscle));
    final sets = volume[muscle] ?? 0;
    final muscleColor = AppColors.colorForMuscle(muscle);

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusXxl),
            ),
            border: isDark
                ? Border(
                    top: BorderSide(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  )
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.sm),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.15)
                      : cs.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: AppSpacing.screenPadding,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: AppSpacing.cardPaddingCompact,
                          decoration: BoxDecoration(
                            color: muscleColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(AppSpacing.md),
                          ),
                          child: Icon(
                            muscle.icon,
                            color: muscleColor,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.lg),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                muscle.displayName,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Row(
                                children: [
                                  Text(
                                    '$sets sets this week',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  _StatusBadge(status: status, isDark: isDark),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ).animate().fadeIn(duration: 300.ms).slideX(begin: -0.05),

                    const SizedBox(height: AppSpacing.xxl),

                    // Volume card
                    Container(
                      padding: AppSpacing.cardPadding,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.04)
                            : AppColors.surfaceLight1,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : AppColors.dividerLight,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'WEEKLY VOLUME',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  letterSpacing: 1.2,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                '$sets sets',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: (sets / 20).clamp(0.0, 1.0),
                              minHeight: 6,
                              backgroundColor: isDark
                                  ? Colors.white.withValues(alpha: 0.06)
                                  : AppColors.surfaceLight3,
                              valueColor: AlwaysStoppedAnimation(muscleColor),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 100.ms),

                    const SizedBox(height: AppSpacing.xxl),

                    // Exercises section
                    Text(
                      'EXERCISES',
                      style: theme.textTheme.labelSmall?.copyWith(
                        letterSpacing: 1.2,
                        color: cs.onSurfaceVariant,
                      ),
                    ).animate().fadeIn(delay: 150.ms),
                    const SizedBox(height: AppSpacing.md),

                    ...exercises.take(5).toList().asMap().entries.map((entry) {
                      final i = entry.key;
                      final exercise = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Material(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.04)
                              : AppColors.surfaceLight1,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                            onTap: () {
                              Navigator.of(context).pop();
                              context.push('/exercise/${exercise.id}');
                            },
                            child: Container(
                              padding: AppSpacing.cardPadding,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.06)
                                      : AppColors.dividerLight,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: muscleColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(AppSpacing.md),
                                    ),
                                    child: Icon(
                                      exercise.equipment.icon,
                                      size: 16,
                                      color: muscleColor,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          exercise.name,
                                          style: theme.textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Text(
                                              exercise.equipment.displayName,
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                color: cs.onSurfaceVariant,
                                              ),
                                            ),
                                            const SizedBox(width: AppSpacing.sm),
                                            _DifficultyDots(
                                              difficulty: exercise.difficulty,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right,
                                    color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                            .animate()
                            .fadeIn(delay: Duration(milliseconds: (200 + 50 * i).toInt())),
                      );
                    }),

                    if (exercises.length > 5)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xs),
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            context.push('/exercises');
                          },
                          child: Text(
                            'See All Exercises',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: AppColors.primaryBlue,
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: AppSpacing.xxxl),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.isDark});
  final String status;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (status) {
      case 'undertrained':
        color = AppColors.error;
        label = 'UNDERTRAINED';
      case 'overtrained':
        color = AppColors.warning;
        label = 'OVERTRAINED';
      default:
        color = AppColors.success;
        label = 'OPTIMAL';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _DifficultyDots extends StatelessWidget {
  const _DifficultyDots({required this.difficulty});
  final ExerciseDifficulty difficulty;

  @override
  Widget build(BuildContext context) {
    final filled = difficulty.index + 1;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(right: 3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: i < filled
                ? AppColors.primaryBlue
                : AppColors.primaryBlue.withValues(alpha: 0.2),
          ),
        );
      }),
    );
  }
}
