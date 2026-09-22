import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../domain/invite/invite_list_preview.dart';

class ThreadInviteBar extends StatelessWidget {
  const ThreadInviteBar({
    super.key,
    required this.onAccept,
    required this.onDecline,
    this.peerName,
  });

  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final String? peerName;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              kIncomingInviteTitle,
              textAlign: TextAlign.center,
              style: typography.bodyLarge.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              incomingInviteHeadline(peerName),
              textAlign: TextAlign.center,
              style: typography.bodyMedium.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Refuser',
                    variant: AppButtonVariant.secondary,
                    onPressed: onDecline,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppButton(label: 'Accepter', onPressed: onAccept),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
