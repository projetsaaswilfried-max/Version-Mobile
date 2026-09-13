import 'package:flutter/material.dart';

/// Design tokens for color, mode-aware via [ThemeExtension].
///
/// Values sourced from the Agapeo graphic charter (docs/CHARTE-AGAPEO.pdf).
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.primary,
    required this.primaryLight,
    required this.secondary,
    required this.surface,
    required this.background,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
    required this.success,
    required this.warning,
    required this.error,
  });

  final Color primary;
  final Color primaryLight;
  final Color secondary;
  final Color surface;
  final Color background;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;
  final Color success;
  final Color warning;
  final Color error;

  static const light = AppColors(
    primary: Color(0xFFE83E75),
    primaryLight: Color(0xFFFE72B3),
    secondary: Color(0xFFFE72B3),
    surface: Color(0xFFFFFFFF),
    background: Color(0xFFFFFBFC),
    textPrimary: Color(0xFF1A1420),
    textSecondary: Color(0xFF6B6570),
    border: Color(0xFFECE6E9),
    success: Color(0xFF2E9E5B),
    warning: Color(0xFFE8A23E),
    error: Color(0xFFD92D2D),
  );

  static const dark = AppColors(
    primary: Color(0xFFE83E75),
    primaryLight: Color(0xFFFE72B3),
    secondary: Color(0xFFFE72B3),
    surface: Color(0xFF221B22),
    background: Color(0xFF161115),
    textPrimary: Color(0xFFF5F1F3),
    textSecondary: Color(0xFFB4ACB2),
    border: Color(0xFF362D35),
    success: Color(0xFF3FBE77),
    warning: Color(0xFFF2B25A),
    error: Color(0xFFEB5757),
  );

  @override
  AppColors copyWith({
    Color? primary,
    Color? primaryLight,
    Color? secondary,
    Color? surface,
    Color? background,
    Color? textPrimary,
    Color? textSecondary,
    Color? border,
    Color? success,
    Color? warning,
    Color? error,
  }) {
    return AppColors(
      primary: primary ?? this.primary,
      primaryLight: primaryLight ?? this.primaryLight,
      secondary: secondary ?? this.secondary,
      surface: surface ?? this.surface,
      background: background ?? this.background,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      border: border ?? this.border,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      primary: Color.lerp(primary, other.primary, t)!,
      primaryLight: Color.lerp(primaryLight, other.primaryLight, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      background: Color.lerp(background, other.background, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      border: Color.lerp(border, other.border, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
    );
  }
}
