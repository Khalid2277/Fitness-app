import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:alfanutrition/core/theme/app_colors.dart';
import 'package:alfanutrition/core/theme/app_spacing.dart';
import 'package:alfanutrition/data/models/enums.dart';

class SplitCard extends StatelessWidget {
  const SplitCard({
    super.key,
    required this.splitType,
    required this.isSelected,
    required this.onTap,
    this.delay = Duration.zero,
  });

  final SplitType splitType;
  final bool isSelected;
  final VoidCallback onTap;
  final Duration delay;

  String get _description {
    switch (splitType) {
      case SplitType.pushPullLegs:
        return 'Train pushing, pulling, and leg movements on separate days for balanced growth.';
      case SplitType.upperLower:
        return 'Alternate between upper body and lower body sessions for high frequency.';
      case SplitType.broSplit:
        return 'Dedicate each day to one muscle group for maximum volume per session.';
      case SplitType.fullBody:
        return 'Hit every major muscle group each session - great for beginners or busy schedules.';
      case SplitType.arnoldSplit:
        return 'Chest/Back, Shoulders/Arms, Legs - the classic Arnold Schwarzenegger split.';
      case SplitType.custom:
        return 'Build your own custom training split.';
    }
  }

  String get _dayLayout {
    switch (splitType) {
      case SplitType.pushPullLegs:
        return 'Push | Pull | Legs | Push | Pull | Legs | Rest';
      case SplitType.upperLower:
        return 'Upper | Lower | Rest | Upper | Lower | Rest | Rest';
      case SplitType.broSplit:
        return 'Chest | Back | Shoulders | Arms | Legs | Rest | Rest';
      case SplitType.fullBody:
        return 'Full | Rest | Full | Rest | Full | Rest | Rest';
      case SplitType.arnoldSplit:
        return 'Chest/Back | Shoulders/Arms | Legs | Repeat | Rest';
      case SplitType.custom:
        return 'Customize your own layout';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: AppSpacing.cardPadding,
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                  ? AppColors.primaryBlue.withValues(alpha: 0.15)
                  : AppColors.primaryBlueSurface)
              : (isDark ? AppColors.surfaceDark1 : AppColors.surfaceLight),
          borderRadius: AppSpacing.borderRadiusLg,
          border: Border.all(
            color: isSelected
                ? AppColors.primaryBlue
                : (isDark ? AppColors.dividerDark : AppColors.dividerLight),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryBlue.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : isDark
                  ? AppColors.cardShadowDark
                  : AppColors.cardShadowLight,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryBlue
                        : (isDark
                            ? AppColors.surfaceDark2
                            : AppColors.surfaceLight2),
                    borderRadius: AppSpacing.borderRadiusMd,
                  ),
                  child: Icon(
                    splitType.icon,
                    color: isSelected
                        ? Colors.white
                        : theme.colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    splitType.displayName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: isSelected
                          ? AppColors.primaryBlue
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryBlue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _description,
              style: theme.textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceDark2.withValues(alpha: 0.5)
                    : AppColors.surfaceLight2,
                borderRadius: AppSpacing.borderRadiusSm,
              ),
              child: Text(
                _dayLayout,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isSelected
                      ? AppColors.primaryBlue
                      : theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 0.3,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    )
        .animate(delay: delay)
        .fadeIn(duration: 400.ms)
        .slideX(begin: 0.05, end: 0, duration: 400.ms);
  }
}
