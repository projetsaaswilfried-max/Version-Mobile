import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens for typography, mode-aware via [ThemeExtension].
///
/// Charte: Bricolage Grotesque as primary (display/headline) typeface,
/// Segoe UI as secondary — kept as a fallback family since it is only
/// natively available on Windows; other platforms fall back to their
/// default system font.
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

  static const _bodyFallback = ['Segoe UI'];

  static TextStyle _display({required double size, required FontWeight weight}) {
    return GoogleFonts.bricolageGrotesque(fontSize: size, fontWeight: weight);
  }

  static const _bodyBase = TextStyle(
    fontFamilyFallback: _bodyFallback,
    height: 1.4,
  );

  static AppTypography of({required Color textPrimary, required Color textSecondary}) {
    return AppTypography(
      displayLarge: _display(size: 32, weight: FontWeight.w700).copyWith(color: textPrimary),
      displayMedium: _display(size: 26, weight: FontWeight.w700).copyWith(color: textPrimary),
      headline: _display(size: 22, weight: FontWeight.w600).copyWith(color: textPrimary),
      title: _display(size: 18, weight: FontWeight.w600).copyWith(color: textPrimary),
      bodyLarge: _bodyBase.copyWith(fontSize: 16, color: textPrimary),
      bodyMedium: _bodyBase.copyWith(fontSize: 14, color: textPrimary),
      bodySmall: _bodyBase.copyWith(fontSize: 12, color: textSecondary),
      label: _bodyBase.copyWith(fontSize: 13, fontWeight: FontWeight.w600, color: textSecondary),
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
