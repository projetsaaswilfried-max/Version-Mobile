import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';

class MessagesExpiredGate extends StatelessWidget {
  const MessagesExpiredGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Abonnement expiré',
              textAlign: TextAlign.center,
              style: context.typography.headline,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Ton abonnement a expiré. Renouvelle-le pour retrouver '
              'tes conversations.',
              textAlign: TextAlign.center,
              style: context.typography.bodyMedium.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
