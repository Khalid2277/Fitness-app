import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:alfanutrition/core/theme/app_colors.dart';
import 'package:alfanutrition/core/theme/app_spacing.dart';
import 'package:alfanutrition/data/models/workout.dart';
import 'package:alfanutrition/features/workouts/providers/workout_providers.dart';
import 'package:alfanutrition/features/workouts/widgets/workout_history_card.dart';

class WorkoutsScreen extends ConsumerWidget {
  const WorkoutsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final historyAsync = ref.watch(workoutHistoryProvider);
    final stats = ref.watch(workoutStatsProvider);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ────────── Header ──────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl, AppSpacing.xxl, AppSpacing.xl, 0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Workouts',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      stats.totalWorkouts == 0
                          ? 'Start your fitness journey'
                          : '${stats.totalWorkouts} total sessions logged',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ).animate().fadeIn(duration: 400.ms),
              ),
            ),

            // ────────── Stats Row ──────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, 0,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _PremiumStatCard(
                        label: 'Total',
                        value: '${stats.totalWorkouts}',
                        icon: Icons.fitness_center_rounded,
                        color: AppColors.primaryBlue,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _PremiumStatCard(
                        label: 'This Week',
                        value: '${stats.thisWeek}',
                        icon: Icons.calendar_today_rounded,
                        color: AppColors.accent,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _PremiumStatCard(
                        label: 'Streak',
                        value: '${stats.streak}',
                        icon: Icons.local_fire_department_rounded,
                        color: AppColors.warning,
                        isDark: isDark,
                        isHighlighted: stats.streak > 0,
                      ),
                    ),
                  ],
                )
                    .animate()
                    .fadeIn(delay: 100.ms, duration: 400.ms)
                    .slideY(
                      begin: 0.05,
                      end: 0,
                      delay: 100.ms,
                      duration: 400.ms,
                      curve: Curves.easeOut,
                    ),
              ),
            ),

            // ────────── Start Workout CTA ──────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, 0,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryBlue.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => context.push('/active-workout'),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusLg),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl,
                          vertical: AppSpacing.lg + 2,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusMd,
                                ),
                              ),
                              child: const Icon(
                                Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.lg),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Start Empty Workout',
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xs / 2),
                                  Text(
                                    'Track exercises, sets & reps',
                                    style:
                                        theme.textTheme.bodySmall?.copyWith(
                                      color:
                                          Colors.white.withValues(alpha: 0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white.withValues(alpha: 0.8),
                              size: 22,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 500.ms)
                    .slideY(
                      begin: 0.05,
                      end: 0,
                      delay: 200.ms,
                      duration: 500.ms,
                      curve: Curves.easeOut,
                    ),
              ),
            ),

            // ────────── Quick Actions ──────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, 0,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _QuickActionCard(
                        icon: Icons.calendar_month_rounded,
                        label: 'Browse Plans',
                        subtitle: 'Structured routines',
                        color: AppColors.primaryBlue,
                        onTap: () => context.push('/plans'),
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _QuickActionCard(
                        icon: Icons.fitness_center_rounded,
                        label: 'Exercise Library',
                        subtitle: '90+ exercises',
                        color: AppColors.accent,
                        onTap: () => context.push('/exercises'),
                        isDark: isDark,
                      ),
                    ),
                  ],
                )
                    .animate()
                    .fadeIn(delay: 300.ms, duration: 400.ms)
                    .slideY(
                      begin: 0.05,
                      end: 0,
                      delay: 300.ms,
                      duration: 400.ms,
                      curve: Curves.easeOut,
                    ),
              ),
            ),

            // ────────── History Header ──────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.xxl + AppSpacing.xs,
                  AppSpacing.xl,
                  AppSpacing.md,
                ),
                child: Row(
                  children: [
                    Text(
                      'History',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    if (historyAsync.valueOrNull?.isNotEmpty == true)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm + 2,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withValues(alpha: 0.1),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusPill),
                        ),
                        child: Text(
                          '${historyAsync.valueOrNull?.length ?? 0} sessions',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ────────── History List ──────────
            historyAsync.when(
              loading: () => const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.xxxxl),
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
              error: (e, _) => SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xxxxl),
                    child: Text('Error loading workouts: $e'),
                  ),
                ),
              ),
              data: (workouts) {
                if (workouts.isEmpty) {
                  return SliverToBoxAdapter(
                    child: _EmptyState(
                      isDark: isDark,
                      onStartWorkout: () =>
                          context.push('/active-workout'),
                    ),
                  );
                }

                final grouped = _groupByDate(workouts);
                final entries = grouped.entries.toList();

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final entry = entries[index];
                      final dateLabel = entry.key;
                      final dayWorkouts = entry.value;

                      return Padding(
                        padding: AppSpacing.screenPadding,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (index > 0)
                              const SizedBox(height: AppSpacing.lg),
                            Padding(
                              padding: const EdgeInsets.only(
                                left: AppSpacing.xs,
                                bottom: AppSpacing.sm,
                              ),
                              child: Text(
                                dateLabel.toUpperCase(),
                                style:
                                    theme.textTheme.labelSmall?.copyWith(
                                  color: isDark
                                      ? AppColors.textTertiaryDark
                                      : AppColors.textTertiaryLight,
                                  letterSpacing: 1.2,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            ...dayWorkouts.asMap().entries.map((e) {
                              return Padding(
                                padding: EdgeInsets.only(
                                  bottom:
                                      e.key < dayWorkouts.length - 1
                                          ? AppSpacing.sm + 2
                                          : 0,
                                ),
                                child: WorkoutHistoryCard(
                                  workout: e.value,
                                  index: e.key,
                                ),
                              );
                            }),
                          ],
                        ),
                      );
                    },
                    childCount: entries.length,
                  ),
                );
              },
            ),

            // Bottom padding for tab bar
            const SliverToBoxAdapter(
              child: SizedBox(height: AppSpacing.xxxxl * 2.5),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, List<Workout>> _groupByDate(List<Workout> workouts) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final Map<String, List<Workout>> grouped = {};

    for (final workout in workouts) {
      final wDate = DateTime(
        workout.date.year,
        workout.date.month,
        workout.date.day,
      );

      String label;
      if (wDate == today) {
        label = 'Today';
      } else if (wDate == yesterday) {
        label = 'Yesterday';
      } else if (now.difference(wDate).inDays < 7) {
        label = DateFormat('EEEE').format(wDate);
      } else {
        label = DateFormat('MMM d, yyyy').format(wDate);
      }

      grouped.putIfAbsent(label, () => []).add(workout);
    }

    return grouped;
  }
}

// ─────────────────────────── Premium Stat Card ───────────────────────────

class _PremiumStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;
  final bool isHighlighted;

  const _PremiumStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.lg,
        horizontal: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isHighlighted
              ? color.withValues(alpha: 0.3)
              : isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : AppColors.dividerLight,
        ),
        boxShadow: isDark ? AppColors.cardShadowDark : AppColors.cardShadowLight,
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: isHighlighted ? color : null,
            ),
          ),
          const SizedBox(height: AppSpacing.xs / 2),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────── Quick Action Card ───────────────────────────

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final bool isDark;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : AppColors.dividerLight,
          ),
          boxShadow: isDark ? AppColors.cardShadowDark : AppColors.cardShadowLight,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              label,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs / 2),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AppColors.textTertiaryDark
                    : AppColors.textTertiaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────── Empty State ───────────────────────────

class _EmptyState extends StatelessWidget {
  final bool isDark;
  final VoidCallback onStartWorkout;

  const _EmptyState({
    required this.isDark,
    required this.onStartWorkout,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xxxxl,
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : cs.surfaceContainerHigh.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.fitness_center_rounded,
              size: 36,
              color: cs.onSurfaceVariant.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'No workouts yet',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Start your first workout to begin\ntracking your progress',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark
                  ? AppColors.textTertiaryDark
                  : AppColors.textTertiaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          SizedBox(
            width: 200,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBlue.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: onStartWorkout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.md,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusPill),
                  ),
                ),
                child: Text(
                  'Start Workout',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms)
        .scale(
          begin: const Offset(0.95, 0.95),
          end: const Offset(1, 1),
          duration: 500.ms,
          curve: Curves.easeOut,
        );
  }
}
