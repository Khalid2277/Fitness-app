import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:alfanutrition/core/theme/app_colors.dart';
import 'package:alfanutrition/core/theme/app_spacing.dart';

class GoalCard extends StatelessWidget {
  const GoalCard({
    super.key,
    required this.icon,
    required this.name,
    required this.description,
    required this.isSelected,
    required this.onTap,
    this.delay = Duration.zero,
  });

  final IconData icon;
  final String name;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;
  final Duration delay;

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
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryBlue
                    : (isDark
                        ? AppColors.surfaceDark2
                        : AppColors.surfaceLight2),
                borderRadius: AppSpacing.borderRadiusMd,
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? Colors.white
                    : theme.colorScheme.onSurfaceVariant,
                size: 24,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: isSelected
                          ? AppColors.primaryBlue
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
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
      ),
    )
        .animate(delay: delay)
        .fadeIn(duration: 400.ms)
        .slideX(begin: 0.05, end: 0, duration: 400.ms);
  }
}
