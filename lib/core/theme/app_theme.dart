import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Access to design tokens from any [BuildContext]:
/// `context.colors.primary`, `context.typography.headline`.
extension AppThemeContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
  AppTypography get typography => Theme.of(this).extension<AppTypography>()!;
}

class AppTheme {
  const AppTheme._();

  static ThemeData get light => _build(AppColors.light);

  static ThemeData get dark => _build(AppColors.dark);

  static ThemeData _build(AppColors colors) {
    final typography = AppTypography.of(
      textPrimary: colors.textPrimary,
      textSecondary: colors.textSecondary,
    );
    final brightness = colors == AppColors.dark
        ? Brightness.dark
        : Brightness.light;

    return ThemeData(
      brightness: brightness,
      useMaterial3: true,
      scaffoldBackgroundColor: colors.background,
      fontFamily: typography.bodyLarge.fontFamily,
      colorScheme: ColorScheme.fromSeed(
        seedColor: colors.primary,
        brightness: brightness,
        primary: colors.primary,
        secondary: colors.secondary,
        surface: colors.surface,
        error: colors.error,
      ),
      extensions: [colors, typography],
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        // Material 3 tints the AppBar with a surface overlay under any
        // Scrollable body by default (even before it scrolls) — kills
        // the flat, on-brand look and creates a seam against the body.
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: typography.title,
        // Material 3 par défaut : actionsPadding = EdgeInsets.zero — sans ça,
        // les icônes d'action collent au bord de l'écran (seul le padding
        // interne de l'IconButton les sépare du bord).
        actionsPadding: const EdgeInsets.only(right: AppSpacing.md),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.surface,
          textStyle: typography.bodyLarge.copyWith(fontWeight: FontWeight.w600),
          shape: const StadiumBorder(),
          minimumSize: const Size.fromHeight(AppSpacing.buttonHeight),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.primary,
          side: BorderSide(color: colors.primary),
          textStyle: typography.bodyLarge.copyWith(fontWeight: FontWeight.w600),
          shape: const StadiumBorder(),
          minimumSize: const Size.fromHeight(AppSpacing.buttonHeight),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: colors.primary,
        inactiveTrackColor: colors.chipBackground,
        thumbColor: colors.primary,
        overlayColor: colors.primary.withValues(alpha: 0.16),
        rangeThumbShape: const RoundRangeSliderThumbShape(
          enabledThumbRadius: 10,
        ),
        trackHeight: 4,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md + AppSpacing.xs,
        ),
        hintStyle: typography.bodyMedium.copyWith(color: colors.textSecondary),
        errorStyle: typography.bodySmall.copyWith(color: colors.error),
        labelStyle: typography.label,
        prefixIconColor: colors.textSecondary,
        suffixIconColor: colors.textSecondary,
        border: OutlineInputBorder(
          borderRadius: AppRadius.mdRadius,
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdRadius,
          borderSide: BorderSide(color: colors.border),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdRadius,
          borderSide: BorderSide(color: colors.border.withValues(alpha: 0.6)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdRadius,
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdRadius,
          borderSide: BorderSide(color: colors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdRadius,
          borderSide: BorderSide(color: colors.error, width: 1.5),
        ),
      ),
      textTheme: TextTheme(
        displayLarge: typography.displayLarge,
        displayMedium: typography.displayMedium,
        displaySmall: typography.headline,
        headlineLarge: typography.headline,
        headlineMedium: typography.headline,
        headlineSmall: typography.title,
        titleLarge: typography.title,
        titleMedium: typography.title,
        titleSmall: typography.label,
        bodyLarge: typography.bodyLarge,
        bodyMedium: typography.bodyMedium,
        bodySmall: typography.bodySmall,
        labelLarge: typography.label,
        labelMedium: typography.label,
        labelSmall: typography.bodySmall,
      ),
    );
  }
}
