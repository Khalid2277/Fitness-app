import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:alfanutrition/core/theme/app_colors.dart';
import 'package:alfanutrition/core/theme/app_spacing.dart';
import 'package:alfanutrition/features/nutrition/providers/nutrition_providers.dart';

/// Horizontal scrollable date picker with unlimited past history.
///
/// Shows 365 days into the past and 1 day into the future, scrolled to
/// today on first build. Users can scroll freely through all dates.
class DateSelector extends ConsumerStatefulWidget {
  const DateSelector({super.key});

  @override
  ConsumerState<DateSelector> createState() => _DateSelectorState();
}

class _DateSelectorState extends ConsumerState<DateSelector> {
  /// How many past days to show. Effectively unlimited history.
  static const int _pastDays = 365;

  /// How many future days to show (today + 1 tomorrow).
  static const int _futureDays = 1;

  static const int _totalDays = _pastDays + 1 + _futureDays; // +1 for today
  static const int _todayIndex = _pastDays;

  static const double _itemWidth = 52.0;
  static const double _itemSpacing = 10.0;
  static const double _todayDotSize = 6.0;

  late final ScrollController _scrollController;
  late final DateTime _baseDate; // today

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _baseDate = DateTime(now.year, now.month, now.day);

    // Calculate initial offset to center today in the viewport.
    // We approximate: center = todayIndex * (itemWidth + spacing) - viewportWidth/2 + itemWidth/2
    // Use a post-frame callback for accurate centering with real viewport width.
    _scrollController = ScrollController(
      initialScrollOffset: _todayIndex * (_itemWidth + _itemSpacing) -
          100, // rough center, refined below
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToDate(ref.read(selectedDateProvider));
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

  /// Whether a new month starts at this index (show month label).
  bool _isFirstOfMonth(int index) {
    final date = _dateAtIndex(index);
    return date.day == 1;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final selectedDate = ref.watch(selectedDateProvider);

    return SizedBox(
      height: 86,
      child: ListView.separated(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: AppSpacing.screenPadding,
        itemCount: _totalDays,
        separatorBuilder: (_, index) {
          // Add month divider when crossing month boundaries
          if (index + 1 < _totalDays && _isFirstOfMonth(index + 1)) {
            final nextDate = _dateAtIndex(index + 1);
            final monthLabel = DateFormat('MMM').format(nextDate).toUpperCase();
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    monthLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiaryLight,
                      fontWeight: FontWeight.w700,
                      fontSize: 9,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Container(
                    width: 1,
                    height: 28,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          (isDark
                                  ? Colors.white
                                  : AppColors.textTertiaryLight)
                              .withValues(alpha: 0.0),
                          (isDark
                                  ? Colors.white
                                  : AppColors.textTertiaryLight)
                              .withValues(alpha: 0.15),
                          (isDark
                                  ? Colors.white
                                  : AppColors.textTertiaryLight)
                              .withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          return SizedBox(width: _itemSpacing);
        },
        itemBuilder: (context, index) {
          final date = _dateAtIndex(index);
          final isSelected = _isSameDay(date, selectedDate);
          final isToday = _isToday(date);
          final dayName = DateFormat('EEE').format(date);
          final dayNum = date.day.toString();
          final isFuture = date.isAfter(_baseDate.add(const Duration(days: 1)));

          return GestureDetector(
            onTap: isFuture
                ? null
                : () {
                    HapticFeedback.selectionClick();
                    ref.read(selectedDateProvider.notifier).state = date;
                  },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              width: _itemWidth,
              decoration: BoxDecoration(
                gradient: isSelected ? AppColors.primaryGradient : null,
                color: isSelected
                    ? null
                    : isDark
                        ? AppColors.surfaceDark1
                        : AppColors.surfaceLight1,
                borderRadius: AppSpacing.borderRadiusMd,
                border: isToday && !isSelected
                    ? Border.all(
                        color: AppColors.primaryBlue.withValues(alpha: 0.5),
                        width: 1.5,
                      )
                    : Border.all(
                        color: isSelected
                            ? Colors.transparent
                            : isDark
                                ? AppColors.dividerDark.withValues(alpha: 0.5)
                                : AppColors.dividerLight.withValues(alpha: 0.6),
                      ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primaryBlue.withValues(alpha: isDark ? 0.35 : 0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                          spreadRadius: -2,
                        ),
                      ]
                    : null,
              ),
              child: Opacity(
                opacity: isFuture ? 0.35 : 1.0,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      dayName.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.85)
                            : isDark
                                ? AppColors.textTertiaryDark
                                : AppColors.textTertiaryLight,
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      dayNum,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: isSelected
                            ? Colors.white
                            : isFuture
                                ? (isDark
                                    ? AppColors.textDisabledDark
                                    : AppColors.textDisabledLight)
                                : theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                        decoration: isFuture ? TextDecoration.lineThrough : null,
                        decorationColor: isDark
                            ? AppColors.textDisabledDark
                            : AppColors.textDisabledLight,
                        decorationStyle: TextDecorationStyle.solid,
                      ),
                    ),
                    if (isToday) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Container(
                        width: _todayDotSize,
                        height: _todayDotSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? Colors.white
                              : AppColors.primaryBlue,
                          boxShadow: [
                            BoxShadow(
                              color: (isSelected
                                      ? Colors.white
                                      : AppColors.primaryBlue)
                                  .withValues(alpha: 0.5),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ],
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
