import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/app_button.dart';

class ThreadInviteBar extends StatelessWidget {
  const ThreadInviteBar({
    super.key,
    required this.onAccept,
    required this.onDecline,
  });

  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
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
      ),
    );
  }
}
