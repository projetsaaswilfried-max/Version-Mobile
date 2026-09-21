import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../domain/match/match_banner_mode.dart';

class ThreadMatchBanner extends StatelessWidget {
  const ThreadMatchBanner({
    super.key,
    required this.mode,
    required this.onPropose,
    required this.onAccept,
    required this.onDecline,
    required this.onCancel,
  });

  final MatchBannerMode mode;
  final VoidCallback onPropose;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    if (mode == MatchBannerMode.hidden) return const SizedBox.shrink();

    final colors = context.colors;
    final typography = context.typography;

    return Material(
      color: colors.primaryLight.withValues(alpha: 0.2),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: switch (mode) {
          MatchBannerMode.propose => Row(
            children: [
              Expanded(
                child: Text(
                  'Prêt pour un engagement sérieux ?',
                  style: typography.bodyMedium,
                ),
              ),
              AppButton(
                label: 'Proposer un match',
                expanded: false,
                compact: true,
                onPressed: onPropose,
              ),
            ],
          ),
          MatchBannerMode.pendingOutgoing => Row(
            children: [
              Expanded(
                child: Text(
                  'En attente de réponse',
                  style: typography.bodyMedium,
                ),
              ),
              AppButton(
                label: 'Annuler',
                variant: AppButtonVariant.secondary,
                expanded: false,
                compact: true,
                onPressed: onCancel,
              ),
            ],
          ),
          MatchBannerMode.pendingIncoming => Row(
            children: [
              Expanded(
                child: Text(
                  'Proposition de match reçue',
                  style: typography.bodyMedium,
                ),
              ),
              AppButton(
                label: 'Refuser',
                variant: AppButtonVariant.secondary,
                expanded: false,
                compact: true,
                onPressed: onDecline,
              ),
              const SizedBox(width: AppSpacing.xs),
              AppButton(
                label: 'Accepter',
                expanded: false,
                compact: true,
                onPressed: onAccept,
              ),
            ],
          ),
          MatchBannerMode.accepted => Row(
            children: [
              Expanded(
                child: Text(
                  'Vous êtes en couple',
                  style: typography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              AppButton(
                label: 'Annuler',
                variant: AppButtonVariant.secondary,
                expanded: false,
                compact: true,
                onPressed: onCancel,
              ),
            ],
          ),
          MatchBannerMode.hidden => const SizedBox.shrink(),
        },
      ),
    );
  }
}
