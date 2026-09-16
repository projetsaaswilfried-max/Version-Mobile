import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/legal_urls.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../otp/otp_page.dart';
import '../widgets/legal_link_text.dart';
import 'registration_controller.dart';

class RegistrationPage extends ConsumerWidget {
  const RegistrationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(registrationControllerProvider, (previous, next) {
      if (!next.succeeded || previous?.succeeded == true) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) =>
              OtpPage(email: next.email.trim(), password: next.password),
        ),
      );
    });

    final state = ref.watch(registrationControllerProvider);
    final controller = ref.read(registrationControllerProvider.notifier);
    final colors = context.colors;
    final typography = context.typography;

    return Scaffold(
      appBar: AppBar(title: const Text('Inscription')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                label: 'Prénom',
                errorText: state.fieldErrors['firstName'],
                onChanged: controller.setFirstName,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: 'Nom (optionnel)',
                onChanged: controller.setLastName,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: 'Email',
                hint: 'toi@email.com',
                keyboardType: TextInputType.emailAddress,
                errorText: state.fieldErrors['email'],
                onChanged: controller.setEmail,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: 'Mot de passe',
                obscureText: true,
                errorText: state.fieldErrors['password'],
                onChanged: controller.setPassword,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: 'Confirmer le mot de passe',
                obscureText: true,
                errorText: state.fieldErrors['passwordConfirm'],
                onChanged: controller.setPasswordConfirm,
              ),
              const SizedBox(height: AppSpacing.lg),
              _LegalCheckbox(
                value: state.acceptedTerms,
                errorText: state.fieldErrors['acceptedTerms'],
                onChanged: controller.setAcceptedTerms,
                prefix: "J'accepte les ",
                linkLabel: 'CGU',
                onLinkPressed: () => openLegalUrl(LegalUrls.cgv),
              ),
              const SizedBox(height: AppSpacing.sm),
              _LegalCheckbox(
                value: state.acceptedCharter,
                errorText: state.fieldErrors['acceptedCharter'],
                onChanged: controller.setAcceptedCharter,
                prefix: "J'accepte la ",
                linkLabel: "Charte d'éthique",
                onLinkPressed: () => openLegalUrl(LegalUrls.charter),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: 'Créer un compte',
                onPressed: state.isLoading ? null : controller.submit,
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
            ],
          ),
        ),
      ),
    );
  }
}

class _LegalCheckbox extends StatelessWidget {
  const _LegalCheckbox({
    required this.value,
    required this.onChanged,
    required this.prefix,
    required this.linkLabel,
    required this.onLinkPressed,
    this.errorText,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String prefix;
  final String linkLabel;
  final VoidCallback onLinkPressed;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: Checkbox(
                value: value,
                onChanged: (checked) => onChanged(checked ?? false),
              ),
            ),
            Expanded(
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(prefix, style: typography.bodyMedium),
                  AppButton(
                    label: linkLabel,
                    variant: AppButtonVariant.text,
                    onPressed: onLinkPressed,
                  ),
                ],
              ),
            ),
          ],
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 48),
            child: Text(
              errorText!,
              style: typography.bodySmall.copyWith(color: colors.error),
            ),
          ),
      ],
    );
  }
}
