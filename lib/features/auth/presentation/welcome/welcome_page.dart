import 'package:flutter/material.dart';

import '../../../../core/config/app_assets.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../login/login_page.dart';
import '../registration/registration_page.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
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
                'Bienvenue',
                textAlign: TextAlign.center,
                style: context.typography.headline,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Des rencontres sincères pour bâtir un foyer chrétien.',
                textAlign: TextAlign.center,
                style: context.typography.bodyMedium.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
              const Spacer(),
              AppButton(
                label: 'Se connecter',
                onPressed: () {
                  Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => const LoginPage()));
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                label: 'Créer un compte',
                variant: AppButtonVariant.text,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RegistrationPage()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
