import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/widgets.dart';

class ProfileHubError extends StatelessWidget {
  const ProfileHubError({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Impossible de charger le profil',
              textAlign: TextAlign.center,
              style: context.typography.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(label: 'Réessayer', onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}
