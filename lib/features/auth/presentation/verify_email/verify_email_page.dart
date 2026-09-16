import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_assets.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../session_stub/session_stub_page.dart';
import 'verify_email_controller.dart';

class VerifyEmailPage extends ConsumerStatefulWidget {
  const VerifyEmailPage({
    super.key,
    required this.email,
    required this.password,
  });

  final String email;
  final String password;

  @override
  ConsumerState<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends ConsumerState<VerifyEmailPage> {
  Timer? _ticker;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _syncTicker(DateTime? until) {
    final locked = until != null && DateTime.now().isBefore(until);
    if (locked && _ticker == null) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        final current = ref.read(verifyEmailControllerProvider).resendAllowedAt;
        if (current == null || !DateTime.now().isBefore(current)) {
          _ticker?.cancel();
          _ticker = null;
        }
        setState(() {});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(verifyEmailControllerProvider, (previous, next) {
      if (!next.succeeded || previous?.succeeded == true) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => SessionStubPage(email: widget.email)),
        (route) => false,
      );
    });

    final state = ref.watch(verifyEmailControllerProvider);
    final controller = ref.read(verifyEmailControllerProvider.notifier);
    final colors = context.colors;
    final typography = context.typography;
    final until = state.resendAllowedAt;
    final remaining = until == null
        ? 0
        : until.difference(DateTime.now()).inSeconds;
    final resendLocked = remaining > 0;
    _syncTicker(until);

    return Scaffold(
      appBar: AppBar(title: const Text('Vérifie tes mails')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: Image.asset(AppAssets.logoFull, width: 180)),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Vérifie tes mails',
                style: typography.headline,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Ouvre le lien envoyé, puis reviens ici.',
                style: typography.bodyMedium.copyWith(
                  color: colors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                widget.email,
                style: typography.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              AppButton(
                label: "J'ai confirmé",
                onPressed: state.isLoading
                    ? null
                    : () => controller.confirm(
                        email: widget.email,
                        password: widget.password,
                      ),
                isLoading: state.isLoading,
              ),
              if (state.formError != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  state.formError!,
                  textAlign: TextAlign.center,
                  style: typography.bodyMedium.copyWith(color: colors.error),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: resendLocked ? 'Renvoyer (${remaining}s)' : 'Renvoyer',
                variant: AppButtonVariant.secondary,
                onPressed: resendLocked || state.isResending
                    ? null
                    : () => controller.resend(email: widget.email),
                isLoading: state.isResending,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
