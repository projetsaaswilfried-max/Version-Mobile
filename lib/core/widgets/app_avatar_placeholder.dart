import 'package:flutter/material.dart';

import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';

/// Placeholder photo/avatar when no image is available - monogram on a soft
/// brand gradient (replaces Material `person_outline` on gray).
class AppAvatarPlaceholder extends StatelessWidget {
  const AppAvatarPlaceholder({
    super.key,
    this.name,
    this.borderRadius,
    this.circle = false,
    this.iconSize,
  });

  /// Used to derive initials (falls back to a heart mark).
  final String? name;
  final BorderRadius? borderRadius;
  final bool circle;
  final double? iconSize;

  static String initialsFor(String? name) {
    final parts = (name ?? '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) {
      final runes = parts.first.runes.toList();
      final take = runes.length >= 2 ? 2 : 1;
      return String.fromCharCodes(runes.take(take)).toUpperCase();
    }
    final a = String.fromCharCode(parts.first.runes.first);
    final b = String.fromCharCode(parts.last.runes.first);
    return ('$a$b').toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final initials = initialsFor(name);
    final radius = circle ? null : (borderRadius ?? AppRadius.xlRadius);

    return Semantics(
      label: name == null || name!.trim().isEmpty
          ? 'Photo manquante'
          : 'Photo manquante pour $name',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final side = constraints.biggest.shortestSide;
          final resolvedSide = side.isFinite && side > 0
              ? side
              : AppSpacing.xxxl * 2;
          final bgIcon = iconSize ?? (resolvedSide * 0.55).clamp(
            AppSpacing.lg,
            AppSpacing.xxxl * 1.5,
          );
          final fgIcon = bgIcon * 0.55;
          final fontSize = (resolvedSide * 0.36).clamp(12.0, 40.0);

          return DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: radius,
              shape: circle ? BoxShape.circle : BoxShape.rectangle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colors.primaryLight.withValues(alpha: 0.55),
                  colors.primary.withValues(alpha: 0.85),
                ],
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Center(
                  child: Icon(
                    Icons.favorite,
                    size: bgIcon,
                    color: colors.onScrim.withValues(alpha: 0.18),
                  ),
                ),
                Center(
                  child: initials.isEmpty
                      ? Icon(
                          Icons.favorite_border,
                          size: fgIcon,
                          color: colors.onScrim.withValues(alpha: 0.92),
                        )
                      : Text(
                          initials,
                          style: typography.displayMedium.copyWith(
                            color: colors.onScrim,
                            fontSize: fontSize,
                            fontWeight: FontWeight.w700,
                            height: 1,
                            letterSpacing: 1,
                          ),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
