import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:alfanutrition/core/theme/app_colors.dart';
import 'package:alfanutrition/core/theme/app_spacing.dart';
import 'package:alfanutrition/data/models/workout.dart';
import 'package:alfanutrition/data/models/enums.dart';
import 'package:alfanutrition/features/workouts/providers/workout_providers.dart';

class WorkoutsScreen extends ConsumerWidget {
  const WorkoutsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final selectedDate = ref.watch(selectedWorkoutDateProvider);
    final workoutsForDay = ref.watch(workoutsForDateProvider);
    final summary = ref.watch(dailyWorkoutSummaryProvider);
    final stats = ref.watch(workoutStatsProvider);
    final historyAsync = ref.watch(workoutHistoryProvider);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── 1. Header ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.primaryGradient,
                      ),
                      child: const Icon(
                        Icons.fitness_center_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Workouts',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('EEEE, MMMM d').format(selectedDate),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _HeaderButton(
                      icon: Icons.today_rounded,
                      isDark: isDark,
                      onTap: () {
                        final now = DateTime.now();
                        ref.read(selectedWorkoutDateProvider.notifier).state =
                            DateTime(now.year, now.month, now.day);
                      },
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.05),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),

            // ── 2. Date Selector ──
            SliverToBoxAdapter(
              child: _WorkoutDateSelector(isDark: isDark),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),

            // ── 3. Weekly Stats Row ──
            SliverToBoxAdapter(
              child: Padding(
                padding: AppSpacing.screenPadding,
                child: Row(
                  children: [
                    Expanded(
                      child: _MiniStatCard(
                        label: 'Total',
                        value: '${stats.totalWorkouts}',
                        icon: Icons.fitness_center_rounded,
                        color: AppColors.primaryBlue,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _MiniStatCard(
                        label: 'This Week',
                        value: '${stats.thisWeek}',
                        icon: Icons.calendar_today_rounded,
                        color: AppColors.accent,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _MiniStatCard(
                        label: 'Streak',
                        value: '${stats.streak}',
                        icon: Icons.local_fire_department_rounded,
                        color: AppColors.warning,
                        isDark: isDark,
                        isHighlighted: stats.streak > 0,
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 100.ms, duration: 400.ms).slideY(
                      begin: 0.05,
                      delay: 100.ms,
                      duration: 400.ms,
                    ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),

            // ── 4. Day Summary Card (when workouts exist) ──
            if (workoutsForDay.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: AppSpacing.screenPadding,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: AppSpacing.lg,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
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
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _SummaryColumn(
                          label: 'Sessions',
                          value: '${summary.workoutCount}',
                          icon: Icons.fitness_center_rounded,
                          color: AppColors.primaryBlue,
                          isDark: isDark,
                          theme: theme,
                        ),
                        Container(
                          width: 1,
                          height: 36,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : AppColors.dividerLight,
                        ),
                        _SummaryColumn(
                          label: 'Duration',
                          value: summary.formattedDuration,
                          icon: Icons.timer_outlined,
                          color: AppColors.accent,
                          isDark: isDark,
                          theme: theme,
                        ),
                        Container(
                          width: 1,
                          height: 36,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : AppColors.dividerLight,
                        ),
                        _SummaryColumn(
                          label: 'Volume',
                          value: summary.totalVolume >= 1000
                              ? '${(summary.totalVolume / 1000).toStringAsFixed(1)}t'
                              : '${summary.totalVolume.round()}kg',
                          icon: Icons.bar_chart_rounded,
                          color: AppColors.warning,
                          isDark: isDark,
                          theme: theme,
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05),
                ),
              ),

            if (workoutsForDay.isNotEmpty)
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),

            // ── 5. Workout Diary Label ──
            SliverToBoxAdapter(
              child: Padding(
                padding: AppSpacing.screenPadding,
                child: Row(
                  children: [
                    Text(
                      'WORKOUT DIARY',
                      style: theme.textTheme.labelSmall?.copyWith(
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textTertiaryLight,
                      ),
                    ),
                    const Spacer(),
                    if (workoutsForDay.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm + 2,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color:
                              AppColors.primaryBlue.withValues(alpha: 0.1),
                          borderRadius: AppSpacing.borderRadiusPill,
                        ),
                        child: Text(
                          '${workoutsForDay.length} session${workoutsForDay.length == 1 ? '' : 's'}',
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

            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),

            // ── 6. Workout Cards or Empty State ──
            if (workoutsForDay.isEmpty)
              SliverToBoxAdapter(
                child: _EmptyDayState(
                  isDark: isDark,
                  selectedDate: selectedDate,
                  onStartWorkout: () => context.push('/log-workout'),
                  onBrowsePlans: () => context.push('/plans'),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final workout = workoutsForDay[index];
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      child: _WorkoutDiaryCard(
                        workout: workout,
                        isDark: isDark,
                        onTap: () => context.push('/workout/${workout.id}'),
                        onDelete: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete Workout'),
                              content: Text(
                                  'Delete "${workout.name}"? This cannot be undone.'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(ctx, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(ctx, true),
                                  child: Text(
                                    'Delete',
                                    style: TextStyle(color: AppColors.error),
                                  ),
                                ),
                              ],
                            ),
                          );
                          if (confirmed == true) {
                            ref
                                .read(workoutHistoryProvider.notifier)
                                .deleteWorkout(workout.id);
                          }
                        },
                      )
                          .animate()
                          .fadeIn(
                            duration: 300.ms,
                            delay: (80 * index).ms,
                          )
                          .slideY(begin: 0.03),
                    );
                  },
                  childCount: workoutsForDay.length,
                ),
              ),

            // ── 7. Quick Actions ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, 0,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _QuickActionCard(
                        icon: Icons.description_outlined,
                        label: 'Plans',
                        subtitle: 'Routines',
                        color: AppColors.primaryBlue,
                        onTap: () => context.push('/plans'),
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _QuickActionCard(
                        icon: Icons.fitness_center_rounded,
                        label: 'Exercises',
                        subtitle: '90+ moves',
                        color: AppColors.accent,
                        onTap: () => context.push('/exercises'),
                        isDark: isDark,
                      ),
                    ),
                  ],
                )
                    .animate()
                    .fadeIn(delay: 300.ms, duration: 400.ms)
                    .slideY(begin: 0.05, delay: 300.ms, duration: 400.ms),
              ),
            ),

            // Bottom padding for tab bar
            const SliverToBoxAdapter(
              child: SizedBox(height: AppSpacing.xxxxl * 2.5),
            ),
          ],
        ),
      ),

      // ── Gradient FAB ──
      floatingActionButton: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryBlue.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => context.push('/log-workout'),
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          highlightElevation: 0,
          child: const Icon(Icons.add_rounded, size: 28),
        ),
      )
          .animate()
          .scale(
            begin: const Offset(0, 0),
            end: const Offset(1, 1),
            duration: 400.ms,
            delay: 300.ms,
            curve: Curves.easeOutBack,
          ),
    );
  }
}

// ─────────────────────────── Header Button ────────────────────────────────

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.icon,
    required this.isDark,
    required this.onTap,
  });
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon),
      style: IconButton.styleFrom(
        backgroundColor: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.04),
      ),
    );
  }
}

// ─────────────────────────── Date Selector ────────────────────────────────

class _WorkoutDateSelector extends ConsumerStatefulWidget {
  final bool isDark;
  const _WorkoutDateSelector({required this.isDark});

  @override
  ConsumerState<_WorkoutDateSelector> createState() =>
      _WorkoutDateSelectorState();
}

class _WorkoutDateSelectorState extends ConsumerState<_WorkoutDateSelector> {
  /// How many past days to show. Effectively unlimited history.
  static const int _pastDays = 365;
  static const int _futureDays = 1;
  static const int _totalDays = _pastDays + 1 + _futureDays;
  static const int _todayIndex = _pastDays;

  static const double _itemWidth = 50.0;
  static const double _itemSpacing = 8.0;

  late final ScrollController _scrollController;
  late final DateTime _baseDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _baseDate = DateTime(now.year, now.month, now.day);
    _scrollController = ScrollController(
      initialScrollOffset:
          _todayIndex * (_itemWidth + _itemSpacing) - 100,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToDate(ref.read(selectedWorkoutDateProvider));
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  DateTime _dateAtIndex(int index) {
    return _baseDate.add(Duration(days: index - _todayIndex));
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isToday(DateTime date) {
    return _isSameDay(date, _baseDate);
  }

  bool _hasWorkout(DateTime date, List<Workout> allWorkouts) {
    return allWorkouts.any((w) =>
        w.date.year == date.year &&
        w.date.month == date.month &&
        w.date.day == date.day);
  }

  bool _isFirstOfMonth(int index) {
    return _dateAtIndex(index).day == 1;
  }

  void _scrollToDate(DateTime date) {
    final diff = date.difference(_baseDate).inDays;
    final index = _todayIndex + diff;
    if (index < 0 || index >= _totalDays) return;
    if (!_scrollController.hasClients) return;

    final viewportWidth = _scrollController.position.viewportDimension;
    final targetOffset =
        index * (_itemWidth + _itemSpacing) - (viewportWidth / 2) + (_itemWidth / 2);
    final clampedOffset = targetOffset.clamp(
      _scrollController.position.minScrollExtent,
      _scrollController.position.maxScrollExtent,
    );
    _scrollController.animateTo(
      clampedOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = widget.isDark;
    final selectedDate = ref.watch(selectedWorkoutDateProvider);
    final allWorkouts = ref.watch(workoutHistoryProvider).valueOrNull ?? [];

    return SizedBox(
      height: 80,
      child: ListView.separated(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: AppSpacing.screenPadding,
        itemCount: _totalDays,
        separatorBuilder: (_, index) {
          if (index + 1 < _totalDays && _isFirstOfMonth(index + 1)) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Center(
                child: Container(
                  width: 1,
                  height: 32,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : AppColors.dividerLight,
                ),
              ),
            );
          }
          return const SizedBox(width: AppSpacing.sm);
        },
        itemBuilder: (context, index) {
          final date = _dateAtIndex(index);
          final isSelected = _isSameDay(date, selectedDate);
          final isToday = _isToday(date);
          final hasWorkout = _hasWorkout(date, allWorkouts);
          final dayName = DateFormat('EEE').format(date);
          final dayNum = date.day.toString();
          final isFuture = date.isAfter(_baseDate.add(const Duration(days: 1)));

          return GestureDetector(
            onTap: isFuture
                ? null
                : () {
                    HapticFeedback.selectionClick();
                    ref.read(selectedWorkoutDateProvider.notifier).state = date;
                  },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              width: _itemWidth,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryBlue
                    : isDark
                        ? AppColors.surfaceDark1
                        : AppColors.surfaceLight1,
                borderRadius: AppSpacing.borderRadiusMd,
                border: isToday && !isSelected
                    ? Border.all(
                        color: AppColors.primaryBlue.withValues(alpha: 0.4),
                        width: 1.5,
                      )
                    : Border.all(
                        color: isSelected
                            ? Colors.transparent
                            : isDark
                                ? AppColors.dividerDark
                                : AppColors.dividerLight,
                      ),
              ),
              child: Opacity(
                opacity: isFuture ? 0.3 : 1.0,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      dayName.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.8)
                            : isDark
                                ? AppColors.textTertiaryDark
                                : AppColors.textTertiaryLight,
                        fontWeight: FontWeight.w500,
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      dayNum,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: isSelected
                            ? Colors.white
                            : theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    // Workout indicator dot
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: hasWorkout
                            ? (isSelected ? Colors.white : AppColors.primaryBlue)
                            : Colors.transparent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────── Mini Stat Card ───────────────────────────────

class _MiniStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;
  final bool isHighlighted;

  const _MiniStatCard({
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
        vertical: AppSpacing.md,
        horizontal: AppSpacing.sm,
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
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: isHighlighted ? color : null,
            ),
          ),
          const SizedBox(height: 2),
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

// ─────────────────────────── Summary Column ──────────────────────────────

class _SummaryColumn extends StatelessWidget {
  const _SummaryColumn({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
    required this.theme,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: isDark
                ? AppColors.textTertiaryDark
                : AppColors.textTertiaryLight,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────── Workout Diary Card ──────────────────────────

class _WorkoutDiaryCard extends StatelessWidget {
  final Workout workout;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _WorkoutDiaryCard({
    required this.workout,
    required this.isDark,
    required this.onTap,
    required this.onDelete,
  });

  String _formatTime(DateTime date) {
    return DateFormat('h:mm a').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muscles = workout.musclesHit.toList();

    return GestureDetector(
      onTap: onTap,
      child: Dismissible(
        key: Key(workout.id),
        direction: DismissDirection.endToStart,
        confirmDismiss: (_) async {
          onDelete();
          return false;
        },
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: AppSpacing.xl),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.1),
            borderRadius: AppSpacing.borderRadiusLg,
          ),
          child: Icon(Icons.delete_outlined, color: AppColors.error),
        ),
        child: Container(
          padding: AppSpacing.cardPadding,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: AppSpacing.borderRadiusLg,
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : AppColors.dividerLight,
            ),
            boxShadow:
                isDark ? AppColors.cardShadowDark : AppColors.cardShadowLight,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: name + time
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: const Icon(
                      Icons.fitness_center_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          workout.name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatTime(workout.date),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? AppColors.textTertiaryDark
                                : AppColors.textTertiaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textTertiaryLight,
                    size: 20,
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              // Stats row
              Row(
                children: [
                  _WorkoutStat(
                    icon: Icons.timer_outlined,
                    value: workout.formattedDuration,
                    isDark: isDark,
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  _WorkoutStat(
                    icon: Icons.repeat_rounded,
                    value:
                        '${workout.exercises.length} exercise${workout.exercises.length == 1 ? '' : 's'}',
                    isDark: isDark,
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  _WorkoutStat(
                    icon: Icons.bar_chart_rounded,
                    value: workout.totalVolume >= 1000
                        ? '${(workout.totalVolume / 1000).toStringAsFixed(1)}t'
                        : '${workout.totalVolume.round()}kg',
                    isDark: isDark,
                  ),
                ],
              ),

              // Muscle chips
              if (muscles.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.xs + 2,
                  runSpacing: AppSpacing.xs,
                  children: muscles.take(4).map((muscle) {
                    final color = AppColors.colorForMuscle(muscle);
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs - 1,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: isDark ? 0.15 : 0.08),
                        borderRadius: AppSpacing.borderRadiusPill,
                      ),
                      child: Text(
                        muscle.name[0].toUpperCase() +
                            muscle.name.substring(1),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────── Workout Stat ────────────────────────────────

class _WorkoutStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final bool isDark;

  const _WorkoutStat({
    required this.icon,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: isDark
              ? AppColors.textTertiaryDark
              : AppColors.textTertiaryLight,
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────── Empty Day State ─────────────────────────────

class _EmptyDayState extends StatelessWidget {
  final bool isDark;
  final DateTime selectedDate;
  final VoidCallback onStartWorkout;
  final VoidCallback onBrowsePlans;

  const _EmptyDayState({
    required this.isDark,
    required this.selectedDate,
    required this.onStartWorkout,
    required this.onBrowsePlans,
  });

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = _isToday(selectedDate);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xxxl,
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : AppColors.primaryBlue.withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(
              today ? Icons.fitness_center_rounded : Icons.event_busy_rounded,
              size: 32,
              color: AppColors.primaryBlue.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            today ? 'No workouts yet today' : 'Rest day',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            today
                ? 'Log a workout to track your progress'
                : 'No workouts were logged on this day',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark
                  ? AppColors.textTertiaryDark
                  : AppColors.textTertiaryLight,
            ),
          ),
          if (today) ...[
            const SizedBox(height: AppSpacing.xxl),
            DecoratedBox(
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
                    horizontal: AppSpacing.xxl,
                    vertical: AppSpacing.md,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusPill),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.play_arrow_rounded, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Log Workout',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
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
          boxShadow:
              isDark ? AppColors.cardShadowDark : AppColors.cardShadowLight,
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
