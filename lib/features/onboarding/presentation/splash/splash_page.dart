import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_assets.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/di/auth_providers.dart';
import '../../../auth/presentation/age_gate/age_gate_page.dart';
import '../../../auth/presentation/session_stub/session_stub_page.dart';
import '../../../auth/presentation/welcome/welcome_page.dart';

/// First screen shown on launch. Routes to age gate, welcome, or session stub.
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

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
    final auth = ref.read(authRepositoryProvider);
    final session = auth.currentSession;
    if (session != null) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => SessionStubPage(email: session.email),
        ),
      );
      return;
    }
    final accepted = await ref.read(ageGateStoreProvider).isAccepted();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => accepted ? const WelcomePage() : const AgeGatePage(),
      ),
    );
  }

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
            CircularProgressIndicator(color: context.colors.surface),
          ],
        ),
      ),
    );
  }
}
