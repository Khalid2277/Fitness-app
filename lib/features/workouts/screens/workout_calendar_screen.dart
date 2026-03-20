import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:alfanutrition/core/theme/app_colors.dart';
import 'package:alfanutrition/core/theme/app_spacing.dart';
import 'package:alfanutrition/features/workouts/providers/workout_providers.dart';
import 'package:alfanutrition/data/models/workout.dart';

// ─────────────────────── Local Providers ───────────────────────

final _selectedDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

final _displayedMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

// ─────────────────────── Screen ───────────────────────

class WorkoutCalendarScreen extends ConsumerStatefulWidget {
  const WorkoutCalendarScreen({super.key});

  @override
  ConsumerState<WorkoutCalendarScreen> createState() =>
      _WorkoutCalendarScreenState();
}

class _WorkoutCalendarScreenState extends ConsumerState<WorkoutCalendarScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final historyAsync = ref.watch(workoutHistoryProvider);
    final selectedDate = ref.watch(_selectedDateProvider);
    final displayedMonth = ref.watch(_displayedMonthProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Calendar'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: AppSpacing.screenPadding,
            child: Text(
              'Failed to load workouts',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ),
        ),
        data: (workouts) {
          // Build a lookup: date -> list of workouts
          final workoutsByDate = <DateTime, List<Workout>>{};
          for (final w in workouts) {
            if (!w.isCompleted) continue;
            final key = DateTime(w.date.year, w.date.month, w.date.day);
            workoutsByDate.putIfAbsent(key, () => []).add(w);
          }

          final selectedWorkouts = workoutsByDate[selectedDate] ?? [];

          // Weekly stats: workouts in the week containing the selected date
          final weekStart = selectedDate
              .subtract(Duration(days: selectedDate.weekday % 7));
          final weekEnd = weekStart.add(const Duration(days: 7));
          final weekWorkouts = workouts.where((w) {
            if (!w.isCompleted) return false;
            final d = DateTime(w.date.year, w.date.month, w.date.day);
            return !d.isBefore(weekStart) && d.isBefore(weekEnd);
          }).toList();

          return CustomScrollView(
            slivers: [
              // ────────── Month Header ──────────
              SliverToBoxAdapter(
                child: _MonthHeader(
                  displayedMonth: displayedMonth,
                  isDark: isDark,
                  onPrevious: () {
                    ref.read(_displayedMonthProvider.notifier).state =
                        DateTime(displayedMonth.year, displayedMonth.month - 1);
                  },
                  onNext: () {
                    ref.read(_displayedMonthProvider.notifier).state =
                        DateTime(displayedMonth.year, displayedMonth.month + 1);
                  },
                ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05),
              ),

              // ────────── Calendar Grid ──────────
              SliverToBoxAdapter(
                child: _CalendarGrid(
                  displayedMonth: displayedMonth,
                  selectedDate: selectedDate,
                  workoutDates: workoutsByDate.keys.toSet(),
                  isDark: isDark,
                  onDateSelected: (date) {
                    HapticFeedback.selectionClick();
                    ref.read(_selectedDateProvider.notifier).state = date;
                  },
                ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05),
              ),

              // ────────── Weekly Stats Bar ──────────
              SliverToBoxAdapter(
                child: _WeeklyStatsBar(
                  weekWorkouts: weekWorkouts,
                  isDark: isDark,
                ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05),
              ),

              // ────────── Selected Day Detail ──────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, 0,
                  ),
                  child: Text(
                    _formatSelectedDateHeading(selectedDate),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ).animate().fadeIn(duration: 400.ms),
              ),

              if (selectedWorkouts.isEmpty)
                SliverToBoxAdapter(
                  child: _EmptyDayState(isDark: isDark)
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: 0.05),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.xxxl,
                  ),
                  sliver: SliverList.separated(
                    itemCount: selectedWorkouts.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.md),
                    itemBuilder: (context, index) {
                      return _WorkoutDayCard(
                        workout: selectedWorkouts[index],
                        isDark: isDark,
                        onTap: () => context.push(
                          '/workout/${selectedWorkouts[index].id}',
                        ),
                      )
                          .animate()
                          .fadeIn(
                            duration: 400.ms,
                            delay: (index * 80).ms,
                          )
                          .slideY(begin: 0.05);
                    },
                  ),
                ),

              // Bottom safe area padding
              const SliverToBoxAdapter(
                child: SizedBox(height: AppSpacing.xxxxl),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatSelectedDateHeading(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (date == today) return 'Today';
    if (date == yesterday) return 'Yesterday';
    return DateFormat('EEEE, MMM d').format(date);
  }
}

// ─────────────────────── Month Header ───────────────────────

class _MonthHeader extends StatelessWidget {
  final DateTime displayedMonth;
  final bool isDark;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const _MonthHeader({
    required this.displayedMonth,
    required this.isDark,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final monthLabel = DateFormat('MMMM yyyy').format(displayedMonth);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.sm,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.surfaceDark1.withValues(alpha: 0.8)
              : AppColors.surfaceLight.withValues(alpha: 0.8),
          borderRadius: AppSpacing.borderRadiusLg,
          border: Border.all(
            color: isDark
                ? AppColors.dividerDark.withValues(alpha: 0.5)
                : AppColors.dividerLight.withValues(alpha: 0.5),
          ),
          boxShadow:
              isDark ? AppColors.cardShadowDark : AppColors.cardShadowLight,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _NavButton(
              icon: Icons.chevron_left_rounded,
              onTap: onPrevious,
              isDark: isDark,
            ),
            Text(
              monthLabel,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            _NavButton(
              icon: Icons.chevron_right_rounded,
              onTap: onNext,
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;

  const _NavButton({
    required this.icon,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Icon(
            icon,
            size: 28,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────── Calendar Grid ───────────────────────

class _CalendarGrid extends StatelessWidget {
  final DateTime displayedMonth;
  final DateTime selectedDate;
  final Set<DateTime> workoutDates;
  final bool isDark;
  final ValueChanged<DateTime> onDateSelected;

  const _CalendarGrid({
    required this.displayedMonth,
    required this.selectedDate,
    required this.workoutDates,
    required this.isDark,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // First day of the month and how many days
    final firstOfMonth =
        DateTime(displayedMonth.year, displayedMonth.month, 1);
    final daysInMonth =
        DateTime(displayedMonth.year, displayedMonth.month + 1, 0).day;

    // Weekday of the 1st (0 = Sun ... 6 = Sat)
    final startWeekday = firstOfMonth.weekday % 7; // Mon=1..Sun=7 -> 0..6

    // Days from previous month to show
    final prevMonth =
        DateTime(displayedMonth.year, displayedMonth.month, 0); // last day
    final prevMonthDays = prevMonth.day;

    const weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        children: [
          // Weekday labels
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              children: weekdays
                  .map(
                    (d) => Expanded(
                      child: Center(
                        child: Text(
                          d,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.textTertiaryDark
                                : AppColors.textTertiaryLight,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),

          // Day cells: 6 rows x 7 columns
          ...List.generate(6, (row) {
            return Row(
              children: List.generate(7, (col) {
                final cellIndex = row * 7 + col;
                final dayOffset = cellIndex - startWeekday;

                DateTime cellDate;
                bool isCurrentMonth;

                if (dayOffset < 0) {
                  // Previous month
                  cellDate = DateTime(
                    displayedMonth.year,
                    displayedMonth.month - 1,
                    prevMonthDays + dayOffset + 1,
                  );
                  isCurrentMonth = false;
                } else if (dayOffset >= daysInMonth) {
                  // Next month
                  cellDate = DateTime(
                    displayedMonth.year,
                    displayedMonth.month + 1,
                    dayOffset - daysInMonth + 1,
                  );
                  isCurrentMonth = false;
                } else {
                  cellDate = DateTime(
                    displayedMonth.year,
                    displayedMonth.month,
                    dayOffset + 1,
                  );
                  isCurrentMonth = true;
                }

                final normalizedCell =
                    DateTime(cellDate.year, cellDate.month, cellDate.day);
                final isSelected = normalizedCell == selectedDate;
                final isToday = normalizedCell == today;
                final hasWorkout = workoutDates.contains(normalizedCell);

                return Expanded(
                  child: _DayCell(
                    day: cellDate.day,
                    isCurrentMonth: isCurrentMonth,
                    isSelected: isSelected,
                    isToday: isToday,
                    hasWorkout: hasWorkout,
                    isDark: isDark,
                    onTap: () => onDateSelected(normalizedCell),
                  ),
                );
              }),
            );
          }),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final bool isCurrentMonth;
  final bool isSelected;
  final bool isToday;
  final bool hasWorkout;
  final bool isDark;
  final VoidCallback onTap;

  const _DayCell({
    required this.day,
    required this.isCurrentMonth,
    required this.isSelected,
    required this.isToday,
    required this.hasWorkout,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const cellSize = 40.0;

    Color textColor;
    if (isSelected) {
      textColor = Colors.white;
    } else if (!isCurrentMonth) {
      textColor =
          isDark ? AppColors.textDisabledDark : AppColors.textDisabledLight;
    } else {
      textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: cellSize + AppSpacing.sm,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: 200.ms,
              width: cellSize,
              height: cellSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.primaryBlue : Colors.transparent,
                border: isToday && !isSelected
                    ? Border.all(
                        color: AppColors.primaryBlue.withValues(alpha: 0.5),
                        width: 1.5,
                      )
                    : null,
              ),
              alignment: Alignment.center,
              child: Text(
                '$day',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight:
                      isToday || isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: textColor,
                  fontSize: 14,
                ),
              ),
            ),
            // Workout dot indicator
            SizedBox(
              height: AppSpacing.xs,
              child: hasWorkout && !isSelected
                  ? Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryBlue,
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────── Weekly Stats Bar ───────────────────────

class _WeeklyStatsBar extends StatelessWidget {
  final List<Workout> weekWorkouts;
  final bool isDark;

  const _WeeklyStatsBar({
    required this.weekWorkouts,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final totalWorkouts = weekWorkouts.length;
    final totalVolume = weekWorkouts.fold<double>(
      0,
      (sum, w) => sum + w.totalVolume,
    );
    final totalDuration = weekWorkouts.fold<int>(
      0,
      (sum, w) => sum + w.durationSeconds,
    );

    String formattedVolume;
    if (totalVolume >= 1000) {
      formattedVolume = '${(totalVolume / 1000).toStringAsFixed(1)}k';
    } else {
      formattedVolume = totalVolume.toStringAsFixed(0);
    }

    final hours = totalDuration ~/ 3600;
    final minutes = (totalDuration % 3600) ~/ 60;
    final formattedDuration =
        hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, 0,
      ),
      child: Container(
        padding: AppSpacing.cardPadding,
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.surfaceDark1
              : theme.colorScheme.surface,
          borderRadius: AppSpacing.borderRadiusLg,
          boxShadow:
              isDark ? AppColors.cardShadowDark : AppColors.cardShadowLight,
        ),
        child: Row(
          children: [
            _WeekStat(
              icon: Icons.fitness_center_rounded,
              label: 'Workouts',
              value: '$totalWorkouts',
              color: AppColors.primaryBlue,
              isDark: isDark,
            ),
            _verticalDivider(isDark),
            _WeekStat(
              icon: Icons.local_fire_department_rounded,
              label: 'Volume',
              value: '${formattedVolume}kg',
              color: AppColors.warning,
              isDark: isDark,
            ),
            _verticalDivider(isDark),
            _WeekStat(
              icon: Icons.timer_rounded,
              label: 'Duration',
              value: formattedDuration,
              color: AppColors.accent,
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _verticalDivider(bool isDark) {
    return Container(
      width: 1,
      height: 36,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
    );
  }
}

class _WeekStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _WeekStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
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
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────── Empty Day State ───────────────────────

class _EmptyDayState extends StatelessWidget {
  final bool isDark;

  const _EmptyDayState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl, AppSpacing.xxl, AppSpacing.xl, AppSpacing.xxxl,
      ),
      child: Column(
        children: [
          Icon(
            Icons.event_busy_rounded,
            size: 48,
            color: isDark
                ? AppColors.textTertiaryDark
                : AppColors.textTertiaryLight,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No workouts logged',
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Hit the gym and log your session!',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark
                  ? AppColors.textTertiaryDark
                  : AppColors.textTertiaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: AppSpacing.borderRadiusPill,
            ),
            child: ElevatedButton(
              onPressed: () => context.push('/active-workout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xxl,
                  vertical: AppSpacing.md,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: AppSpacing.borderRadiusPill,
                ),
              ),
              child: const Text(
                'Log a Workout',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────── Workout Day Card ───────────────────────

class _WorkoutDayCard extends StatelessWidget {
  final Workout workout;
  final bool isDark;
  final VoidCallback onTap;

  const _WorkoutDayCard({
    required this.workout,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final formattedVolume = workout.totalVolume >= 1000
        ? '${(workout.totalVolume / 1000).toStringAsFixed(1)}k kg'
        : '${workout.totalVolume.toStringAsFixed(0)} kg';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: AppSpacing.cardPadding,
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.surfaceDark1
              : theme.colorScheme.surface,
          borderRadius: AppSpacing.borderRadiusLg,
          border: Border.all(
            color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
          ),
          boxShadow:
              isDark ? AppColors.cardShadowDark : AppColors.cardShadowLight,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.12),
                    borderRadius: AppSpacing.borderRadiusMd,
                  ),
                  child: const Icon(
                    Icons.fitness_center_rounded,
                    size: 20,
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
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('h:mm a').format(workout.date),
                        style: theme.textTheme.labelSmall?.copyWith(
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
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // Stats row
            Row(
              children: [
                _CardStat(
                  icon: Icons.timer_outlined,
                  text: workout.formattedDuration,
                  isDark: isDark,
                ),
                const SizedBox(width: AppSpacing.lg),
                _CardStat(
                  icon: Icons.list_rounded,
                  text: '${workout.exercises.length} exercises',
                  isDark: isDark,
                ),
                const SizedBox(width: AppSpacing.lg),
                _CardStat(
                  icon: Icons.scale_rounded,
                  text: formattedVolume,
                  isDark: isDark,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CardStat extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isDark;

  const _CardStat({
    required this.icon,
    required this.text,
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
        const SizedBox(width: AppSpacing.xs),
        Text(
          text,
          style: theme.textTheme.labelSmall?.copyWith(
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
