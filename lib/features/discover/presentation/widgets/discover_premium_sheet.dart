import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../premium/presentation/premium_plan_page.dart';
import 'discover_premium_plans.dart';

class DiscoverPremiumSheet extends StatelessWidget {
  const DiscoverPremiumSheet({super.key, this.onDismiss, this.onSelectPlan});

  final VoidCallback? onDismiss;
  final ValueChanged<DiscoverPremiumPlan>? onSelectPlan;

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
          child: DiscoverPremiumSheet(
            onDismiss: () => Navigator.of(ctx).pop(),
            onSelectPlan: (_) {
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
                    'Découvre tout Agapeo',
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
              'Sur Agapeo, un abonnement Premium te permet de consulter les '
              'profils en entier, démarrer des conversations, voir qui '
              "s'intéresse à toi et utiliser les filtres avancés. Sans lui, "
              'ton exploration reste très limitée.',
              style: typography.bodyMedium.copyWith(
                color: colors.textSecondary,
                height: 1.35,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            for (final plan in discoverPremiumPlans) ...[
              _PlanTile(plan: plan, onTap: () => onSelectPlan?.call(plan)),
              const SizedBox(height: AppSpacing.sm),
            ],
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: 'Quitter maintenant',
              variant: AppButtonVariant.secondary,
              onPressed: onDismiss,
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({required this.plan, required this.onTap});

  final DiscoverPremiumPlan plan;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    return Material(
      color: colors.surface,
      borderRadius: AppRadius.mdRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.mdRadius,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            borderRadius: AppRadius.mdRadius,
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Expanded(child: Text(plan.label, style: typography.bodyLarge)),
              Text(
                plan.priceLabel,
                style: typography.title.copyWith(color: colors.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
