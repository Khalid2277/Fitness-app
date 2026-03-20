import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:alfanutrition/core/theme/app_spacing.dart';

/// A bottom action button used in the home dashboard.
///
/// Two of these sit side-by-side as "LOG FOOD" and "NEW WORKOUT".
/// They have an icon, label, and a tinted outlined/filled style.
class QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final int animationIndex;
  final bool filled;

  const QuickActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.animationIndex = 0,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppSpacing.borderRadiusMd,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: filled
                  ? color.withValues(alpha: isDark ? 0.15 : 0.08)
                  : Colors.transparent,
              borderRadius: AppSpacing.borderRadiusMd,
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : color.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: isDark ? Colors.white : color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      )
          .animate()
          .fadeIn(
            duration: 400.ms,
            delay: Duration(milliseconds: 100 * animationIndex),
          )
          .slideY(
            begin: 0.1,
            end: 0,
            duration: 400.ms,
            delay: Duration(milliseconds: 100 * animationIndex),
            curve: Curves.easeOut,
          ),
    );
  }
}
