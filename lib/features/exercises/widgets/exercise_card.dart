import 'package:flutter/material.dart';
import 'package:alfanutrition/data/models/exercise.dart';
import 'package:alfanutrition/data/models/enums.dart';
import 'package:alfanutrition/core/theme/app_colors.dart';
import 'package:alfanutrition/core/theme/app_spacing.dart';

class ExerciseCard extends StatelessWidget {
  const ExerciseCard({
    super.key,
    required this.exercise,
    required this.onTap,
  });

  final Exercise exercise;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final muscleColor = AppColors.colorForMuscle(exercise.primaryMuscle);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: AppSpacing.cardPadding,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: AppSpacing.borderRadiusLg,
          border: Border.all(
            color: Colors.white.withValues(alpha: isDark ? 0.07 : 0.0),
          ),
          boxShadow:
              isDark ? AppColors.cardShadowDark : AppColors.cardShadowLight,
        ),
        child: Row(
          children: [
            // Equipment icon with muscle color
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: muscleColor.withValues(alpha: 0.12),
                borderRadius: AppSpacing.borderRadiusMd,
              ),
              child: Icon(
                exercise.equipment.icon,
                size: 22,
                color: muscleColor,
              ),
            ),
            const SizedBox(width: AppSpacing.lg),

            // Name and details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      // Muscle chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: muscleColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(
                              AppSpacing.radiusPill),
                        ),
                        child: Text(
                          exercise.primaryMuscle.displayName,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: muscleColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      // Equipment label
                      Icon(
                        exercise.equipment.icon,
                        size: 12,
                        color: isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textTertiaryLight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        exercise.equipment.displayName,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: isDark
                              ? AppColors.textTertiaryDark
                              : AppColors.textTertiaryLight,
                        ),
                      ),
                      const Spacer(),
                      // Difficulty indicator
                      _DifficultyIndicator(
                        difficulty: exercise.difficulty,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: AppSpacing.sm),

            // Chevron
            Icon(
              Icons.chevron_right_rounded,
              color: isDark
                  ? AppColors.textTertiaryDark
                  : AppColors.textTertiaryLight,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _DifficultyIndicator extends StatelessWidget {
  const _DifficultyIndicator({
    required this.difficulty,
    required this.isDark,
  });
  final ExerciseDifficulty difficulty;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final filled = difficulty.index + 1;
    final Color activeColor;
    switch (difficulty) {
      case ExerciseDifficulty.beginner:
        activeColor = AppColors.success;
      case ExerciseDifficulty.intermediate:
        activeColor = AppColors.warning;
      case ExerciseDifficulty.advanced:
        activeColor = AppColors.error;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return Container(
          width: 4,
          height: i < filled ? 10 + (i * 3.0) : 10 + (i * 3.0),
          margin: const EdgeInsets.only(right: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            color: i < filled
                ? activeColor
                : (isDark
                    ? AppColors.surfaceDark3
                    : AppColors.surfaceLight3),
          ),
        );
      }),
    );
  }
}
