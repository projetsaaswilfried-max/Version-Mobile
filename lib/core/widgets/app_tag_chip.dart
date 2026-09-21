import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';

/// Read-only Datify interest chip (filled wash or outlined pill).
class AppTagChip extends StatelessWidget {
  const AppTagChip({
    super.key,
    required this.label,
    this.icon,
    this.outlined = false,
  });

  final String label;
  final IconData? icon;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: outlined
            ? colors.surface
            : colors.primary.withValues(alpha: 0.1),
        shape: StadiumBorder(
          side: outlined
              ? BorderSide(color: colors.border)
              : BorderSide.none,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: AppSpacing.lg,
                color: outlined ? colors.textSecondary : colors.primary,
              ),
              const SizedBox(width: AppSpacing.xs),
            ],
            Text(
              label,
              style: typography.bodyMedium.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppTagWrap extends StatelessWidget {
  const AppTagWrap({
    super.key,
    required this.labels,
    this.outlined = false,
  });

  final List<String> labels;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final label in labels)
          AppTagChip(label: label, outlined: outlined),
      ],
    );
  }
}
