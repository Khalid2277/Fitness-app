import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:alfanutrition/core/theme/app_colors.dart';

class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/nutrition')) return 1;
    if (location.startsWith('/workouts')) return 2;
    if (location.startsWith('/progress')) return 3;
    if (location.startsWith('/ai-coach')) return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    HapticFeedback.selectionClick();

    // Dismiss any open modal bottom sheets / overlays before switching tabs
    Navigator.of(context, rootNavigator: false).popUntil((route) {
      return route.isFirst || route is! PopupRoute;
    });

    switch (index) {
      case 0:
        context.go('/home');
      case 1:
        context.go('/nutrition');
      case 2:
        context.go('/workouts');
      case 3:
        context.go('/progress');
      case 4:
        context.go('/ai-coach');
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: child,
      extendBody: true,
      bottomNavigationBar: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.backgroundDark.withValues(alpha: 0.85)
                  : AppColors.backgroundLight.withValues(alpha: 0.88),
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.06),
                  width: 0.5,
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.only(
                  left: 4,
                  right: 4,
                  top: 6,
                  bottom: bottomPadding > 0 ? 0 : 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _NavItem(
                      icon: Icons.home_rounded,
                      activeIcon: Icons.home_rounded,
                      label: 'Home',
                      isSelected: selectedIndex == 0,
                      onTap: () => _onItemTapped(0, context),
                    ),
                    _NavItem(
                      icon: Icons.restaurant_outlined,
                      activeIcon: Icons.restaurant_rounded,
                      label: 'Nutrition',
                      isSelected: selectedIndex == 1,
                      onTap: () => _onItemTapped(1, context),
                    ),
                    _NavItem(
                      icon: Icons.fitness_center_outlined,
                      activeIcon: Icons.fitness_center_rounded,
                      label: 'Workouts',
                      isSelected: selectedIndex == 2,
                      onTap: () => _onItemTapped(2, context),
                    ),
                    _NavItem(
                      icon: Icons.trending_up_outlined,
                      activeIcon: Icons.trending_up_rounded,
                      label: 'Progress',
                      isSelected: selectedIndex == 3,
                      onTap: () => _onItemTapped(3, context),
                    ),
                    _NavItem(
                      icon: Icons.smart_toy_outlined,
                      activeIcon: Icons.smart_toy_rounded,
                      label: 'AI Coach',
                      isSelected: selectedIndex == 4,
                      onTap: () => _onItemTapped(4, context),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedColor = AppColors.primaryBlue;
    final unselectedColor = theme.colorScheme.onSurface.withValues(alpha: 0.35);
    final color = isSelected ? selectedColor : unselectedColor;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isSelected ? activeIcon : icon,
                key: ValueKey(isSelected),
                size: 24,
                color: color,
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: color,
                letterSpacing: 0.1,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
