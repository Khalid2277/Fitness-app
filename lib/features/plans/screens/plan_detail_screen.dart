import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:alfanutrition/core/theme/app_colors.dart';
import 'package:alfanutrition/core/theme/app_spacing.dart';
import 'package:alfanutrition/data/models/workout_plan.dart';
import 'package:alfanutrition/data/supabase/data_source.dart';
import 'package:alfanutrition/data/supabase/supabase_providers.dart';
import 'package:alfanutrition/features/plans/providers/plan_providers.dart';
import 'package:alfanutrition/features/plans/widgets/plan_day_card.dart';

class PlanDetailScreen extends ConsumerStatefulWidget {
  const PlanDetailScreen({super.key, required this.planId});

  final String planId;

  @override
  ConsumerState<PlanDetailScreen> createState() => _PlanDetailScreenState();
}

class _PlanDetailScreenState extends ConsumerState<PlanDetailScreen> {
  Map<String, dynamic>? _plan;
  bool _isLoading = true;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _loadPlan();
  }

  Future<void> _loadPlan() async {
    // First check if this is a just-generated plan
    final generatedPlan = ref.read(generatedPlanProvider);
    if (generatedPlan != null && generatedPlan['id'] == widget.planId) {
      setState(() {
        _plan = generatedPlan;
        _isLoading = false;
        _isSaved = false;
      });
      return;
    }

    // Otherwise load from repository
    final repo = ref.read(planRepositoryProvider);
    final plan = await repo.getPlan(widget.planId);
    setState(() {
      _plan = plan;
      _isLoading = false;
      _isSaved = plan != null;
    });
  }

  Future<void> _savePlan() async {
    if (_plan == null) return;

    final source = ref.read(dataSourceProvider);
    if (source == DataSourceType.supabase) {
      final sbRepo = ref.read(sbPlanRepositoryProvider);
      final workoutPlan = WorkoutPlan.fromJson(_plan!);
      await sbRepo.savePlan(workoutPlan);
    } else {
      final repo = ref.read(planRepositoryProvider);
      await repo.savePlan(_plan!);
    }

    ref.invalidate(savedPlansProvider);
    setState(() => _isSaved = true);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Plan saved successfully!'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusMd,
          ),
        ),
      );
    }
  }

  Future<void> _deletePlan() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Plan'),
        content: const Text(
            'Are you sure you want to delete this workout plan? This action cannot be undone.'),
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

    if (confirmed == true && _plan != null) {
      final repo = ref.read(planRepositoryProvider);
      await repo.deletePlan(_plan!['id'] as String);
      ref.invalidate(savedPlansProvider);
      ref.read(generatedPlanProvider.notifier).state = null;

      if (mounted) context.pop();
    }
  }

  Future<void> _setAsActive() async {
    if (_plan == null) return;
    if (!_isSaved) await _savePlan();

    final repo = ref.read(planRepositoryProvider);
    await repo.setActivePlan(_plan!['id'] as String);
    ref.invalidate(savedPlansProvider);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Plan set as active!'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusMd,
          ),
        ),
      );
    }
  }

  String _displaySplitType(String? splitType) {
    if (splitType == null) return '';
    switch (splitType) {
      case 'pushPullLegs':
        return 'Push/Pull/Legs';
      case 'upperLower':
        return 'Upper/Lower';
      case 'broSplit':
        return 'Bro Split';
      case 'fullBody':
        return 'Full Body';
      case 'arnoldSplit':
        return 'Arnold Split';
      default:
        return splitType;
    }
  }

  String _displayGoal(String? goal) {
    if (goal == null) return '';
    switch (goal) {
      case 'strength':
        return 'Strength';
      case 'hypertrophy':
        return 'Hypertrophy';
      case 'endurance':
        return 'Endurance';
      case 'fatLoss':
        return 'Fat Loss';
      default:
        return goal;
    }
  }

  String _displayExperience(String? level) {
    if (level == null) return '';
    switch (level) {
      case 'beginner':
        return 'Beginner';
      case 'intermediate':
        return 'Intermediate';
      case 'advanced':
        return 'Advanced';
      default:
        return level;
    }
  }

  Color _colorForGoal(String? goal) {
    switch (goal) {
      case 'strength':
        return AppColors.error;
      case 'hypertrophy':
        return AppColors.primaryBlue;
      case 'endurance':
        return AppColors.accent;
      case 'fatLoss':
        return AppColors.warning;
      default:
        return AppColors.info;
    }
  }

  int _totalExerciseCount(List days) {
    int count = 0;
    for (final day in days) {
      final dayMap =
          day is Map ? Map<String, dynamic>.from(day) : <String, dynamic>{};
      final exercises = dayMap['exercises'] as List?;
      if (exercises != null) count += exercises.length;
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: AppSpacing.lg),
              Text('Loading plan...', style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      );
    }

    if (_plan == null) {
      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.surfaceDark2
                              : AppColors.surfaceLight2,
                          borderRadius: AppSpacing.borderRadiusMd,
                        ),
                        child: Icon(Icons.arrow_back_ios_new_rounded,
                            size: 18, color: theme.colorScheme.onSurface),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        size: 48,
                        color: theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text('Plan not found',
                          style: theme.textTheme.headlineSmall),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final plan = _plan!;
    final days = (plan['days'] as List?) ?? [];
    final daysPerWeek = plan['daysPerWeek'] as int? ?? days.length;
    final goal = plan['goal'] as String?;
    final goalColor = _colorForGoal(goal);
    final totalExercises = _totalExerciseCount(days);

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                // ── Hero Header ──────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Gradient hero area
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              goalColor.withValues(alpha: isDark ? 0.2 : 0.12),
                              goalColor.withValues(alpha: isDark ? 0.05 : 0.03),
                            ],
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                              AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xxl),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Nav row
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      ref
                                          .read(
                                              generatedPlanProvider.notifier)
                                          .state = null;
                                      context.pop();
                                    },
                                    child: Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? Colors.white
                                                .withValues(alpha: 0.1)
                                            : Colors.white
                                                .withValues(alpha: 0.8),
                                        borderRadius:
                                            AppSpacing.borderRadiusMd,
                                        border: Border.all(
                                          color: isDark
                                              ? Colors.white
                                                  .withValues(alpha: 0.08)
                                              : AppColors.dividerLight,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.arrow_back_ios_new_rounded,
                                        size: 18,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  // Actions menu
                                  PopupMenuButton<String>(
                                    onSelected: (value) {
                                      switch (value) {
                                        case 'activate':
                                          _setAsActive();
                                          break;
                                        case 'delete':
                                          _deletePlan();
                                          break;
                                      }
                                    },
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          AppSpacing.borderRadiusMd,
                                    ),
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'activate',
                                        child: Row(
                                          children: [
                                            Icon(Icons.star_rounded,
                                                size: 20),
                                            SizedBox(
                                                width:
                                                    AppSpacing.sm + 2),
                                            Text('Set as Active'),
                                          ],
                                        ),
                                      ),
                                      if (_isSaved)
                                        PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              Icon(
                                                  Icons.delete_rounded,
                                                  size: 20,
                                                  color:
                                                      AppColors.error),
                                              const SizedBox(
                                                  width:
                                                      AppSpacing.sm + 2),
                                              Text('Delete Plan',
                                                  style: theme
                                                      .textTheme
                                                      .bodyMedium
                                                      ?.copyWith(
                                                          color: AppColors
                                                              .error)),
                                            ],
                                          ),
                                        ),
                                    ],
                                    child: Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? Colors.white
                                                .withValues(alpha: 0.1)
                                            : Colors.white
                                                .withValues(alpha: 0.8),
                                        borderRadius:
                                            AppSpacing.borderRadiusMd,
                                        border: Border.all(
                                          color: isDark
                                              ? Colors.white
                                                  .withValues(alpha: 0.08)
                                              : AppColors.dividerLight,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.more_horiz_rounded,
                                        size: 20,
                                        color:
                                            theme.colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.xl),

                              // Plan name
                              Text(
                                plan['name'] as String? ?? 'Workout Plan',
                                style:
                                    theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              )
                                  .animate()
                                  .fadeIn(duration: 400.ms)
                                  .slideX(
                                      begin: -0.03,
                                      end: 0,
                                      duration: 400.ms),

                              const SizedBox(height: AppSpacing.md),

                              // Metadata chips
                              Wrap(
                                spacing: AppSpacing.sm,
                                runSpacing: AppSpacing.sm,
                                children: [
                                  _MetadataChip(
                                    icon: Icons.view_week_rounded,
                                    label: _displaySplitType(
                                        plan['splitType'] as String?),
                                    color: AppColors.primaryBlue,
                                    isDark: isDark,
                                  ),
                                  _MetadataChip(
                                    icon: Icons.flag_rounded,
                                    label: _displayGoal(goal),
                                    color: goalColor,
                                    isDark: isDark,
                                  ),
                                  _MetadataChip(
                                    icon:
                                        Icons.signal_cellular_alt_rounded,
                                    label: _displayExperience(
                                        plan['experience'] as String?),
                                    color: AppColors.warning,
                                    isDark: isDark,
                                  ),
                                  _MetadataChip(
                                    icon: Icons.calendar_today_rounded,
                                    label: '${daysPerWeek}x / week',
                                    color: AppColors.info,
                                    isDark: isDark,
                                  ),
                                ],
                              )
                                  .animate()
                                  .fadeIn(
                                      delay: 100.ms, duration: 400.ms),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // ── Overview Card ────────────────────────────────────
                      Padding(
                        padding: AppSpacing.screenPadding,
                        child: Container(
                          padding: AppSpacing.cardPadding,
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.surfaceDark1
                                : AppColors.surfaceLight,
                            borderRadius: AppSpacing.borderRadiusLg,
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.06)
                                  : AppColors.dividerLight,
                            ),
                            boxShadow: isDark
                                ? AppColors.cardShadowDark
                                : AppColors.cardShadowLight,
                          ),
                          child: Row(
                            children: [
                              _OverviewStat(
                                icon: Icons.calendar_view_week_rounded,
                                value: '${days.length}',
                                label: 'Days',
                                color: AppColors.primaryBlue,
                                isDark: isDark,
                              ),
                              _OverviewDivider(isDark: isDark),
                              _OverviewStat(
                                icon: Icons.fitness_center_rounded,
                                value: '$totalExercises',
                                label: 'Exercises',
                                color: AppColors.accent,
                                isDark: isDark,
                              ),
                              _OverviewDivider(isDark: isDark),
                              _OverviewStat(
                                icon: Icons.timer_rounded,
                                value: '~${(totalExercises * 4).clamp(20, 90)}',
                                label: 'Min/Day',
                                color: AppColors.warning,
                                isDark: isDark,
                              ),
                            ],
                          ),
                        ),
                      )
                          .animate(delay: 150.ms)
                          .fadeIn(duration: 400.ms)
                          .slideY(begin: 0.05, duration: 400.ms),

                      const SizedBox(height: AppSpacing.xxl),

                      // Save button (if not yet saved)
                      if (!_isSaved)
                        Padding(
                          padding: AppSpacing.screenPadding,
                          child: GestureDetector(
                            onTap: _savePlan,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.md + 2),
                              decoration: BoxDecoration(
                                gradient: AppColors.accentGradient,
                                borderRadius: AppSpacing.borderRadiusMd,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.accent
                                        .withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.save_rounded,
                                      size: 20, color: Colors.white),
                                  const SizedBox(width: AppSpacing.sm),
                                  Text(
                                    'Save Plan',
                                    style: theme.textTheme.titleSmall
                                        ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                            .animate(delay: 200.ms)
                            .fadeIn(duration: 400.ms)
                            .slideY(begin: 0.1, end: 0, duration: 400.ms),

                      if (!_isSaved)
                        const SizedBox(height: AppSpacing.xxl),

                      // ── Training Days Header ─────────────────────────────
                      Padding(
                        padding: AppSpacing.screenPadding,
                        child: Row(
                          children: [
                            Container(
                              width: 4,
                              height: 20,
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusPill),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              'Training Days',
                              style:
                                  theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm + 2,
                                vertical: AppSpacing.xs,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.surfaceDark2
                                    : AppColors.surfaceLight2,
                                borderRadius: AppSpacing.borderRadiusPill,
                              ),
                              child: Text(
                                '${days.length} day${days.length == 1 ? '' : 's'}',
                                style: theme.textTheme.labelSmall
                                    ?.copyWith(
                                  color: theme
                                      .colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ),
                ),

                // ── Day Cards ─────────────────────────────────────────────────
                SliverPadding(
                  padding: AppSpacing.screenPadding,
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final dayData = days[index];
                        final dayMap = dayData is Map
                            ? Map<String, dynamic>.from(dayData)
                            : <String, dynamic>{};
                        final dayName =
                            dayMap['name'] as String? ?? 'Day ${index + 1}';
                        final exercises = (dayMap['exercises'] as List?)
                                ?.map((e) => e is Map
                                    ? Map<String, dynamic>.from(e)
                                    : <String, dynamic>{})
                                .toList() ??
                            [];

                        return Padding(
                          padding: const EdgeInsets.only(
                              bottom: AppSpacing.itemSpacing),
                          child: PlanDayCard(
                            dayNumber: index + 1,
                            dayName: 'Day ${index + 1} - $dayName',
                            exercises: exercises,
                            onStartWorkout: () {
                              // Navigate to active workout
                              context.push('/log-workout');
                            },
                            delay:
                                Duration(milliseconds: 100 * index),
                          ),
                        );
                      },
                      childCount: days.length,
                    ),
                  ),
                ),

                // ── Bottom Spacing (for the fixed bottom button) ────────
                const SliverToBoxAdapter(
                  child: SizedBox(height: 100),
                ),
              ],
            ),

            // ── Fixed Bottom CTA ────────────────────────────────────────
            if (days.isNotEmpty)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      AppSpacing.md,
                      AppSpacing.xl,
                      AppSpacing.lg),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        (isDark
                                ? AppColors.backgroundDark
                                : AppColors.backgroundLight)
                            .withValues(alpha: 0),
                        isDark
                            ? AppColors.backgroundDark
                            : AppColors.backgroundLight,
                      ],
                      stops: const [0.0, 0.35],
                    ),
                  ),
                  child: GestureDetector(
                    onTap: () => context.push('/log-workout'),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.lg),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: AppSpacing.borderRadiusLg,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryBlue
                                .withValues(alpha: 0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.play_arrow_rounded,
                              size: 24, color: Colors.white),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            'Log Workout',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                    .animate(delay: 400.ms)
                    .fadeIn(duration: 500.ms)
                    .slideY(begin: 0.3, duration: 500.ms, curve: Curves.easeOut),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Overview Stat
// ─────────────────────────────────────────────────────────────────────────────

class _OverviewStat extends StatelessWidget {
  const _OverviewStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.isDark,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.15 : 0.08),
              borderRadius: AppSpacing.borderRadiusMd,
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewDivider extends StatelessWidget {
  const _OverviewDivider({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 48,
      color: isDark
          ? Colors.white.withValues(alpha: 0.06)
          : AppColors.dividerLight,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Metadata Chip
// ─────────────────────────────────────────────────────────────────────────────

class _MetadataChip extends StatelessWidget {
  const _MetadataChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (label.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm - 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.1),
        borderRadius: AppSpacing.borderRadiusPill,
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: AppSpacing.sm - 2),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
