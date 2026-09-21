import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_assets.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/presentation/sign_out/confirm_and_sign_out.dart';
import '../../../premium/presentation/premium_plan_page.dart';

/// Mur EXPIRED minimal. Pas de CTA paiement dans cette itération.
class ExpiredSubscriptionPage extends ConsumerWidget {
  const ExpiredSubscriptionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          child: Column(
            children: [
              const Spacer(),
              Image.asset(AppAssets.logoFull, width: 180),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                'Abonnement expiré',
                textAlign: TextAlign.center,
                style: context.typography.headline,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Ton abonnement a expiré. Renouvelle-le pour retrouver '
                'l\'accès complet à Agapéo.',
                textAlign: TextAlign.center,
                style: context.typography.bodyMedium.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
              const Spacer(),
              AppButton(
                label: 'Voir les formules',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const PremiumPlanPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                label: 'Déconnexion',
                variant: AppButtonVariant.secondary,
                onPressed: () => confirmAndSignOut(context, ref),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
