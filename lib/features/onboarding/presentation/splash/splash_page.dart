import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_assets.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/di/auth_providers.dart';
import '../../../auth/presentation/session_stub/session_stub_page.dart';
import '../../../auth/presentation/welcome/welcome_page.dart';
import '../../di/onboarding_providers.dart';
import '../intro/intro_onboarding_page.dart';

/// First screen shown on launch. Routes to intro, welcome, or session stub.
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
    final next = await _resolveNextPage();
    await hold;
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => next),
    );
  }

  Future<Widget> _resolveNextPage() async {
    final auth = ref.read(authRepositoryProvider);
    final session = auth.currentSession;
    if (session != null) {
      return SessionStubPage(email: session.email);
    }
    final introSeen = await ref.read(introStoreProvider).isSeen();
    return introSeen ? const WelcomePage() : const IntroOnboardingPage();
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
