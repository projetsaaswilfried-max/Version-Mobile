import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/di/auth_providers.dart';
import '../../../auth/presentation/welcome/welcome_page.dart';
import '../../../onboarding/presentation/profile_onboarding/onboarding_flow_page.dart';

class ProfileTabPage extends ConsumerWidget {
  const ProfileTabPage({super.key});

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
    final email =
        ref.watch(authRepositoryProvider).currentSession?.email ?? '';

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
              Text(
                'Profil',
                textAlign: TextAlign.center,
                style: context.typography.headline,
              ),
              if (email.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  email,
                  textAlign: TextAlign.center,
                  style: context.typography.bodyLarge,
                ),
              ],
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
