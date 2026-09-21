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
    required this.muted,
    required this.skeleton,
    required this.chipBackground,
    required this.border,
    required this.success,
    required this.warning,
    required this.error,
    required this.verified,
    required this.scrim,
    required this.onScrim,
  });

  final Color primary;
  final Color primaryLight;
  final Color secondary;
  final Color surface;
  final Color background;
  final Color textPrimary;
  final Color textSecondary;

  /// Soft neutral gray: inactive nav icons, image placeholders.
  final Color muted;

  /// Lighter neutral gray, dedicated to skeleton/loading blocks — `muted`
  /// reads too heavy once filled solid over a large card area.
  final Color skeleton;

  /// Neutral gray fill for unselected chips/tags — distinct token from
  /// [skeleton] even though the shade matches today (different intent).
  final Color chipBackground;
  final Color border;
  final Color success;
  final Color warning;
  final Color error;
  final Color verified;
  final Color scrim;
  final Color onScrim;

  static const double scrimOpacity = 0.45;

  static const light = AppColors(
    primary: Color(0xFFE83E75),
    primaryLight: Color(0xFFFE72B3),
    secondary: Color(0xFFFE72B3),
    surface: Color(0xFFFFFFFF),
    // Same as surface: white body + thin borders/shadows, no rose-gray wash.
    background: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF1A1420),
    textSecondary: Color(0xFF6B6570),
    // Simple app-like gray (not the darker textSecondary mauve).
    muted: Color(0xFFB0B0B0),
    skeleton: Color(0xFFE7E7E7),
    chipBackground: Color(0xFFEDEDED),
    border: Color(0xFFD8D0D4),
    success: Color(0xFF2E9E5B),
    warning: Color(0xFFE8A23E),
    error: Color(0xFFD92D2D),
    verified: Color(0xFFE83E75),
    scrim: Color(0xFF1A1420),
    onScrim: Color(0xFFFFFFFF),
  );

  static const dark = AppColors(
    primary: Color(0xFFE83E75),
    primaryLight: Color(0xFFFE72B3),
    secondary: Color(0xFFFE72B3),
    surface: Color(0xFF221B22),
    background: Color(0xFF161115),
    textPrimary: Color(0xFFF5F1F3),
    textSecondary: Color(0xFFB4ACB2),
    muted: Color(0xFF7A7A7A),
    skeleton: Color(0xFF3D3A3C),
    chipBackground: Color(0xFF322C30),
    border: Color(0xFF362D35),
    success: Color(0xFF3FBE77),
    warning: Color(0xFFF2B25A),
    error: Color(0xFFEB5757),
    verified: Color(0xFFFE72B3),
    scrim: Color(0xFF1A1420),
    onScrim: Color(0xFFFFFFFF),
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
    Color? muted,
    Color? skeleton,
    Color? chipBackground,
    Color? border,
    Color? success,
    Color? warning,
    Color? error,
    Color? verified,
    Color? scrim,
    Color? onScrim,
  }) {
    return AppColors(
      primary: primary ?? this.primary,
      primaryLight: primaryLight ?? this.primaryLight,
      secondary: secondary ?? this.secondary,
      surface: surface ?? this.surface,
      background: background ?? this.background,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      muted: muted ?? this.muted,
      skeleton: skeleton ?? this.skeleton,
      chipBackground: chipBackground ?? this.chipBackground,
      border: border ?? this.border,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      verified: verified ?? this.verified,
      scrim: scrim ?? this.scrim,
      onScrim: onScrim ?? this.onScrim,
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
      muted: Color.lerp(muted, other.muted, t)!,
      skeleton: Color.lerp(skeleton, other.skeleton, t)!,
      chipBackground: Color.lerp(chipBackground, other.chipBackground, t)!,
      border: Color.lerp(border, other.border, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      verified: Color.lerp(verified, other.verified, t)!,
      scrim: Color.lerp(scrim, other.scrim, t)!,
      onScrim: Color.lerp(onScrim, other.onScrim, t)!,
    );
  }
}
