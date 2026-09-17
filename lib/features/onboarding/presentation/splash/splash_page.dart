import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_assets.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/di/auth_providers.dart';
import '../../../auth/presentation/welcome/welcome_page.dart';
import '../../../profile/presentation/navigation/navigate_after_auth.dart';
import '../../di/onboarding_providers.dart';
import '../intro/intro_onboarding_page.dart';

/// First screen shown on launch. Routes to intro, welcome, or post-auth gate.
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  /// Minimum time the branded splash stays visible (perceived polish on iOS).
  static const minDisplayDuration = Duration(milliseconds: 1800);

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _route());
  }

  Future<void> _route() async {
    final hold = Future<void>.delayed(SplashPage.minDisplayDuration);
    final session = ref.read(authRepositoryProvider).currentSession;
    if (session != null) {
      await hold;
      if (!mounted) return;
      await navigateAfterAuth(ref, context, email: session.email);
      return;
    }

    final introSeen = await ref.read(introStoreProvider).isSeen();
    final next = introSeen ? const WelcomePage() : const IntroOnboardingPage();
    await hold;
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => next),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.primary,
      body: Center(
        child: Image.asset(AppAssets.logoFullWhite, width: 140),
      ),
    );
  }
}
