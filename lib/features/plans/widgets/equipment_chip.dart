import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:alfanutrition/core/theme/app_colors.dart';
import 'package:alfanutrition/core/theme/app_spacing.dart';
import 'package:alfanutrition/data/models/enums.dart';

class EquipmentChip extends StatelessWidget {
  const EquipmentChip({
    super.key,
    required this.equipment,
    required this.isSelected,
    required this.onTap,
    this.delay = Duration.zero,
  });

  final EquipmentType equipment;
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
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                  ? AppColors.primaryBlue.withValues(alpha: 0.2)
                  : AppColors.primaryBlueSurface)
              : (isDark ? AppColors.surfaceDark1 : AppColors.surfaceLight1),
          borderRadius: AppSpacing.borderRadiusPill,
          border: Border.all(
            color: isSelected
                ? AppColors.primaryBlue
                : (isDark ? AppColors.dividerDark : AppColors.dividerLight),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              equipment.icon,
              size: 18,
              color: isSelected
                  ? AppColors.primaryBlue
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              equipment.displayName,
              style: theme.textTheme.labelLarge?.copyWith(
                color: isSelected
                    ? AppColors.primaryBlue
                    : theme.colorScheme.onSurface,
                fontSize: 13,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.check_circle,
                size: 16,
                color: AppColors.primaryBlue,
              ),
            ],
          ],
        ),
      ),
    )
        .animate(delay: delay)
        .fadeIn(duration: 300.ms)
        .scale(begin: const Offset(0.95, 0.95), duration: 300.ms);
  }
}
