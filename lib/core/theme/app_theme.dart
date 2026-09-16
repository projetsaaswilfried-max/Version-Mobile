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
    final brightness = colors == AppColors.dark ? Brightness.dark : Brightness.light;

    return ThemeData(
      brightness: brightness,
      useMaterial3: true,
      scaffoldBackgroundColor: colors.background,
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
        centerTitle: true,
        titleTextStyle: typography.title,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: Colors.white,
          textStyle: typography.bodyLarge.copyWith(fontWeight: FontWeight.w600),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdRadius),
          minimumSize: const Size.fromHeight(AppSpacing.buttonHeight),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.primary,
          side: BorderSide(color: colors.primary),
          textStyle: typography.bodyLarge.copyWith(fontWeight: FontWeight.w600),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdRadius),
          minimumSize: const Size.fromHeight(AppSpacing.buttonHeight),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surface,
        border: OutlineInputBorder(
          borderRadius: AppRadius.mdRadius,
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdRadius,
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdRadius,
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
      ),
      textTheme: TextTheme(
        displayLarge: typography.displayLarge,
        displayMedium: typography.displayMedium,
        headlineMedium: typography.headline,
        titleMedium: typography.title,
        bodyLarge: typography.bodyLarge,
        bodyMedium: typography.bodyMedium,
        bodySmall: typography.bodySmall,
        labelLarge: typography.label,
      ),
    );
  }
}
