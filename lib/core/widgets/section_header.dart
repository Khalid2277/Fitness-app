import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// A section header row with a title and an optional trailing "See All" button.
///
/// ```dart
/// SectionHeader(
///   title: 'Recent Workouts',
///   onSeeAll: () => Navigator.push(...),
/// )
/// ```
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.onSeeAll,
    this.seeAllLabel = 'See All',
    this.trailing,
    this.padding,
    this.titleStyle,
  });

  /// Section title text.
  final String title;

  /// Callback for the trailing action button.  When null the button is hidden.
  final VoidCallback? onSeeAll;

  /// Label for the trailing button.
  final String seeAllLabel;

  /// Completely replaces the "See All" button with a custom widget.
  final Widget? trailing;

  /// Outer padding.  Defaults to horizontal [AppSpacing.screenPadding].
  final EdgeInsetsGeometry? padding;

  /// Override the default title text style.
  final TextStyle? titleStyle;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: padding ?? AppSpacing.screenPadding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: titleStyle ?? theme.textTheme.headlineMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (trailing != null)
            trailing!
          else if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.xs,
                  horizontal: AppSpacing.xs,
                ),
                child: Text(
                  seeAllLabel,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
