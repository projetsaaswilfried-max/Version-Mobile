import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';

class DiscoverVerifySheet extends StatelessWidget {
  const DiscoverVerifySheet({
    super.key,
    this.onDismiss,
    this.onVerify,
    this.isPending = false,
  });

  final VoidCallback? onDismiss;
  final VoidCallback? onVerify;

  /// Vérification déjà soumise, en attente de revue - il n'y a rien à faire
  /// de plus, renvoyer vers l'étape photo serait trompeur.
  final bool isPending;

  static Future<void> show(
    BuildContext context, {
    VoidCallback? onVerify,
    bool isPending = false,
  }) {
    final colors = context.colors;
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.surface,
      barrierColor: colors.textPrimary.withValues(alpha: 0.45),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) {
        return DiscoverVerifySheet(
          onDismiss: () => Navigator.of(ctx).pop(),
          onVerify: isPending
              ? null
              : () {
                  Navigator.of(ctx).pop();
                  onVerify?.call();
                },
          isPending: isPending,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          bottom > 0 ? bottom : AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    isPending ? 'Vérification en cours' : 'Valide ton profil',
                    style: typography.headline,
                  ),
                ),
                IconButton(
                  tooltip: 'Fermer',
                  onPressed: onDismiss,
                  icon: Icon(Icons.close, color: colors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              isPending
                  ? "Ton identité est en cours d'examen par notre équipe. "
                        'Reviens dès que c\'est validé pour aimer un profil.'
                  : "Pour aimer un profil, valide d'abord ton identité.",
              style: typography.bodyMedium.copyWith(
                color: colors.textSecondary,
                height: 1.35,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (!isPending) ...[
              AppButton(label: 'Vérifier mon profil', onPressed: onVerify),
              const SizedBox(height: AppSpacing.sm),
            ],
            AppButton(
              label: 'Fermer',
              variant: AppButtonVariant.secondary,
              onPressed: onDismiss,
            ),
          ],
        ),
      ),
    );
  }
}
