import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// A clean, minimal custom app bar for AlfaNutrition.
///
/// Supports an optional subtitle, trailing action buttons, and a
/// translucent blurred-background mode.
///
/// ```dart
/// AlfaNutritionAppBar(
///   title: 'Dashboard',
///   subtitle: 'Monday, March 18',
///   trailing: [IconButton(...)],
///   transparent: true,
/// )
/// ```
class AlfaNutritionAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AlfaNutritionAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.transparent = false,
    this.showBackButton = false,
    this.onBackPressed,
    this.centerTitle = false,
    this.titleWidget,
    this.bottomWidget,
    this.elevation = 0,
  });

  /// Primary title string.
  final String title;

  /// Optional subtitle displayed below the title.
  final String? subtitle;

  /// Override the leading widget.
  final Widget? leading;

  /// Action widgets on the trailing side.
  final List<Widget>? trailing;

  /// When true the bar renders with a blurred, semi-transparent background.
  final bool transparent;

  /// Shows a back-arrow as the leading widget.
  final bool showBackButton;

  /// Custom back-press handler (defaults to [Navigator.pop]).
  final VoidCallback? onBackPressed;

  /// Center the title (iOS-style).
  final bool centerTitle;

  /// Replace the text title with a completely custom widget.
  final Widget? titleWidget;

  /// Optional widget below the title row (e.g. a search field).
  final PreferredSizeWidget? bottomWidget;

  /// Shadow elevation.
  final double elevation;

  @override
  Size get preferredSize {
    double h = 56;
    if (subtitle != null) h += 20;
    if (bottomWidget != null) h += bottomWidget!.preferredSize.height;
    return Size.fromHeight(h);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bg = transparent
        ? (isDark
            ? AppColors.backgroundDark.withValues(alpha: 0.85)
            : AppColors.backgroundLight.withValues(alpha: 0.85))
        : (isDark ? AppColors.backgroundDark : AppColors.backgroundLight);

    Widget titleContent = titleWidget ??
        Column(
          crossAxisAlignment:
              centerTitle ? CrossAxisAlignment.center : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        );

    Widget bar = AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: centerTitle,
      toolbarHeight: preferredSize.height -
          (bottomWidget != null ? bottomWidget!.preferredSize.height : 0),
      leading: leading ??
          (showBackButton
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                  onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
                )
              : null),
      title: titleContent,
      actions: [
        if (trailing != null) ...trailing!,
        const SizedBox(width: AppSpacing.sm),
      ],
      bottom: bottomWidget,
      systemOverlayStyle: isDark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
    );

    if (transparent) {
      bar = ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            color: bg,
            child: bar,
          ),
        ),
      );
    } else {
      bar = Container(
        color: bg,
        child: bar,
      );
    }

    return bar;
  }
}
