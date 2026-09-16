import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_assets.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../di/auth_providers.dart';
import '../../../onboarding/presentation/profile_onboarding/onboarding_flow_page.dart';
import '../welcome/welcome_page.dart';

class SessionStubPage extends ConsumerWidget {
  const SessionStubPage({super.key, required this.email});

  final String email;

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    await ref.read(signOutProvider)();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomePage()),
      (route) => false,
    );
  }

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
                'Session',
                textAlign: TextAlign.center,
                style: context.typography.headline,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                email,
                textAlign: TextAlign.center,
                style: context.typography.bodyLarge,
              ),
              const Spacer(),
              AppButton(
                label: 'Continuer l\'onboarding',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const OnboardingFlowPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: 'Déconnexion',
                variant: AppButtonVariant.secondary,
                onPressed: () => _signOut(context, ref),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
