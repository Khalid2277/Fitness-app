import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// A beautiful centered empty-state placeholder with an icon, title,
/// subtitle, and an optional call-to-action button.
///
/// ```dart
/// EmptyState(
///   icon: Icons.fitness_center_rounded,
///   title: 'No Workouts Yet',
///   subtitle: 'Start your first workout to see it here.',
///   ctaLabel: 'Start Workout',
///   onCtaPressed: () {},
/// )
/// ```
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.ctaLabel,
    this.onCtaPressed,
    this.iconColor,
    this.iconSize = 56,
    this.compact = false,
  });

  /// Large decorative icon.
  final IconData icon;

  /// Primary message.
  final String title;

  /// Supporting description.
  final String? subtitle;

  /// Label for the action button (hidden when null).
  final String? ctaLabel;

  /// Callback for the action button.
  final VoidCallback? onCtaPressed;

  /// Override icon color.
  final Color? iconColor;

  /// Size of the icon.
  final double iconSize;

  /// Uses reduced spacing for inline empty states.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    final Color iconBg = (iconColor ?? AppColors.primaryBlue)
        .withValues(alpha: isDark ? 0.12 : 0.08);

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.xxxl,
          vertical: compact ? AppSpacing.xxl : AppSpacing.xxxxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: iconSize + 32,
              height: iconSize + 32,
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: iconSize,
                color: iconColor ??
                    (isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textTertiaryLight),
              ),
            ),
            SizedBox(height: compact ? AppSpacing.lg : AppSpacing.xxl),

            // Title
            Text(
              title,
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),

            // Subtitle
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                subtitle!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
                textAlign: TextAlign.center,
              ),
            ],

            // CTA button
            if (ctaLabel != null && onCtaPressed != null) ...[
              SizedBox(height: compact ? AppSpacing.lg : AppSpacing.xxl),
              DecoratedBox(
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
                child: ElevatedButton(
                  onPressed: onCtaPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xxl,
                      vertical: AppSpacing.md,
                    ),
                  ),
                  child: Text(ctaLabel!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
