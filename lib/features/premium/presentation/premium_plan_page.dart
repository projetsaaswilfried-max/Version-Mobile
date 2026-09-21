import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/result.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/presentation/widgets/legal_link_text.dart';
import '../../profile/di/profile_providers.dart';
import '../../profile/domain/entities/member_gate_snapshot.dart';
import '../../profile/domain/entities/subscription_status.dart';
import '../domain/premium_plan.dart';

class PremiumPlanPage extends ConsumerWidget {
  const PremiumPlanPage({super.key});

  static const _benefits = [
    'Fiches complètes et likes illimités',
    'Filtres de recherche avancés (ville, dénomination...)',
    'Voir qui s\'intéresse à toi',
    'Invitations illimitées',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final typography = context.typography;
    final gate = ref.watch(memberGateProvider);
    final status = switch (gate) {
      AsyncData(:final value) => switch (value) {
        Ok<MemberGateSnapshot>(:final value) => value.subscriptionStatus,
        _ => SubscriptionStatus.free,
      },
      _ => SubscriptionStatus.free,
    };
    final (statusLabel, statusColor) = switch (status) {
      SubscriptionStatus.active => ('Premium actif', colors.success),
      SubscriptionStatus.expired => ('Expiré', colors.error),
      SubscriptionStatus.canceled => ('Annulé', colors.warning),
      SubscriptionStatus.free => ('Gratuit', colors.textSecondary),
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Mon Plan')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: AppRadius.pillRadius,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.workspace_premium,
                      size: AppSpacing.lg,
                      color: statusColor,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      statusLabel,
                      style: typography.bodyLarge.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Avantages Premium', style: typography.title),
          const SizedBox(height: AppSpacing.sm),
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: AppRadius.lgRadius,
              border: Border.all(color: colors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final benefit in _benefits)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: AppSpacing.md,
                            color: colors.primary,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(benefit, style: typography.bodyMedium),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Choisis ta formule', style: typography.title),
          const SizedBox(height: AppSpacing.sm),
          for (final plan in premiumCatalog) ...[
            _PlanCard(plan: plan),
            const SizedBox(height: AppSpacing.sm),
          ],
          const SizedBox(height: AppSpacing.md),
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.08),
              borderRadius: AppRadius.lgRadius,
              border: Border.all(color: colors.primary.withValues(alpha: 0.28)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Le paiement depuis l\'app arrive bientôt',
                    style: typography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'En attendant, tu peux souscrire directement sur le site.',
                    style: typography.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  InkWell(
                    onTap: () => openLegalUrl('https://agapeo.love'),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'agapeo.love',
                          style: typography.bodyLarge.copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Icon(
                          Icons.open_in_new,
                          size: AppSpacing.md,
                          color: colors.primary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan});

  final PremiumPlan plan;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: plan.recommended
            ? colors.primary.withValues(alpha: 0.06)
            : colors.surface,
        borderRadius: AppRadius.lgRadius,
        border: Border.all(
          color: plan.recommended
              ? colors.primary
              : colors.border,
          width: plan.recommended ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        plan.label,
                        style: typography.bodyLarge.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (plan.recommended) ...[
                        const SizedBox(width: AppSpacing.xs),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: colors.primary,
                            borderRadius: AppRadius.pillRadius,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: 2,
                            ),
                            child: Text(
                              'Recommandé',
                              style: typography.label.copyWith(
                                color: colors.onScrim,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    plan.priceLabel,
                    style: typography.bodyMedium.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.radio_button_off,
              color: plan.recommended ? colors.primary : colors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
