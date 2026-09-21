import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens for typography, mode-aware via [ThemeExtension].
///
/// Charte: Bricolage Grotesque everywhere (titles, body, fields).
class AppTypography extends ThemeExtension<AppTypography> {
  const AppTypography({
    required this.displayLarge,
    required this.displayMedium,
    required this.headline,
    required this.title,
    required this.bodyLarge,
    required this.bodyMedium,
    required this.bodySmall,
    required this.label,
  });

  final TextStyle displayLarge;
  final TextStyle displayMedium;
  final TextStyle headline;
  final TextStyle title;
  final TextStyle bodyLarge;
  final TextStyle bodyMedium;
  final TextStyle bodySmall;
  final TextStyle label;

  static TextStyle _face({
    required double size,
    required FontWeight weight,
    double height = 1.25,
  }) {
    return GoogleFonts.bricolageGrotesque(
      fontSize: size,
      fontWeight: weight,
      height: height,
    );
  }

  static AppTypography of({
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return AppTypography(
      displayLarge: _face(
        size: 32,
        weight: FontWeight.w700,
      ).copyWith(color: textPrimary),
      displayMedium: _face(
        size: 26,
        weight: FontWeight.w700,
      ).copyWith(color: textPrimary),
      headline: _face(
        size: 22,
        weight: FontWeight.w600,
      ).copyWith(color: textPrimary),
      title: _face(
        size: 18,
        weight: FontWeight.w600,
      ).copyWith(color: textPrimary),
      bodyLarge: _face(
        size: 16,
        weight: FontWeight.w400,
        height: 1.4,
      ).copyWith(color: textPrimary),
      bodyMedium: _face(
        size: 14,
        weight: FontWeight.w400,
        height: 1.4,
      ).copyWith(color: textPrimary),
      bodySmall: _face(
        size: 12,
        weight: FontWeight.w400,
        height: 1.4,
      ).copyWith(color: textSecondary),
      label: _face(
        size: 13,
        weight: FontWeight.w600,
        height: 1.3,
      ).copyWith(color: textSecondary),
    );
  }

  @override
  AppTypography copyWith({
    TextStyle? displayLarge,
    TextStyle? displayMedium,
    TextStyle? headline,
    TextStyle? title,
    TextStyle? bodyLarge,
    TextStyle? bodyMedium,
    TextStyle? bodySmall,
    TextStyle? label,
  }) {
    return AppTypography(
      displayLarge: displayLarge ?? this.displayLarge,
      displayMedium: displayMedium ?? this.displayMedium,
      headline: headline ?? this.headline,
      title: title ?? this.title,
      bodyLarge: bodyLarge ?? this.bodyLarge,
      bodyMedium: bodyMedium ?? this.bodyMedium,
      bodySmall: bodySmall ?? this.bodySmall,
      label: label ?? this.label,
    );
  }

  @override
  AppTypography lerp(ThemeExtension<AppTypography>? other, double t) {
    if (other is! AppTypography) return this;
    return AppTypography(
      displayLarge: TextStyle.lerp(displayLarge, other.displayLarge, t)!,
      displayMedium: TextStyle.lerp(displayMedium, other.displayMedium, t)!,
      headline: TextStyle.lerp(headline, other.headline, t)!,
      title: TextStyle.lerp(title, other.title, t)!,
      bodyLarge: TextStyle.lerp(bodyLarge, other.bodyLarge, t)!,
      bodyMedium: TextStyle.lerp(bodyMedium, other.bodyMedium, t)!,
      bodySmall: TextStyle.lerp(bodySmall, other.bodySmall, t)!,
      label: TextStyle.lerp(label, other.label, t)!,
    );
  }
}
