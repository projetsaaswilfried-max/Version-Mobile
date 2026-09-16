import 'package:flutter/material.dart';

import '../../../../core/config/app_assets.dart';
import '../../../../core/config/legal_urls.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../login/login_page.dart';
import '../registration/registration_page.dart';
import '../widgets/google_auth_button.dart';
import '../widgets/legal_link_text.dart';

/// Welcome (Sign up layout): full-bleed hero, bottom sheet with CTAs,
/// Google and legal links.
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
    final heroHeight = MediaQuery.of(context).size.height * 0.46;

    return Scaffold(
      backgroundColor: colors.surface,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: heroHeight,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  AppAssets.introSlide1,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, colors.surface],
                      stops: const [0.45, 1],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: heroHeight - AppSpacing.xxl,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppRadius.xl),
                  topRight: Radius.circular(AppRadius.xl),
                ),
                boxShadow: AppShadows.lg,
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.xl,
                    AppSpacing.xl,
                    AppSpacing.md,
                  ),
                  child: Column(
                    children: [
                      Image.asset(AppAssets.logoFull, width: 56),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Bienvenue',
                        textAlign: TextAlign.center,
                        style: typography.headline.copyWith(
                          fontWeight: FontWeight.w700,
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
                      const GoogleAuthButton(),
                      const SizedBox(height: AppSpacing.xxl),
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
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
