import 'package:flutter/material.dart';

import '../../../../core/config/app_assets.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';

/// First screen shown on launch. Routing to auth/onboarding/home based on
/// session + `profiles.onboarding_completed` (PRD §4) lands here once the
/// auth feature exists.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(AppAssets.logoFullWhite, width: 140),
            const SizedBox(height: AppSpacing.lg),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
