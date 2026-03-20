import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:alfanutrition/core/theme/app_colors.dart';
import 'package:alfanutrition/core/theme/app_spacing.dart';
import 'package:alfanutrition/core/constants/app_constants.dart';
import 'package:alfanutrition/core/widgets/section_header.dart';
import 'package:alfanutrition/features/home/providers/home_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final userName = ref.watch(userNameProvider).valueOrNull ?? '';
    final nutrition =
        ref.watch(todaysNutritionProvider).valueOrNull ??
        const DailyNutrition(
          caloriesConsumed: 0,
          caloriesTarget: AppConstants.defaultCalorieTarget,
          proteinConsumed: 0,
          proteinTarget: AppConstants.defaultProteinTarget,
          carbsConsumed: 0,
          carbsTarget: AppConstants.defaultCarbsTarget,
          fatsConsumed: 0,
          fatsTarget: AppConstants.defaultFatsTarget,
        );
    final todaysWorkout = ref.watch(todaysWorkoutProvider).valueOrNull;
    final weeklySummary =
        ref.watch(weeklyWorkoutSummaryProvider).valueOrNull ??
        const WeeklyWorkoutSummary(
          trainedDays: [false, false, false, false, false, false, false],
          totalWorkouts: 0,
          totalMinutes: 0,
        );
    final recentWorkouts =
        ref.watch(recentWorkoutsProvider).valueOrNull ?? [];

    return Scaffold(
      body: RefreshIndicator(
        color: theme.colorScheme.primary,
        onRefresh: () async {
          HapticFeedback.mediumImpact();
          ref.invalidate(todaysNutritionProvider);
          ref.invalidate(todaysWorkoutProvider);
          ref.invalidate(weeklyWorkoutSummaryProvider);
          ref.invalidate(recentWorkoutsProvider);
          ref.invalidate(userNameProvider);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            // Safe area top padding
            SliverToBoxAdapter(
              child: SizedBox(
                height: MediaQuery.of(context).padding.top + AppSpacing.md,
              ),
            ),

            // 1. Greeting Header
            SliverToBoxAdapter(
              child: Padding(
                padding: AppSpacing.screenPadding,
                child: _GreetingHeader(userName: userName),
              ),
            ),

            SliverToBoxAdapter(
              child: SizedBox(height: AppSpacing.xxl),
            ),

            // 2. Today's Summary Card (Hero Nutrition)
            SliverToBoxAdapter(
              child: Padding(
                padding: AppSpacing.screenPadding,
                child: _HeroNutritionCard(nutrition: nutrition),
              ),
            ),

            SliverToBoxAdapter(
              child: SizedBox(height: AppSpacing.xxl),
            ),

            // 3. Today's Workout Card
            SliverToBoxAdapter(
              child: Padding(
                padding: AppSpacing.screenPadding,
                child: _TodaysWorkoutCard(workout: todaysWorkout),
              ),
            ),

            SliverToBoxAdapter(
              child: SizedBox(height: AppSpacing.xxl),
            ),

            // 4. Weekly Streak
            SliverToBoxAdapter(
              child: Padding(
                padding: AppSpacing.screenPadding,
                child: _WeeklyStreakCard(summary: weeklySummary),
              ),
            ),

            SliverToBoxAdapter(
              child: SizedBox(height: AppSpacing.xxl),
            ),

            // 5. Quick Actions (2x2)
            SliverToBoxAdapter(
              child: _QuickActionsSection(),
            ),

            SliverToBoxAdapter(
              child: SizedBox(height: AppSpacing.xxl),
            ),

            // 6. Recent Activity
            if (recentWorkouts.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: _RecentActivitySection(workouts: recentWorkouts),
              ),
              SliverToBoxAdapter(
                child: SizedBox(height: AppSpacing.xxl),
              ),
            ],

            // Bottom padding for tab bar
            SliverToBoxAdapter(
              child: SizedBox(
                height: MediaQuery.of(context).padding.bottom + 100,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// 1. Greeting Header
// =============================================================================

class _GreetingHeader extends StatelessWidget {
  final String userName;

  const _GreetingHeader({required this.userName});

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, MMMM d').format(now);
    final displayName =
        userName.isNotEmpty ? userName.split(' ').first : 'there';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Profile Avatar
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            context.push('/profile');
          },
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryBlue.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: AppSpacing.md),

        // Greeting text + date
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$_greeting,',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: AppSpacing.xs),
              Text(
                displayName,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              SizedBox(height: AppSpacing.xs),
              Text(
                dateStr,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppColors.textTertiaryDark
                      : AppColors.textTertiaryLight,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        // Notification bell
        Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : AppColors.surfaceLight2,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              context.push('/reminders');
            },
            icon: Icon(
              Icons.notifications_outlined,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
              size: 22,
            ),
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(duration: 500.ms, curve: Curves.easeOut)
        .slideX(
          begin: -0.03,
          end: 0,
          duration: 500.ms,
          curve: Curves.easeOut,
        );
  }
}

// =============================================================================
// 2. Hero Nutrition Card
// =============================================================================

class _HeroNutritionCard extends StatelessWidget {
  final DailyNutrition nutrition;

  const _HeroNutritionCard({required this.nutrition});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final consumed = nutrition.caloriesConsumed.toInt();
    final target = nutrition.caloriesTarget.toInt();
    final remaining = nutrition.caloriesRemaining.toInt();

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        // Navigate to nutrition tab
        context.go('/nutrition');
      },
      child: Container(
        padding: EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: AppSpacing.borderRadiusXl,
          border: isDark
              ? Border.all(
                  color: Colors.white.withValues(alpha: 0.07),
                  width: 1,
                )
              : null,
          boxShadow: isDark ? AppColors.cardShadowDark : AppColors.elevatedShadowLight,
        ),
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TODAY\'S NUTRITION',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textTertiaryLight,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                    SizedBox(height: AppSpacing.xs),
                    Text(
                      '$consumed / $target kcal',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: isDark
                      ? AppColors.textTertiaryDark
                      : AppColors.textTertiaryLight,
                ),
              ],
            ),

            SizedBox(height: AppSpacing.xxl),

            // Large Calorie Ring
            CircularPercentIndicator(
              radius: 85,
              lineWidth: 12,
              percent: nutrition.caloriesPercent,
              animation: true,
              animationDuration: 1200,
              circularStrokeCap: CircularStrokeCap.round,
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : AppColors.surfaceLight2,
              linearGradient: AppColors.primaryGradient,
              center: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${remaining.abs()}',
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    remaining >= 0 ? 'kcal left' : 'kcal over',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: remaining >= 0
                          ? (isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight)
                          : AppColors.error,
                      letterSpacing: 0.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: AppSpacing.xxl),

            // 3 Macro Pills
            Row(
              children: [
                Expanded(
                  child: _MacroPill(
                    label: 'Protein',
                    current: nutrition.proteinConsumed,
                    target: nutrition.proteinTarget,
                    percent: nutrition.proteinPercent,
                    color: AppColors.primaryBlue,
                  ),
                ),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _MacroPill(
                    label: 'Carbs',
                    current: nutrition.carbsConsumed,
                    target: nutrition.carbsTarget,
                    percent: nutrition.carbsPercent,
                    color: AppColors.accent,
                  ),
                ),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _MacroPill(
                    label: 'Fats',
                    current: nutrition.fatsConsumed,
                    target: nutrition.fatsTarget,
                    percent: nutrition.fatsPercent,
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms, curve: Curves.easeOut)
        .slideY(begin: 0.05, end: 0, duration: 600.ms, curve: Curves.easeOut);
  }
}

class _MacroPill extends StatelessWidget {
  final String label;
  final double current;
  final double target;
  final double percent;
  final Color color;

  const _MacroPill({
    required this.label,
    required this.current,
    required this.target,
    required this.percent,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? color.withValues(alpha: 0.08)
            : color.withValues(alpha: 0.06),
        borderRadius: AppSpacing.borderRadiusMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 10,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            '${current.toInt()}g',
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            '/ ${target.toInt()}g',
            style: theme.textTheme.labelSmall?.copyWith(
              color: isDark
                  ? AppColors.textTertiaryDark
                  : AppColors.textTertiaryLight,
              fontWeight: FontWeight.w500,
              fontSize: 10,
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          // Progress bar
          ClipRRect(
            borderRadius: AppSpacing.borderRadiusPill,
            child: SizedBox(
              height: 4,
              child: Stack(
                children: [
                  Container(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : color.withValues(alpha: 0.15),
                  ),
                  FractionallySizedBox(
                    widthFactor: percent,
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: AppSpacing.borderRadiusPill,
                      ),
                    ),
                  )
                      .animate()
                      .scaleX(
                        begin: 0,
                        end: 1,
                        alignment: Alignment.centerLeft,
                        duration: 800.ms,
                        curve: Curves.easeOutCubic,
                        delay: 400.ms,
                      ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 3. Today's Workout Card
// =============================================================================

class _TodaysWorkoutCard extends StatelessWidget {
  final TodaysWorkout? workout;

  const _TodaysWorkoutCard({required this.workout});

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
          ? _buildWorkoutContent(context, theme, isDark)
          : _buildEmptyState(context, theme, isDark),
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: 100.ms, curve: Curves.easeOut)
        .slideY(
          begin: 0.05,
          end: 0,
          duration: 500.ms,
          delay: 100.ms,
          curve: Curves.easeOut,
        );
  }

  Widget _buildWorkoutContent(
      BuildContext context, ThemeData theme, bool isDark) {
    final w = workout!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section label
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: w.isCompleted
                    ? AppColors.success.withValues(alpha: 0.15)
                    : AppColors.primaryBlue.withValues(alpha: 0.15),
                borderRadius: AppSpacing.borderRadiusSm,
              ),
              child: Icon(
                w.isCompleted
                    ? Icons.check_circle_rounded
                    : Icons.fitness_center_rounded,
                size: 16,
                color: w.isCompleted ? AppColors.success : AppColors.primaryBlue,
              ),
            ),
            SizedBox(width: AppSpacing.sm),
            Text(
              w.isCompleted ? 'COMPLETED' : 'TODAY\'S WORKOUT',
              style: theme.textTheme.labelSmall?.copyWith(
                color: w.isCompleted ? AppColors.success : AppColors.primaryBlue,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.lg),

        // Workout name
        Text(
          w.name,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: AppSpacing.sm),

        // Meta row
        Row(
          children: [
            if (w.focus != null) ...[
              _MetaChip(
                icon: Icons.track_changes_rounded,
                label: w.focus!,
                isDark: isDark,
                theme: theme,
              ),
              SizedBox(width: AppSpacing.sm),
            ],
            _MetaChip(
              icon: Icons.timer_outlined,
              label: '${w.durationMinutes} min',
              isDark: isDark,
              theme: theme,
            ),
            SizedBox(width: AppSpacing.sm),
            _MetaChip(
              icon: Icons.format_list_numbered_rounded,
              label: '${w.exerciseCount} exercises',
              isDark: isDark,
              theme: theme,
            ),
          ],
        ),
        SizedBox(height: AppSpacing.xl),

        // Muscle group color dots
        if (w.muscleGroups.isNotEmpty) ...[
          Row(
            children: [
              ...w.muscleGroups.take(4).map((muscle) {
                return Padding(
                  padding: EdgeInsets.only(right: AppSpacing.xs),
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.colorForMuscle(muscle),
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              }),
              SizedBox(width: AppSpacing.xs),
              Text(
                w.muscleGroups
                    .take(3)
                    .map((m) => m.displayName)
                    .join(', '),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.lg),
        ],

        // Action button
        if (w.isCompleted)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.push('/workout/${w.id}'),
              icon: Icon(Icons.check_circle_rounded,
                  size: 18, color: AppColors.success),
              label: Text(
                'View Details',
                style: TextStyle(color: AppColors.success),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                    color: AppColors.success.withValues(alpha: 0.3)),
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: AppSpacing.borderRadiusMd,
                ),
              ),
            ),
          )
        else
          SizedBox(
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
                onPressed: () => context.push('/log-workout'),
                icon: const Icon(Icons.edit_note_rounded, size: 20),
                label: const Text('LOG WORKOUT'),
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
          ),
      ],
    );
  }

  Widget _buildEmptyState(
      BuildContext context, ThemeData theme, bool isDark) {
    return Column(
      children: [
        SizedBox(height: AppSpacing.sm),
        Icon(
          Icons.self_improvement_rounded,
          size: 48,
          color: isDark
              ? AppColors.textTertiaryDark
              : AppColors.textTertiaryLight,
        ),
        SizedBox(height: AppSpacing.lg),
        Text(
          'Rest Day',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: AppSpacing.xs),
        Text(
          'No workout planned. Start a freestyle session\nor take the day to recover.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
            height: 1.5,
          ),
        ),
        SizedBox(height: AppSpacing.xl),
        SizedBox(
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
              onPressed: () => context.push('/log-workout'),
              icon: const Icon(Icons.play_arrow_rounded, size: 20),
              label: const Text('FREESTYLE WORKOUT'),
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
        ),
        SizedBox(height: AppSpacing.sm),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final ThemeData theme;

  const _MetaChip({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : AppColors.surfaceLight2,
        borderRadius: AppSpacing.borderRadiusPill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: isDark
                ? AppColors.textTertiaryDark
                : AppColors.textTertiaryLight,
          ),
          SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 4. Weekly Streak Card
// =============================================================================

class _WeeklyStreakCard extends StatelessWidget {
  final WeeklyWorkoutSummary summary;

  const _WeeklyStreakCard({required this.summary});

  static const _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final todayIndex = DateTime.now().weekday - 1;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with streak badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Weekly Activity',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (summary.streak > 0)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm + 2,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.15),
                    borderRadius: AppSpacing.borderRadiusPill,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '\u{1F525}',
                        style: TextStyle(fontSize: 12),
                      ),
                      SizedBox(width: AppSpacing.xs),
                      Text(
                        '${summary.streak} Day Streak',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          SizedBox(height: AppSpacing.xl),

          // Day indicators row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (index) {
              final trained = summary.trainedDays[index];
              final isToday = index == todayIndex;
              final isPast = index < todayIndex;

              return _DayIndicator(
                label: _dayLabels[index],
                trained: trained,
                isToday: isToday,
                isPast: isPast,
                index: index,
              );
            }),
          ),

          SizedBox(height: AppSpacing.lg),

          // Summary stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _WeekStat(
                value: '${summary.daysTrained}',
                label: 'Days',
                isDark: isDark,
                theme: theme,
              ),
              Container(
                width: 1,
                height: 24,
                color: isDark
                    ? AppColors.dividerDark
                    : AppColors.dividerLight,
              ),
              _WeekStat(
                value: '${summary.totalWorkouts}',
                label: 'Workouts',
                isDark: isDark,
                theme: theme,
              ),
              Container(
                width: 1,
                height: 24,
                color: isDark
                    ? AppColors.dividerDark
                    : AppColors.dividerLight,
              ),
              _WeekStat(
                value: '${summary.totalMinutes}',
                label: 'Minutes',
                isDark: isDark,
                theme: theme,
              ),
            ],
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: 200.ms, curve: Curves.easeOut)
        .slideY(
          begin: 0.05,
          end: 0,
          duration: 500.ms,
          delay: 200.ms,
          curve: Curves.easeOut,
        );
  }
}

class _DayIndicator extends StatelessWidget {
  final String label;
  final bool trained;
  final bool isToday;
  final bool isPast;
  final int index;

  const _DayIndicator({
    required this.label,
    required this.trained,
    required this.isToday,
    required this.isPast,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color dotColor;
    Color dotBorder;
    if (trained) {
      dotColor = theme.colorScheme.primary;
      dotBorder = theme.colorScheme.primary;
    } else if (isToday) {
      dotColor = Colors.transparent;
      dotBorder = theme.colorScheme.primary;
    } else if (isPast) {
      dotColor = isDark
          ? Colors.white.withValues(alpha: 0.06)
          : AppColors.surfaceLight3;
      dotBorder = Colors.transparent;
    } else {
      dotColor = isDark
          ? Colors.white.withValues(alpha: 0.04)
          : AppColors.surfaceLight2;
      dotBorder = Colors.transparent;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: isToday
                ? theme.colorScheme.primary
                : (isDark
                    ? AppColors.textTertiaryDark
                    : AppColors.textTertiaryLight),
            fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
            fontSize: 11,
          ),
        ),
        SizedBox(height: AppSpacing.sm),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: dotBorder,
              width: isToday && !trained ? 2 : 0,
            ),
          ),
          child: trained
              ? const Icon(
                  Icons.check_rounded,
                  size: 14,
                  color: Colors.white,
                )
              : null,
        ),
      ],
    )
        .animate()
        .fadeIn(
          duration: 300.ms,
          delay: Duration(milliseconds: 50 * index),
        )
        .scale(
          begin: const Offset(0.5, 0.5),
          end: const Offset(1.0, 1.0),
          duration: 300.ms,
          delay: Duration(milliseconds: 50 * index),
          curve: Curves.easeOutBack,
        );
  }
}

class _WeekStat extends StatelessWidget {
  final String value;
  final String label;
  final bool isDark;
  final ThemeData theme;

  const _WeekStat({
    required this.value,
    required this.label,
    required this.isDark,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: isDark
                ? AppColors.textTertiaryDark
                : AppColors.textTertiaryLight,
            fontWeight: FontWeight.w500,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// 5. Quick Actions Grid (2x2)
// =============================================================================

class _QuickActionsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Quick Actions',
          padding: AppSpacing.screenPadding,
        ),
        SizedBox(height: AppSpacing.md),
        Padding(
          padding: AppSpacing.screenPadding,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _QuickActionTile(
                      icon: Icons.restaurant_rounded,
                      label: 'Log Food',
                      subtitle: 'Track meals',
                      color: AppColors.accent,
                      onTap: () => context.push('/add-meal'),
                      index: 0,
                    ),
                  ),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _QuickActionTile(
                      icon: Icons.fitness_center_rounded,
                      label: 'Log Workout',
                      subtitle: 'Hit the gym',
                      color: AppColors.primaryBlue,
                      onTap: () => context.push('/log-workout'),
                      index: 1,
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _QuickActionTile(
                      icon: Icons.monitor_weight_outlined,
                      label: 'Body Stats',
                      subtitle: 'Log metrics',
                      color: AppColors.warning,
                      onTap: () => context.push('/add-body-metric'),
                      index: 2,
                    ),
                  ),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _QuickActionTile(
                      icon: Icons.accessibility_new_rounded,
                      label: 'Muscle Map',
                      subtitle: 'Body analysis',
                      color: AppColors.success,
                      onTap: () => context.push('/muscles'),
                      index: 3,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: 300.ms, curve: Curves.easeOut)
        .slideY(
          begin: 0.05,
          end: 0,
          duration: 500.ms,
          delay: 300.ms,
          curve: Curves.easeOut,
        );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final int index;

  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: AppSpacing.borderRadiusLg,
        child: Container(
          padding: EdgeInsets.all(AppSpacing.lg),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Colored icon container (40x40)
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isDark ? 0.15 : 0.1),
                  borderRadius: AppSpacing.borderRadiusMd,
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: color,
                ),
              ),
              SizedBox(height: AppSpacing.md),
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: AppSpacing.xs),
              Text(
                subtitle,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isDark
                      ? AppColors.textTertiaryDark
                      : AppColors.textTertiaryLight,
                  fontWeight: FontWeight.w500,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// 6. Recent Activity Section
// =============================================================================

class _RecentActivitySection extends StatelessWidget {
  final List<RecentWorkout> workouts;

  const _RecentActivitySection({required this.workouts});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Recent Activity',
          onSeeAll: () {
            HapticFeedback.lightImpact();
            context.go('/workouts');
          },
          padding: AppSpacing.screenPadding,
        ),
        SizedBox(height: AppSpacing.md),
        Padding(
          padding: AppSpacing.screenPadding,
          child: Column(
            children: workouts
                .take(3)
                .toList()
                .asMap()
                .entries
                .map((entry) {
              final index = entry.key;
              final workout = entry.value;
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index < workouts.length - 1 && index < 2
                      ? AppSpacing.sm
                      : 0,
                ),
                child: _RecentWorkoutCard(
                    workout: workout, index: index),
              );
            }).toList(),
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: 350.ms, curve: Curves.easeOut)
        .slideY(
          begin: 0.05,
          end: 0,
          duration: 500.ms,
          delay: 350.ms,
          curve: Curves.easeOut,
        );
  }
}

class _RecentWorkoutCard extends StatelessWidget {
  final RecentWorkout workout;
  final int index;

  const _RecentWorkoutCard({
    required this.workout,
    required this.index,
  });

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final workoutDay = DateTime(date.year, date.month, date.day);
    final diff = today.difference(workoutDay).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return '${diff}d ago';
    return DateFormat('MMM d').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryMuscleColor = workout.muscleGroups.isNotEmpty
        ? AppColors.colorForMuscle(workout.muscleGroups.first)
        : AppColors.primaryBlue;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push('/workout/${workout.id}');
      },
      child: Container(
        padding: AppSpacing.cardPaddingCompact,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: AppSpacing.borderRadiusMd,
          border: isDark
              ? Border.all(
                  color: Colors.white.withValues(alpha: 0.07),
                  width: 1,
                )
              : null,
          boxShadow: isDark ? null : AppColors.cardShadowLight,
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Colored left border
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: primaryMuscleColor,
                  borderRadius: AppSpacing.borderRadiusPill,
                ),
              ),
              SizedBox(width: AppSpacing.md),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      workout.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Text(
                          '${workout.exerciseCount} exercises',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? AppColors.textTertiaryDark
                                : AppColors.textTertiaryLight,
                            fontSize: 11,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.xs),
                          child: Text(
                            '\u00B7',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark
                                  ? AppColors.textTertiaryDark
                                  : AppColors.textTertiaryLight,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          '${workout.totalSets} sets',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? AppColors.textTertiaryDark
                                : AppColors.textTertiaryLight,
                            fontSize: 11,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.xs),
                          child: Text(
                            '\u00B7',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark
                                  ? AppColors.textTertiaryDark
                                  : AppColors.textTertiaryLight,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          '${workout.durationMinutes} min',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? AppColors.textTertiaryDark
                                : AppColors.textTertiaryLight,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Date + muscle dots + chevron
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _formatDate(workout.date),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiaryLight,
                      fontWeight: FontWeight.w500,
                      fontSize: 10,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: workout.muscleGroups.take(3).map((muscle) {
                      return Padding(
                        padding: EdgeInsets.only(left: AppSpacing.xs),
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.colorForMuscle(muscle),
                            shape: BoxShape.circle,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              SizedBox(width: AppSpacing.sm),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: isDark
                    ? AppColors.textTertiaryDark
                    : AppColors.textTertiaryLight,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
