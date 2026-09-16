import 'package:flutter/material.dart';

import '../../../../core/config/app_assets.dart';
import '../../../../core/config/legal_urls.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../login/login_page.dart';
import '../registration/registration_page.dart';
import '../widgets/google_sign_in_button.dart';
import '../widgets/legal_link_text.dart';

/// Nestle-style welcome (Sign up layout): logo, CTAs, Google, legal.
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  void _openLogin(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const LoginPage()));
  }

  void _openRegistration(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const RegistrationPage()));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Image.asset(AppAssets.logoFull, width: 120),
              const SizedBox(height: AppSpacing.xxxl),
              Text(
                'Bienvenue',
                textAlign: TextAlign.center,
                style: typography.title.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Des rencontres sincères pour bâtir un foyer chrétien.',
                textAlign: TextAlign.center,
                style: typography.bodyMedium.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              AppButton(
                label: 'Créer un compte',
                onPressed: () => _openRegistration(context),
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: 'Se connecter',
                variant: AppButtonVariant.secondary,
                onPressed: () => _openLogin(context),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Row(
                children: [
                  Expanded(child: Divider(color: colors.border)),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    child: Text(
                      'ou continuer avec',
                      style: typography.bodySmall.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: colors.border)),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              GoogleSignInButton(onPressed: () => showGoogleComingSoon(context)),
              const Spacer(flex: 3),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => openLegalUrl(LegalUrls.cgv),
                    child: Text(
                      'CGU',
                      style: typography.bodySmall.copyWith(
                        color: colors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  TextButton(
                    onPressed: () => openLegalUrl(LegalUrls.privacy),
                    child: Text(
                      'Confidentialité',
                      style: typography.bodySmall.copyWith(
                        color: colors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}
