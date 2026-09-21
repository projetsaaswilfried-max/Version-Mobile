import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';

/// Rose verification check, Datify-style, reusable on cards and bylines.
class AppVerifiedBadge extends StatelessWidget {
  const AppVerifiedBadge({
    super.key,
    this.size = AppSpacing.lg,
    this.onScrim = false,
  });

  final double size;
  final bool onScrim;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      label: 'Vérifié',
      child: Icon(
        Icons.verified,
        size: size,
        color: onScrim ? colors.onScrim : colors.verified,
      ),
    );
  }
}
