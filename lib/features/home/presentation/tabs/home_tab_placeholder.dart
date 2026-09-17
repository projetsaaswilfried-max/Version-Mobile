import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';

/// Centered placeholder for unfinished home tabs.
class HomeTabPlaceholder extends StatelessWidget {
  const HomeTabPlaceholder({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: context.typography.headline,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Bientôt',
              textAlign: TextAlign.center,
              style: context.typography.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
