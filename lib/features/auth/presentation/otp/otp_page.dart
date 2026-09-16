import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  final _otpFocus = FocusNode();
  final _otpTextController = TextEditingController();
  Timer? _ticker;

  @override
  void dispose() {
    _ticker?.cancel();
    _otpFocus.dispose();
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
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => SessionStubPage(email: widget.email)),
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
    _syncTicker(until);

    return Scaffold(
      appBar: AppBar(title: const Text('Confirmation')),
      body: SafeArea(
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
              Semantics(
                label: 'Code de confirmation à 6 chiffres',
                textField: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GestureDetector(
                      onTap: () => _otpFocus.requestFocus(),
                      child: ExcludeSemantics(
                        child: _OtpBoxes(
                          value: state.otp,
                          hasError: state.fieldErrors['otp'] != null,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      controller: _otpTextController,
                      focusNode: _otpFocus,
                      autofocus: true,
                      hint: '000000',
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.oneTimeCode],
                      maxLength: 6,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      errorText: state.fieldErrors['otp'],
                      onChanged: controller.setOtp,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: 'Valider',
                onPressed: state.isLoading
                    ? null
                    : () => controller.submit(email: widget.email),
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
      ),
    );
  }
}

class _OtpBoxes extends StatelessWidget {
  const _OtpBoxes({required this.value, required this.hasError});

  final String value;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    return Row(
      children: List.generate(6, (index) {
        final filled = index < value.length;
        final isCurrent =
            index == value.length || (value.length == 6 && index == 5);
        final borderColor = hasError
            ? colors.error
            : (isCurrent ? colors.primary : colors.border);

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index == 5 ? 0 : AppSpacing.sm),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: AppRadius.mdRadius,
                  border: Border.all(color: borderColor, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    filled ? value[index] : '',
                    style: typography.headline.copyWith(color: colors.primary),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
