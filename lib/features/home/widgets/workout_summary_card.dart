import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:alfanutrition/core/theme/app_colors.dart';
import 'package:alfanutrition/core/theme/app_spacing.dart';
import 'package:alfanutrition/features/home/providers/home_providers.dart';

/// Pending Session card — shows today's scheduled workout with a START button,
/// or a rest-day empty state when no workout is planned.
class WorkoutSummaryCard extends StatelessWidget {
  final TodaysWorkout? workout;

  const WorkoutSummaryCard({super.key, required this.workout});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppSpacing.borderRadiusLg,
        border: isDark
            ? Border.all(
                color: Colors.white.withValues(alpha: 0.07),
                width: 1,
              )
            : null,
        boxShadow: isDark ? null : AppColors.cardShadowLight,
      ),
      child: workout != null
          ? _buildPendingView(context)
          : _buildEmptyView(context),
    )
        .animate()
        .fadeIn(duration: 600.ms, delay: 100.ms, curve: Curves.easeOut)
        .slideY(
            begin: 0.05,
            end: 0,
            duration: 600.ms,
            delay: 100.ms,
            curve: Curves.easeOut);
  }

  Widget _buildPendingView(BuildContext context) {
    final theme = Theme.of(context);
    final w = workout!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          w.isCompleted ? 'COMPLETED SESSION' : 'PENDING SESSION',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
        ),
        SizedBox(height: AppSpacing.sm),

        // Workout name
        Text(
          w.name,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: AppSpacing.sm),

        // Subtitle: Focus • duration • exercises
        Text(
          'Focus: ${w.focus ?? "General"} • ${w.durationMinutes} mins • ${w.exerciseCount} Exercises',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: AppSpacing.xl),

        // Action button
        if (!w.isCompleted)
          _buildStartButton(context)
        else
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => context.push('/workout/${w.id}'),
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: const Text('View Details'),
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStartButton(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: AppSpacing.borderRadiusMd,
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryBlue.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: () => context.push('/active-workout'),
          icon: const Icon(Icons.play_arrow_rounded, size: 20),
          label: const Text('START WORKOUT'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            shape: RoundedRectangleBorder(
              borderRadius: AppSpacing.borderRadiusMd,
            ),
            textStyle: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyView(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          'PENDING SESSION',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
        ),
        SizedBox(height: AppSpacing.xl),

        // Motivational CTA
        Center(
          child: Column(
            children: [
              Icon(
                Icons.fitness_center_rounded,
                size: 40,
                color: theme.colorScheme.onSurfaceVariant
                    .withValues(alpha: 0.3),
              ),
              SizedBox(height: AppSpacing.md),
              Text(
                'No workout planned today',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: AppSpacing.lg),
              _buildStartButton(context),
            ],
          ),
        ),
      ],
    );
  }
}
