import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:alfanutrition/core/theme/app_colors.dart';
import 'package:alfanutrition/core/theme/app_spacing.dart';
import 'package:alfanutrition/features/nutrition/providers/nutrition_providers.dart';

/// Horizontal scrollable date picker showing 7 days centered on today.
class DateSelector extends ConsumerStatefulWidget {
  const DateSelector({super.key});

  @override
  ConsumerState<DateSelector> createState() => _DateSelectorState();
}

class _DateSelectorState extends ConsumerState<DateSelector> {
  late final ScrollController _scrollController;
  late final List<DateTime> _dates;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    _dates = List.generate(7, (i) => today.add(Duration(days: i - 3)));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return _isSameDay(date, DateTime(now.year, now.month, now.day));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final selectedDate = ref.watch(selectedDateProvider);

    return SizedBox(
      height: 76,
      child: ListView.separated(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: AppSpacing.screenPadding,
        itemCount: _dates.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final date = _dates[index];
          final isSelected = _isSameDay(date, selectedDate);
          final isToday = _isToday(date);
          final dayName = DateFormat('EEE').format(date);
          final dayNum = date.day.toString();

          return GestureDetector(
            onTap: () {
              ref.read(selectedDateProvider.notifier).state = date;
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              width: 50,
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dayName.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isSelected
                          ? theme.colorScheme.onPrimary.withValues(alpha: 0.8)
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
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (isToday) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? theme.colorScheme.onPrimary
                            : AppColors.primaryBlue,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ).animate().fadeIn(
                duration: 300.ms,
                delay: (50 * index).ms,
              );
        },
      ),
    );
  }
}
