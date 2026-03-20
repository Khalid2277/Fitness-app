import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:alfanutrition/core/theme/app_colors.dart';
import 'package:alfanutrition/core/theme/app_spacing.dart';
import 'package:alfanutrition/data/models/exercise_set.dart';
import 'package:alfanutrition/data/models/workout.dart';
import 'package:alfanutrition/data/models/workout_exercise.dart';
import 'package:alfanutrition/features/workouts/providers/workout_providers.dart';

class WorkoutDetailScreen extends ConsumerWidget {
  final String workoutId;

  const WorkoutDetailScreen({super.key, required this.workoutId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final workoutAsync = ref.watch(workoutByIdProvider(workoutId));

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: workoutAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (workout) {
          if (workout == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 48,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                  ),
                  SizedBox(height: AppSpacing.md),
                  Text(
                    'Workout not found',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          // Determine the dominant muscle color for the header gradient
          final primaryMuscle = workout.musclesHit.isNotEmpty
              ? workout.musclesHit.first
              : null;
          final heroColor = primaryMuscle != null
              ? AppColors.colorForMuscle(primaryMuscle)
              : AppColors.primaryBlue;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ────────── Hero Header ──────────
              _HeroHeader(
                workout: workout,
                heroColor: heroColor,
                theme: theme,
                isDark: isDark,
                onBack: () => context.pop(),
                onRepeat: () => _repeatWorkout(context, ref, workout),
                onDelete: () => _deleteWorkout(context, ref, workout),
              ),

              // ────────── Stats Row ──────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.xl, AppSpacing.xxl, AppSpacing.xl, 0,
                  ),
                  child: Row(
                    children: [
                      _StatBox(
                        icon: Icons.timer_outlined,
                        value: workout.formattedDuration,
                        label: 'Duration',
                        color: AppColors.primaryBlue,
                        theme: theme,
                        isDark: isDark,
                      ),
                      SizedBox(width: AppSpacing.md),
                      _StatBox(
                        icon: Icons.fitness_center_rounded,
                        value: '${workout.exercises.length}',
                        label: 'Exercises',
                        color: AppColors.accent,
                        theme: theme,
                        isDark: isDark,
                      ),
                      SizedBox(width: AppSpacing.md),
                      _StatBox(
                        icon: Icons.repeat_rounded,
                        value: '${workout.totalSets}',
                        label: 'Sets',
                        color: AppColors.warning,
                        theme: theme,
                        isDark: isDark,
                      ),
                      SizedBox(width: AppSpacing.md),
                      _StatBox(
                        icon: Icons.scale_rounded,
                        value: _formatVolume(workout.totalVolume),
                        label: 'Volume',
                        color: AppColors.success,
                        theme: theme,
                        isDark: isDark,
                      ),
                    ],
                  )
                      .animate()
                      .fadeIn(
                        delay: 200.ms,
                        duration: 500.ms,
                      )
                      .slideY(
                        begin: 0.06,
                        end: 0,
                        delay: 200.ms,
                        duration: 500.ms,
                        curve: Curves.easeOut,
                      ),
                ),
              ),

              // ────────── Muscles Targeted ──────────
              if (workout.musclesHit.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.xl, AppSpacing.xxl, AppSpacing.xl, 0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.my_location_rounded,
                              size: 18,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                            SizedBox(width: AppSpacing.sm),
                            Text(
                              'Muscles Targeted',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: AppSpacing.md),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: workout.musclesHit.map((muscle) {
                              final color = AppColors.colorForMuscle(muscle);
                              return Padding(
                                padding: EdgeInsets.only(right: AppSpacing.sm),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md,
                                    vertical: AppSpacing.sm,
                                  ),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: isDark ? 0.15 : 0.10),
                                    borderRadius: AppSpacing.borderRadiusPill,
                                    border: Border.all(
                                      color: color.withValues(alpha: 0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: color,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      SizedBox(width: AppSpacing.sm),
                                      Text(
                                        muscle.displayName,
                                        style: theme.textTheme.labelMedium?.copyWith(
                                          color: color,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 300.ms, duration: 500.ms)
                      .slideY(begin: 0.05, delay: 300.ms, duration: 500.ms, curve: Curves.easeOut),
                ),

              // ────────── Notes ──────────
              if (workout.notes != null && workout.notes!.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.xl, AppSpacing.xxl, AppSpacing.xl, 0,
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: AppSpacing.cardPadding,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark1 : AppColors.surfaceLight,
                        borderRadius: AppSpacing.borderRadiusLg,
                        border: Border.all(
                          color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
                        ),
                        boxShadow: isDark
                            ? AppColors.cardShadowDark
                            : AppColors.cardShadowLight,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.sticky_note_2_outlined,
                                size: 16,
                                color: isDark
                                    ? AppColors.textTertiaryDark
                                    : AppColors.textTertiaryLight,
                              ),
                              SizedBox(width: AppSpacing.sm),
                              Text(
                                'Notes',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: isDark
                                      ? AppColors.textTertiaryDark
                                      : AppColors.textTertiaryLight,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: AppSpacing.sm),
                          Text(
                            workout.notes!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 350.ms, duration: 500.ms)
                      .slideY(begin: 0.05, delay: 350.ms, duration: 500.ms, curve: Curves.easeOut),
                ),

              // ────────── Exercises Header ──────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.xl, AppSpacing.xxl, AppSpacing.xl, AppSpacing.md,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.format_list_bulleted_rounded,
                        size: 20,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                      SizedBox(width: AppSpacing.sm),
                      Text(
                        'Exercise Breakdown',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.surfaceDark2
                              : AppColors.surfaceLight2,
                          borderRadius: AppSpacing.borderRadiusPill,
                        ),
                        child: Text(
                          '${workout.exercises.length} exercises',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: isDark
                                ? AppColors.textTertiaryDark
                                : AppColors.textTertiaryLight,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ────────── Exercise List ──────────
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final exercise = workout.exercises[index];
                      return _ExerciseBreakdownCard(
                        exercise: exercise,
                        index: index,
                        theme: theme,
                        isDark: isDark,
                        muscleColor: AppColors.colorForMuscle(exercise.primaryMuscle),
                      );
                    },
                    childCount: workout.exercises.length,
                  ),
                ),
              ),

              // ────────── Bottom Actions ──────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.xl, AppSpacing.xxl, AppSpacing.xl, AppSpacing.md,
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: AppSpacing.borderRadiusLg,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryBlue.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () => _repeatWorkout(context, ref, workout),
                      icon: const Icon(Icons.replay_rounded, size: 20),
                      label: const Text('Repeat This Workout'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppSpacing.borderRadiusLg,
                        ),
                        textStyle: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 600.ms, duration: 500.ms)
                    .slideY(begin: 0.05, delay: 600.ms, duration: 500.ms, curve: Curves.easeOut),
              ),

              // ────────── Delete Button ──────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.xl, AppSpacing.xs, AppSpacing.xl, AppSpacing.xxxxl + AppSpacing.xl,
                  ),
                  child: TextButton.icon(
                    onPressed: () => _deleteWorkout(context, ref, workout),
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      size: 18,
                      color: AppColors.error.withValues(alpha: 0.7),
                    ),
                    label: Text(
                      'Delete Workout',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.error.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppSpacing.borderRadiusMd,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatVolume(double volume) {
    if (volume >= 1000) {
      return '${(volume / 1000).toStringAsFixed(1)}k';
    }
    return volume.toStringAsFixed(0);
  }

  void _repeatWorkout(BuildContext context, WidgetRef ref, Workout workout) {
    final notifier = ref.read(activeWorkoutProvider.notifier);
    notifier.startWorkout(name: workout.name);
    for (final exercise in workout.exercises) {
      notifier.addExercise(
        exerciseId: exercise.exerciseId,
        exerciseName: exercise.exerciseName,
        primaryMuscle: exercise.primaryMuscle,
      );
    }
    context.push('/active-workout');
  }

  Future<void> _deleteWorkout(
    BuildContext context,
    WidgetRef ref,
    Workout workout,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusXl,
        ),
        title: const Text('Delete Workout?'),
        content: const Text(
          'This action cannot be undone. All data for this workout will be permanently removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref
          .read(workoutHistoryProvider.notifier)
          .deleteWorkout(workout.id);
      if (context.mounted) {
        context.pop();
      }
    }
  }
}

// ─────────────────────────── Hero Header ───────────────────────────

class _HeroHeader extends StatelessWidget {
  final Workout workout;
  final Color heroColor;
  final ThemeData theme;
  final bool isDark;
  final VoidCallback onBack;
  final VoidCallback onRepeat;
  final VoidCallback onDelete;

  const _HeroHeader({
    required this.workout,
    required this.heroColor,
    required this.theme,
    required this.isDark,
    required this.onBack,
    required this.onRepeat,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              heroColor,
              heroColor.withValues(alpha: 0.8),
              isDark
                  ? AppColors.backgroundDark
                  : AppColors.backgroundLight,
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.sm, 0, AppSpacing.sm, AppSpacing.xxl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top bar with back + menu
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _GlassIconButton(
                      icon: Icons.arrow_back_rounded,
                      onTap: onBack,
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'repeat') {
                          onRepeat();
                        } else if (value == 'delete') {
                          onDelete();
                        }
                      },
                      child: _GlassIconButton(
                        icon: Icons.more_horiz_rounded,
                        onTap: null,
                      ),
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'repeat',
                          child: Row(
                            children: [
                              Icon(Icons.replay_rounded, size: 18),
                              SizedBox(width: AppSpacing.sm),
                              Text('Repeat Workout'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline_rounded, size: 18),
                              SizedBox(width: AppSpacing.sm),
                              Text('Delete'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                SizedBox(height: AppSpacing.lg),

                // Workout name
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Text(
                    workout.name,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 500.ms)
                      .slideX(begin: -0.05, duration: 500.ms, curve: Curves.easeOut),
                ),

                SizedBox(height: AppSpacing.md),

                // Date and duration badges
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Row(
                    children: [
                      _HeroBadge(
                        icon: Icons.calendar_today_rounded,
                        text: DateFormat('MMM d, yyyy').format(workout.date),
                      ),
                      SizedBox(width: AppSpacing.sm),
                      _HeroBadge(
                        icon: Icons.access_time_rounded,
                        text: DateFormat('h:mm a').format(workout.date),
                      ),
                      SizedBox(width: AppSpacing.sm),
                      _HeroBadge(
                        icon: Icons.timer_outlined,
                        text: workout.formattedDuration,
                      ),
                    ],
                  )
                      .animate()
                      .fadeIn(delay: 150.ms, duration: 500.ms)
                      .slideY(begin: 0.1, delay: 150.ms, duration: 500.ms, curve: Curves.easeOut),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────── Glass Icon Button ───────────────────────────

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _GlassIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final child = Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
        ),
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: child);
    }
    return child;
  }
}

// ─────────────────────────── Hero Badge ───────────────────────────

class _HeroBadge extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HeroBadge({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: AppSpacing.xs + 1,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: AppSpacing.borderRadiusPill,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white.withValues(alpha: 0.9)),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.95),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────── Stat Box ───────────────────────────

class _StatBox extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final ThemeData theme;
  final bool isDark;

  const _StatBox({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: AppSpacing.md + 2,
          horizontal: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark1 : AppColors.surfaceLight,
          borderRadius: AppSpacing.borderRadiusLg,
          border: Border.all(
            color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
            width: 0.5,
          ),
          boxShadow: isDark
              ? AppColors.cardShadowDark
              : AppColors.cardShadowLight,
        ),
        child: Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withValues(alpha: isDark ? 0.15 : 0.10),
                borderRadius: AppSpacing.borderRadiusSm,
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              value,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: isDark
                    ? AppColors.textTertiaryDark
                    : AppColors.textTertiaryLight,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────── Exercise Breakdown Card ───────────────────────────

class _ExerciseBreakdownCard extends StatelessWidget {
  final WorkoutExercise exercise;
  final int index;
  final ThemeData theme;
  final bool isDark;
  final Color muscleColor;

  const _ExerciseBreakdownCard({
    required this.exercise,
    required this.index,
    required this.theme,
    required this.isDark,
    required this.muscleColor,
  });

  @override
  Widget build(BuildContext context) {
    final bestSet = exercise.bestSet;

    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark1 : AppColors.surfaceLight,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(
          color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
          width: 0.5,
        ),
        boxShadow: isDark
            ? AppColors.cardShadowDark
            : AppColors.cardShadowLight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Card header with accent bar ──
          Container(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.md,
            ),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: muscleColor,
                  width: 3,
                ),
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppSpacing.radiusLg),
                topRight: Radius.circular(AppSpacing.radiusLg),
              ),
            ),
            child: Row(
              children: [
                // Muscle color dot
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: muscleColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: muscleColor.withValues(alpha: 0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.exerciseName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${exercise.completedSets} of ${exercise.sets.length} sets completed',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppColors.textTertiaryDark
                              : AppColors.textTertiaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm + 2,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: muscleColor.withValues(alpha: isDark ? 0.15 : 0.10),
                    borderRadius: AppSpacing.borderRadiusPill,
                  ),
                  child: Text(
                    exercise.primaryMuscle.displayName,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: muscleColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Set table header ──
          Container(
            margin: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.surfaceDark2
                  : AppColors.surfaceLight2,
              borderRadius: AppSpacing.borderRadiusSm,
            ),
            child: Row(
              children: [
                _TableHeaderCell('SET', flex: 1),
                _TableHeaderCell('KG', flex: 2),
                _TableHeaderCell('REPS', flex: 2),
                _TableHeaderCell('VOL', flex: 2),
              ],
            ),
          ),

          // ── Set rows ──
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              children: exercise.sets.asMap().entries.map((entry) {
                final set = entry.value;
                final isBest = bestSet != null &&
                    set.setNumber == bestSet.setNumber &&
                    !set.isWarmup &&
                    set.isCompleted;
                return _SetRow(
                  set: set,
                  isBest: isBest,
                  theme: theme,
                  isDark: isDark,
                  muscleColor: muscleColor,
                );
              }).toList(),
            ),
          ),

          // ── Best set highlight ──
          if (bestSet != null && bestSet.volume > 0)
            Container(
              margin: EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.xs, AppSpacing.lg, AppSpacing.md,
              ),
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.warning.withValues(alpha: isDark ? 0.12 : 0.08),
                    AppColors.warning.withValues(alpha: isDark ? 0.06 : 0.03),
                  ],
                ),
                borderRadius: AppSpacing.borderRadiusSm,
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.emoji_events_rounded,
                    size: 14,
                    color: AppColors.warning,
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Text(
                    'Best set: ',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${_formatWeight(bestSet.weight)} kg x ${bestSet.reps ?? 0} reps',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${bestSet.volume.toStringAsFixed(0)} vol',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),

          // ── Exercise notes ──
          if (exercise.notes != null && exercise.notes!.isNotEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.xs, AppSpacing.lg, AppSpacing.lg,
              ),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.surfaceDark2
                      : AppColors.surfaceLight1,
                  borderRadius: AppSpacing.borderRadiusSm,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.notes_rounded,
                      size: 14,
                      color: isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiaryLight,
                    ),
                    SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        exercise.notes!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Bottom spacing if no notes and no best set
          if ((exercise.notes == null || exercise.notes!.isEmpty) &&
              (bestSet == null || bestSet.volume <= 0))
            SizedBox(height: AppSpacing.sm),
        ],
      ),
    )
        .animate()
        .fadeIn(
          delay: Duration(milliseconds: 400 + (80 * math.min(index, 6))),
          duration: 500.ms,
        )
        .slideY(
          begin: 0.04,
          end: 0,
          delay: Duration(milliseconds: 400 + (80 * math.min(index, 6))),
          duration: 500.ms,
          curve: Curves.easeOut,
        );
  }

  String _formatWeight(double? weight) {
    if (weight == null) return '-';
    return weight == weight.roundToDouble()
        ? weight.toStringAsFixed(0)
        : weight.toStringAsFixed(1);
  }
}

// ─────────────────────────── Table Header Cell ───────────────────────────

class _TableHeaderCell extends StatelessWidget {
  final String text;
  final int flex;

  const _TableHeaderCell(this.text, {this.flex = 1});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          color: isDark
              ? AppColors.textTertiaryDark
              : AppColors.textTertiaryLight,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// ─────────────────────────── Set Row ───────────────────────────

class _SetRow extends StatelessWidget {
  final ExerciseSet set;
  final bool isBest;
  final ThemeData theme;
  final bool isDark;
  final Color muscleColor;

  const _SetRow({
    required this.set,
    required this.isBest,
    required this.theme,
    required this.isDark,
    required this.muscleColor,
  });

  @override
  Widget build(BuildContext context) {
    final volume = set.volume;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? AppColors.dividerDark.withValues(alpha: 0.5)
                : AppColors.dividerLight.withValues(alpha: 0.5),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // Set number
          Expanded(
            flex: 1,
            child: Center(
              child: set.isWarmup
                  ? Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.12),
                        borderRadius: AppSpacing.borderRadiusSm,
                      ),
                      child: Text(
                        'W',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    )
                  : Text(
                      '${set.setNumber}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          // Weight
          Expanded(
            flex: 2,
            child: Text(
              set.weight != null
                  ? _formatWeight(set.weight!)
                  : '-',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // Reps
          Expanded(
            flex: 2,
            child: Text(
              set.reps?.toString() ?? '-',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // Volume
          Expanded(
            flex: 2,
            child: Text(
              volume > 0 ? volume.toStringAsFixed(0) : '-',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textTertiaryDark
                    : AppColors.textTertiaryLight,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  String _formatWeight(double weight) {
    return weight == weight.roundToDouble()
        ? weight.toStringAsFixed(0)
        : weight.toStringAsFixed(1);
  }
}
