import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:alfanutrition/core/theme/app_colors.dart';
import 'package:alfanutrition/core/theme/app_spacing.dart';
import 'package:alfanutrition/features/home/providers/home_providers.dart';

/// Weekly Activity card with streak badge and day-of-week training dots.
class WeeklyDots extends StatelessWidget {
  final WeeklyWorkoutSummary summary;

  const WeeklyDots({super.key, required this.summary});

  static const _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final todayIndex = DateTime.now().weekday - 1; // 0=Mon ... 6=Sun
    final copper = AppColors.warning;

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
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Weekly Activity',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              // Streak badge
              if (summary.streak > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: copper.withValues(alpha: 0.15),
                    borderRadius: AppSpacing.borderRadiusPill,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.local_fire_department_rounded,
                        size: 14,
                        color: copper,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'STREAK: ${summary.streak} DAYS',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: copper,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // Day dots row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (index) {
              final trained = summary.trainedDays[index];
              final isToday = index == todayIndex;
              final isPast = index < todayIndex;

              return _DayDot(
                label: _dayLabels[index],
                trained: trained,
                isToday: isToday,
                isPast: isPast,
                index: index,
              );
            }),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms, delay: 200.ms, curve: Curves.easeOut)
        .slideY(
            begin: 0.05,
            end: 0,
            duration: 600.ms,
            delay: 200.ms,
            curve: Curves.easeOut);
  }
}

class _DayDot extends StatelessWidget {
  final String label;
  final bool trained;
  final bool isToday;
  final bool isPast;
  final int index;

  const _DayDot({
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
        // Day label
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: isToday
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
            fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 8),
        // Dot
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 28,
          height: 28,
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
