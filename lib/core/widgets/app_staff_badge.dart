import 'package:flutter/material.dart';

import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';

/// Compact "Équipe" pill for staff identity.
class AppStaffBadge extends StatelessWidget {
  const AppStaffBadge({super.key, this.onScrim = false});

  final bool onScrim;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final fill = onScrim
        ? colors.onScrim.withValues(alpha: 0.18)
        : colors.primary.withValues(alpha: 0.12);
    final foreground = onScrim ? colors.onScrim : colors.primary;
    return Semantics(
      label: 'Équipe',
      container: true,
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: fill,
            borderRadius: AppRadius.pillRadius,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            child: Text(
              'Équipe',
              style: context.typography.label.copyWith(
                color: foreground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
