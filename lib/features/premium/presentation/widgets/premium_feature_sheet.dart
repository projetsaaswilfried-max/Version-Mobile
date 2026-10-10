import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../premium_plan_page.dart';
import 'feature_unavailable_sheet.dart';

/// Sheet Premium ciblé sur une seule fonctionnalité bloquée (recherche,
/// filtres, invitation, écrire dans une conversation acceptée...) —
/// distinct du sheet complet [DiscoverPremiumSheet] qui liste toutes les
/// offres et n'est réservé qu'à l'offre spontanée sur Découvrir.
class PremiumFeatureSheet extends StatelessWidget {
  const PremiumFeatureSheet({
    super.key,
    required this.title,
    required this.message,
    this.onDismiss,
    this.onSeePlans,
  });

  final String title;
  final String message;
  final VoidCallback? onDismiss;
  final VoidCallback? onSeePlans;

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    final enabled = ProviderScope.containerOf(
      context,
      listen: false,
    ).read(premiumPaymentsEnabledProvider);
    if (!enabled) return FeatureUnavailableSheet.show(context);

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
          child: PremiumFeatureSheet(
            title: title,
            message: message,
            onDismiss: () => Navigator.of(ctx).pop(),
            onSeePlans: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const PremiumPlanPage(),
                ),
              );
            },
          ),
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
                Icons.workspace_premium_outlined,
                size: AppSpacing.xxxl,
                color: colors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: typography.title,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              textAlign: TextAlign.center,
              style: typography.bodyMedium.copyWith(
                color: colors.textSecondary,
                height: 1.35,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(label: 'Voir les offres Premium', onPressed: onSeePlans),
            const SizedBox(height: AppSpacing.xs),
            AppButton(
              label: 'Plus tard',
              variant: AppButtonVariant.text,
              onPressed: onDismiss,
            ),
          ],
        ),
      ),
    );
  }
}
