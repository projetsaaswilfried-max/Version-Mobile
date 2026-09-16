import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_assets.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../di/auth_providers.dart';
import '../welcome/welcome_page.dart';

class AgeGatePage extends ConsumerStatefulWidget {
  const AgeGatePage({super.key});

  @override
  ConsumerState<AgeGatePage> createState() => _AgeGatePageState();
}

class _AgeGatePageState extends ConsumerState<AgeGatePage> {
  static const _refuseMessage =
      'Agapéo est réservé aux personnes de 18 ans et plus.';

  bool _refused = false;
  bool _accepting = false;

  Future<void> _onAccept() async {
    setState(() {
      _accepting = true;
      _refused = false;
    });
    await ref.read(ageGateStoreProvider).accept();
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const WelcomePage()));
  }

  void _onRefuse() {
    setState(() => _refused = true);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

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
                'Agapéo est réservé aux adultes',
                textAlign: TextAlign.center,
                style: typography.headline,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Tu dois avoir 18 ans ou plus pour créer un compte et utiliser l\'application.',
                textAlign: TextAlign.center,
                style: typography.bodyMedium.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const Spacer(),
              AppButton(
                label: "J'ai 18 ans ou plus",
                onPressed: _accepting ? null : _onAccept,
                isLoading: _accepting,
              ),
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                label: "Je n'ai pas 18 ans",
                variant: AppButtonVariant.text,
                onPressed: _accepting ? null : _onRefuse,
              ),
              if (_refused) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _refuseMessage,
                  textAlign: TextAlign.center,
                  style: typography.bodyMedium.copyWith(color: colors.error),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
