import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/di/providers.dart';
import '../../../core/error/result.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/presentation/widgets/legal_link_text.dart';
import '../../profile/di/profile_providers.dart';
import '../../profile/domain/entities/member_gate_snapshot.dart';
import '../../profile/domain/entities/subscription_status.dart';
import '../di/premium_checkout_providers.dart';
import '../domain/premium_plan.dart';

class PremiumPlanPage extends ConsumerStatefulWidget {
  const PremiumPlanPage({super.key});

  @override
  ConsumerState<PremiumPlanPage> createState() => _PremiumPlanPageState();
}

class _PremiumPlanPageState extends ConsumerState<PremiumPlanPage> {
  static const _benefits = [
    'Fiches complètes et likes illimités',
    'Filtres de recherche avancés (ville, dénomination...)',
    'Voir qui s\'intéresse à toi',
    'Invitations illimitées',
  ];

  String? _launchingCode;

  Future<void> _startCheckout(String planCode) async {
    setState(() => _launchingCode = planCode);
    final result = await ref
        .read(premiumCheckoutRepositoryProvider)
        .startCheckout(plan: planCode);
    if (!mounted) return;
    setState(() => _launchingCode = null);
    switch (result) {
      case Ok<Uri>(:final value):
        await launchUrl(value, mode: LaunchMode.externalApplication);
      case Err<Uri>(:final failure):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message)),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    // Garde-fou défensif : couvre tout point d'entrée qui pousserait
    // directement cette page (ex. "Mon Plan" dans le hub profil,
    // notification PAYMENT_FAILED) sans passer par un sheet déjà filtré
    // (PremiumFeatureSheet/DiscoverPremiumSheet) - voir PremiumRemoteConfig.
    if (!ref.watch(premiumPaymentsEnabledProvider)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mon Plan')),
        body: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.info_outline,
                size: AppSpacing.xxxl,
                color: colors.textSecondary,
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
            ],
          ),
        ),
      );
    }

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
            _PlanCard(
              plan: plan,
              isLoading: _launchingCode == plan.code,
              onTap: _launchingCode == null
                  ? () => _startCheckout(plan.code)
                  : null,
            ),
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
                    'Le paiement s\'effectue sur le site',
                    style: typography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Choisis une formule ci-dessus pour continuer dans le '
                    'navigateur - tu es reconnu automatiquement, pas besoin '
                    'de te reconnecter.',
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
  const _PlanCard({required this.plan, required this.isLoading, this.onTap});

  final PremiumPlan plan;
  final bool isLoading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    return Material(
      color: plan.recommended
          ? colors.primary.withValues(alpha: 0.06)
          : colors.surface,
      borderRadius: AppRadius.lgRadius,
      child: InkWell(
        borderRadius: AppRadius.lgRadius,
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: AppRadius.lgRadius,
            border: Border.all(
              color: plan.recommended ? colors.primary : colors.border,
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
                          Flexible(
                            child: Text(
                              plan.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: typography.bodyLarge.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
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
                if (isLoading)
                  SizedBox(
                    width: AppSpacing.lg,
                    height: AppSpacing.lg,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.primary,
                    ),
                  )
                else
                  Icon(
                    Icons.radio_button_off,
                    color: plan.recommended
                        ? colors.primary
                        : colors.textSecondary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
