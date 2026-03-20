import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_spacing.dart';

/// Builds the [ThemeData] for both light and dark modes.
///
/// Usage:
/// ```dart
/// MaterialApp(
///   theme: AppTheme.light,
///   darkTheme: AppTheme.dark,
///   themeMode: ThemeMode.system,
/// )
/// ```
abstract final class AppTheme {
  // ─────────────────────────── Public API ────────────────────────────────

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  // ─────────────────────────── Builder ───────────────────────────────────

  static ThemeData _build(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;

    final Color background =
        isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final Color surface =
        isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final Color onSurface =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final Color onSurfaceVariant =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final Color divider =
        isDark ? AppColors.dividerDark : AppColors.dividerLight;

    final ColorScheme colorScheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.primaryBlue,
      onPrimary: Colors.white,
      primaryContainer:
          isDark ? AppColors.primaryDarkElevated : AppColors.primaryBlueSurface,
      onPrimaryContainer:
          isDark ? AppColors.primaryBlueLight : AppColors.primaryBlue,
      secondary: AppColors.accent,
      onSecondary: Colors.white,
      secondaryContainer:
          isDark ? AppColors.accentDark : AppColors.accentSurface,
      onSecondaryContainer:
          isDark ? AppColors.accentLight : AppColors.accentDark,
      tertiary: AppColors.primaryBlueLight,
      onTertiary: Colors.white,
      error: AppColors.error,
      onError: Colors.white,
      errorContainer:
          isDark ? AppColors.errorDark : AppColors.errorLight,
      onErrorContainer:
          isDark ? AppColors.error : AppColors.errorDark,
      surface: surface,
      onSurface: onSurface,
      onSurfaceVariant: onSurfaceVariant,
      outline: divider,
      outlineVariant:
          isDark ? AppColors.surfaceDark2 : AppColors.surfaceLight2,
      shadow: isDark ? Colors.black : const Color(0xFF1A1D2E),
      surfaceContainerHighest:
          isDark ? AppColors.surfaceDark3 : AppColors.surfaceLight3,
      surfaceContainerHigh:
          isDark ? AppColors.surfaceDark2 : AppColors.surfaceLight2,
      surfaceContainer:
          isDark ? AppColors.surfaceDark1 : AppColors.surfaceLight1,
      surfaceContainerLow:
          isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
    );

    // ──────────────────────── Typography ─────────────────────────────────

    const String fontFamily = '.SF Pro Display';
    const List<String> fallback = ['Roboto'];

    final TextTheme textTheme = TextTheme(
      displayLarge: TextStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: fallback,
        fontSize: 34,
        fontWeight: FontWeight.w700,
        height: 1.15,
        letterSpacing: -0.5,
        color: onSurface,
      ),
      displayMedium: TextStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: fallback,
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.5,
        color: onSurface,
      ),
      displaySmall: TextStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: fallback,
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.3,
        color: onSurface,
      ),
      headlineLarge: TextStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: fallback,
        fontSize: 22,
        fontWeight: FontWeight.w600,
        height: 1.25,
        letterSpacing: -0.3,
        color: onSurface,
      ),
      headlineMedium: TextStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: fallback,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.3,
        letterSpacing: -0.2,
        color: onSurface,
      ),
      headlineSmall: TextStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: fallback,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.3,
        letterSpacing: -0.1,
        color: onSurface,
      ),
      titleLarge: TextStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: fallback,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.35,
        letterSpacing: -0.1,
        color: onSurface,
      ),
      titleMedium: TextStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: fallback,
        fontSize: 15,
        fontWeight: FontWeight.w600,
        height: 1.35,
        color: onSurface,
      ),
      titleSmall: TextStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: fallback,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.35,
        color: onSurface,
      ),
      bodyLarge: TextStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: fallback,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: onSurface,
      ),
      bodyMedium: TextStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: fallback,
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: onSurface,
      ),
      bodySmall: TextStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: fallback,
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: onSurfaceVariant,
      ),
      labelLarge: TextStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: fallback,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.3,
        letterSpacing: 0.1,
        color: onSurface,
      ),
      labelMedium: TextStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: fallback,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.3,
        letterSpacing: 0.3,
        color: onSurfaceVariant,
      ),
      labelSmall: TextStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: fallback,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        height: 1.3,
        letterSpacing: 0.5,
        color: onSurfaceVariant,
      ),
    );

    // ──────────────────────── Component themes ──────────────────────────

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      textTheme: textTheme,
      fontFamily: fontFamily,

      // ---- App Bar ----
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontFamilyFallback: fallback,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          color: onSurface,
        ),
        iconTheme: IconThemeData(color: onSurface, size: 24),
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),

      // ---- Cards ----
      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusLg,
        ),
        margin: EdgeInsets.zero,
      ),

      // ---- Elevated Button ----
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          disabledBackgroundColor:
              isDark ? AppColors.surfaceDark2 : AppColors.surfaceLight3,
          disabledForegroundColor:
              isDark ? AppColors.textDisabledDark : AppColors.textDisabledLight,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusMd,
          ),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
          minimumSize: const Size(64, 52),
        ),
      ),

      // ---- Filled Button ----
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          disabledBackgroundColor:
              isDark ? AppColors.surfaceDark2 : AppColors.surfaceLight3,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusMd,
          ),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          minimumSize: const Size(64, 52),
        ),
      ),

      // ---- Outlined Button ----
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryBlue,
          side: BorderSide(color: divider),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusMd,
          ),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          minimumSize: const Size(64, 52),
        ),
      ),

      // ---- Text Button ----
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryBlue,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusSm,
          ),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ---- Input Decoration ----
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor:
            isDark ? AppColors.surfaceDark1 : AppColors.surfaceLight1,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: BorderSide(color: divider, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide:
              const BorderSide(color: AppColors.primaryBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        hintStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color:
              isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
        ),
        labelStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: onSurfaceVariant,
        ),
        errorStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.error,
        ),
      ),

      // ---- Bottom Navigation Bar ----
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: surface,
        selectedItemColor: AppColors.primaryBlue,
        unselectedItemColor: onSurfaceVariant,
        selectedLabelStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.2,
        ),
        elevation: 0,
        showUnselectedLabels: true,
      ),

      // ---- Navigation Bar (Material 3) ----
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.primaryBlueSurface,
        elevation: 0,
        height: 72,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              fontFamily: fontFamily,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
              color: AppColors.primaryBlue,
            );
          }
          return TextStyle(
            fontFamily: fontFamily,
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
            color: onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(
              color: AppColors.primaryBlue,
              size: 24,
            );
          }
          return IconThemeData(color: onSurfaceVariant, size: 24);
        }),
      ),

      // ---- Chip ----
      chipTheme: ChipThemeData(
        backgroundColor:
            isDark ? AppColors.surfaceDark1 : AppColors.surfaceLight1,
        selectedColor:
            isDark
                ? Color.alphaBlend(
                    AppColors.primaryBlue.withValues(alpha: 0.20),
                    AppColors.surfaceDark1,
                  )
                : AppColors.primaryBlueSurface,
        disabledColor:
            isDark ? AppColors.surfaceDark : AppColors.surfaceLight2,
        labelStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: onSurface,
        ),
        secondaryLabelStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryBlue,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusPill,
        ),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),

      // ---- Divider ----
      dividerTheme: DividerThemeData(
        color: divider,
        thickness: 1,
        space: 1,
      ),

      // ---- Bottom Sheet ----
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? AppColors.surfaceDark1 : surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusXxl),
          ),
        ),
        dragHandleColor: divider,
        dragHandleSize: const Size(36, 4),
      ),

      // ---- Dialog ----
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusXl,
        ),
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontFamilyFallback: fallback,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: onSurface,
        ),
      ),

      // ---- Snackbar ----
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? AppColors.surfaceDark3 : AppColors.textPrimaryLight,
        contentTextStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusMd,
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 4,
      ),

      // ---- Icon ----
      iconTheme: IconThemeData(color: onSurface, size: 24),

      // ---- Splash / highlight ----
      splashColor: AppColors.primaryBlue.withValues(alpha: 0.08),
      highlightColor: AppColors.primaryBlue.withValues(alpha: 0.04),
      splashFactory: InkSparkle.splashFactory,
    );
  }
}
