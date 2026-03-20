import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:alfanutrition/core/theme/app_colors.dart';
import 'package:alfanutrition/core/theme/app_spacing.dart';
import 'package:alfanutrition/features/progress/providers/progress_providers.dart';

class StatsOverview extends StatelessWidget {
  final TrainingStats stats;

  const StatsOverview({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final items = [
      _StatItem(
        icon: Icons.fitness_center_rounded,
        label: 'TOTAL WORKOUTS',
        value: '${stats.totalWorkouts}',
        color: AppColors.primaryBlue,
      ),
      _StatItem(
        icon: Icons.scale_rounded,
        label: 'TOTAL VOLUME',
        value: _formatVolume(stats.totalVolume),
        color: AppColors.accent,
      ),
      _StatItem(
        icon: Icons.local_fire_department_rounded,
        label: 'STREAK',
        value: '${stats.trainingStreak} days',
        color: AppColors.warning,
      ),
      _StatItem(
        icon: Icons.timer_rounded,
        label: 'AVG DURATION',
        value: '${stats.averageDurationMinutes} min',
        color: AppColors.info,
      ),
      _StatItem(
        icon: Icons.star_rounded,
        label: 'TOP MUSCLE',
        value: stats.mostTrainedMuscle,
        color: AppColors.muscleChest,
      ),
      _StatItem(
        icon: Icons.calendar_today_rounded,
        label: 'DAYS ACTIVE',
        value: '${stats.daysSinceStarted}',
        color: AppColors.muscleArms,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TRAINING OVERVIEW',
          style: theme.textTheme.labelSmall?.copyWith(
            letterSpacing: 1.2,
            fontWeight: FontWeight.w600,
            color: isDark
                ? AppColors.textTertiaryDark
                : AppColors.textTertiaryLight,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.55,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            return _StatCard(item: items[index])
                .animate()
                .fadeIn(
                  duration: 500.ms,
                  delay: (100 * index).ms,
                  curve: Curves.easeOut,
                )
                .slideY(
                  begin: 0.05,
                  end: 0,
                  duration: 500.ms,
                  delay: (100 * index).ms,
                  curve: Curves.easeOut,
                );
          },
        ),
      ],
    );
  }

  String _formatVolume(double volume) {
    if (volume >= 1000000) {
      return '${(volume / 1000000).toStringAsFixed(1)}M kg';
    } else if (volume >= 1000) {
      return '${(volume / 1000).toStringAsFixed(1)}K kg';
    }
    return '${volume.toStringAsFixed(0)} kg';
  }
}

class _StatItem {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
}

class _StatCard extends StatelessWidget {
  final _StatItem item;

  const _StatCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : AppColors.dividerLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.1),
              borderRadius: AppSpacing.borderRadiusSm,
            ),
            child: Icon(item.icon, color: item.color, size: 18),
          ),
          const Spacer(),
          Text(
            item.value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            item.label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: isDark
                  ? AppColors.textTertiaryDark
                  : AppColors.textTertiaryLight,
              letterSpacing: 0.8,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
