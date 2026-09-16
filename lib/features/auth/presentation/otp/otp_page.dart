import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinput/pinput.dart';

import '../../../../core/config/app_assets.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../session_stub/session_stub_page.dart';
import '../verify_email/verify_email_page.dart';
import 'otp_controller.dart';

class OtpPage extends ConsumerStatefulWidget {
  const OtpPage({super.key, required this.email, required this.password});

  final String email;
  final String password;

  @override
  ConsumerState<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends ConsumerState<OtpPage> {
  final _otpTextController = TextEditingController();
  Timer? _ticker;

  @override
  void dispose() {
    _ticker?.cancel();
    _otpTextController.dispose();
    super.dispose();
  }

  void _syncTicker(DateTime? until) {
    final locked = until != null && DateTime.now().isBefore(until);
    if (locked && _ticker == null) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        final current = ref.read(otpControllerProvider).resendAllowedAt;
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
    ref.listen(otpControllerProvider, (previous, next) {
      if (!next.succeeded || previous?.succeeded == true) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => SessionStubPage(email: widget.email)),
        (route) => false,
      );
    });

    final state = ref.watch(otpControllerProvider);
    final controller = ref.read(otpControllerProvider.notifier);
    final colors = context.colors;
    final typography = context.typography;
    final until = state.resendAllowedAt;
    final remaining = until == null
        ? 0
        : until.difference(DateTime.now()).inSeconds;
    final resendLocked = remaining > 0;
    final hasError = state.fieldErrors['otp'] != null;
    _syncTicker(until);

    final defaultPinTheme = PinTheme(
      width: 48,
      height: 56,
      textStyle: typography.headline.copyWith(fontWeight: FontWeight.w700),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadius.mdRadius,
        border: Border.all(color: colors.border),
      ),
    );
    final focusedPinTheme = defaultPinTheme.copyDecorationWith(
      border: Border.all(color: colors.primary, width: 1.5),
    );
    final errorPinTheme = defaultPinTheme.copyDecorationWith(
      border: Border.all(color: colors.error, width: 1.5),
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: colors.surface,
        appBar: AppBar(title: const Text('Confirme ton compte')),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
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
                        'Saisis le code à 6 chiffres',
                        style: typography.headline,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Un code a été envoyé à',
                        style: typography.bodyMedium.copyWith(
                          color: colors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        widget.email,
                        style: typography.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      Center(
                        child: Pinput(
                          length: 6,
                          controller: _otpTextController,
                          autofocus: true,
                          defaultPinTheme: defaultPinTheme,
                          focusedPinTheme: focusedPinTheme,
                          submittedPinTheme: defaultPinTheme,
                          errorPinTheme: errorPinTheme,
                          forceErrorState: hasError,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          autofillHints: const [AutofillHints.oneTimeCode],
                          onChanged: controller.setOtp,
                          onCompleted: (_) => FocusScope.of(context).unfocus(),
                        ),
                      ),
                      if (hasError) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          state.fieldErrors['otp']!,
                          textAlign: TextAlign.center,
                          style: typography.bodySmall.copyWith(
                            color: colors.error,
                          ),
                        ),
                      ],
                      if (state.formError != null) ...[
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          state.formError!,
                          textAlign: TextAlign.center,
                          style: typography.bodyMedium.copyWith(
                            color: colors.error,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.md,
                  AppSpacing.xl,
                  AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppButton(
                      label: 'Valider',
                      onPressed: state.isLoading
                          ? null
                          : () => controller.submit(email: widget.email),
                      isLoading: state.isLoading,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppButton(
                      label: resendLocked
                          ? 'Renvoyer le code (${remaining}s)'
                          : 'Renvoyer le code',
                      variant: AppButtonVariant.secondary,
                      onPressed: resendLocked || state.isResending
                          ? null
                          : () => controller.resend(email: widget.email),
                      isLoading: state.isResending,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppButton(
                      label: "Tu n'as pas reçu de code ?",
                      variant: AppButtonVariant.text,
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => VerifyEmailPage(
                              email: widget.email,
                              password: widget.password,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
