import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../utils/haptics.dart';

/// A premium card widget with optional gradient header, subtle shadow,
/// rounded corners, tap support, and a satisfying press animation.
///
/// ```dart
/// AppCard(
///   onTap: () {},
///   gradient: AppColors.primaryGradient,
///   child: Text('Hello'),
/// )
/// ```
class AppCard extends StatefulWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.gradient,
    this.headerGradient,
    this.headerChild,
    this.headerHeight,
    this.borderRadius,
    this.backgroundColor,
    this.border,
    this.elevation,
    this.shadowColor,
    this.enablePressAnimation = true,
    this.enableHaptic = true,
  });

  /// The card's main content.
  final Widget child;

  /// Called when the card is tapped.
  final VoidCallback? onTap;

  /// Padding around [child].  Defaults to [AppSpacing.cardPadding].
  final EdgeInsetsGeometry? padding;

  /// Outer margin.
  final EdgeInsetsGeometry? margin;

  /// If provided, the entire card background gets this gradient.
  final Gradient? gradient;

  /// If provided, a gradient header bar is rendered above [child].
  final Gradient? headerGradient;

  /// Widget rendered inside the gradient header (e.g. title text).
  final Widget? headerChild;

  /// Height of the gradient header.  Defaults to 48.
  final double? headerHeight;

  /// Border radius.  Defaults to [AppSpacing.radiusLg].
  final BorderRadiusGeometry? borderRadius;

  /// Explicit background color (ignored when [gradient] is set).
  final Color? backgroundColor;

  /// Optional border.
  final BoxBorder? border;

  /// Shadow elevation scale factor (0 = no shadow).
  final double? elevation;

  /// Custom shadow color.
  final Color? shadowColor;

  /// Whether to animate a subtle scale-down on press.
  final bool enablePressAnimation;

  /// Whether to trigger haptic feedback on tap.
  final bool enableHaptic;

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> with SingleTickerProviderStateMixin {
  late final AnimationController _pressController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (widget.onTap != null && widget.enablePressAnimation) {
      _pressController.forward();
    }
  }

  void _onTapUp(TapUpDetails _) {
    if (widget.onTap != null && widget.enablePressAnimation) {
      _pressController.reverse();
    }
  }

  void _onTapCancel() {
    if (widget.enablePressAnimation) {
      _pressController.reverse();
    }
  }

  void _onTap() {
    if (widget.enableHaptic) Haptics.light();
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final BorderRadiusGeometry radius =
        widget.borderRadius ?? AppSpacing.borderRadiusLg;
    final Color bg = widget.backgroundColor ??
        (isDark ? AppColors.surfaceDark : AppColors.surfaceLight);
    final List<BoxShadow> shadow = (widget.elevation == 0)
        ? []
        : isDark
            ? AppColors.cardShadowDark
            : AppColors.cardShadowLight;

    Widget card = Container(
      margin: widget.margin,
      decoration: BoxDecoration(
        gradient: widget.gradient,
        color: widget.gradient == null ? bg : null,
        borderRadius: radius,
        border: widget.border,
        boxShadow: shadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.headerGradient != null)
            Container(
              height: widget.headerHeight ?? 48,
              decoration: BoxDecoration(gradient: widget.headerGradient),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              alignment: Alignment.centerLeft,
              child: widget.headerChild,
            ),
          Padding(
            padding: widget.padding ?? AppSpacing.cardPadding,
            child: widget.child,
          ),
        ],
      ),
    );

    if (widget.onTap != null) {
      final bool animate =
          widget.enablePressAnimation && widget.onTap != null;

      card = GestureDetector(
        onTap: _onTap,
        onTapDown: animate ? _onTapDown : null,
        onTapUp: animate ? _onTapUp : null,
        onTapCancel: animate ? _onTapCancel : null,
        behavior: HitTestBehavior.opaque,
        child: animate
            ? ScaleTransition(scale: _scaleAnimation, child: card)
            : card,
      );
    }

    return card;
  }
}
