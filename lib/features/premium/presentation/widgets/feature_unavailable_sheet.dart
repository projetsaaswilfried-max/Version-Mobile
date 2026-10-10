import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';

/// Sheet neutre affiché à la place de [PremiumFeatureSheet]/
/// [DiscoverPremiumSheet] quand le Premium est désactivé côté iOS (kill
/// switch Remote Config, voir `PremiumRemoteConfig`) - volontairement sans
/// aucune mention de Premium/paiement/Apple.
class FeatureUnavailableSheet extends StatelessWidget {
  const FeatureUnavailableSheet({super.key, this.onDismiss});

  final VoidCallback? onDismiss;

  static Future<void> show(BuildContext context) {
    final colors = context.colors;
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.surface,
      barrierColor: colors.textPrimary.withValues(
        alpha: AppColors.scrimOpacity,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) {
        final maxHeight =
            MediaQuery.sizeOf(ctx).height * AppSpacing.sheetMaxHeightFactor;
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: FeatureUnavailableSheet(onDismiss: () => Navigator.of(ctx).pop()),
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
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          bottom > 0 ? bottom : AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Icon(
                Icons.info_outline,
                size: AppSpacing.xxxl,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Fonctionnalité non disponible',
              textAlign: TextAlign.center,
              style: typography.title,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Cette fonctionnalité n\'est pas disponible pour le moment.',
              textAlign: TextAlign.center,
              style: typography.bodyMedium.copyWith(
                color: colors.textSecondary,
                height: 1.35,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
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
