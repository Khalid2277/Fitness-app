import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:alfanutrition/data/models/workout.dart';
import 'package:alfanutrition/core/theme/app_colors.dart';
import 'package:alfanutrition/core/theme/app_spacing.dart';

/// A card displaying a past workout in the history list.
class WorkoutHistoryCard extends StatelessWidget {
  final Workout workout;
  final int index;

  const WorkoutHistoryCard({
    super.key,
    required this.workout,
    this.index = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => context.push('/workout/${workout.id}'),
      child: Container(
        padding: AppSpacing.cardPadding,
        decoration: BoxDecoration(
          color: cs.surface,
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
                // Workout icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: const Icon(
                    Icons.fitness_center_rounded,
                    size: 18,
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        workout.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.xs / 2),
                      Text(
                        DateFormat('MMM d, yyyy \u2022 h:mm a').format(workout.date),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                  size: 24,
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // Stats row
            Row(
              children: [
                _StatChip(
                  icon: Icons.timer_outlined,
                  label: workout.formattedDuration,
                  isDark: isDark,
                ),
                const SizedBox(width: AppSpacing.md),
                _StatChip(
                  icon: Icons.fitness_center_rounded,
                  label: '${workout.exercises.length} exercises',
                  isDark: isDark,
                ),
                const SizedBox(width: AppSpacing.md),
                if (workout.totalVolume > 0)
                  _StatChip(
                    icon: Icons.trending_up_rounded,
                    label: '${workout.totalVolume.toStringAsFixed(0)} kg',
                    isDark: isDark,
                  ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // Muscle group chips
            Wrap(
              spacing: AppSpacing.xs + 2,
              runSpacing: AppSpacing.xs,
              children: workout.musclesHit.take(4).map((muscle) {
                final color = AppColors.colorForMuscle(muscle);
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs - 1),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  ),
                  child: Text(
                    muscle.displayName.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                      letterSpacing: 0.5,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(
          delay: Duration(milliseconds: 50 * index),
          duration: 400.ms,
        )
        .slideX(
          begin: 0.02,
          end: 0,
          delay: Duration(milliseconds: 50 * index),
          duration: 400.ms,
          curve: Curves.easeOut,
        );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : AppColors.surfaceLight2,
        borderRadius: BorderRadius.circular(AppSpacing.xs + 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
