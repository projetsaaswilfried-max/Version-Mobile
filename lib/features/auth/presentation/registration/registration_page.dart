import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_environment.dart';
import '../../../../core/config/legal_urls.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../onboarding/presentation/profile_onboarding/onboarding_flow_page.dart';
import '../login/login_page.dart';
import '../otp/otp_page.dart';
import '../widgets/google_auth_button.dart';
import '../widgets/legal_link_text.dart';
import 'registration_controller.dart';

/// Datify-inspired registration: strong headline, fields, Google, legal.
class RegistrationPage extends ConsumerStatefulWidget {
  const RegistrationPage({super.key});

  @override
  ConsumerState<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends ConsumerState<RegistrationPage> {
  bool _obscurePassword = true;
  bool _obscurePasswordConfirm = true;

  @override
  Widget build(BuildContext context) {
    ref.listen(registrationControllerProvider, (previous, next) {
      if (!next.succeeded || previous?.succeeded == true) return;
      final nextPage = AppEnvironment.current.hasSupabase
          ? OtpPage(email: next.email.trim(), password: next.password)
          : const OnboardingFlowPage();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => nextPage),
      );
    });

    final state = ref.watch(registrationControllerProvider);
    final controller = ref.read(registrationControllerProvider.notifier);
    final colors = context.colors;
    final typography = context.typography;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: colors.textPrimary,
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Créer un compte',
                      style: typography.headline.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 28,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Rejoins Agapeo pour des rencontres sincères.',
                      style: typography.bodyMedium.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    AppTextField(
                      label: 'Prénom',
                      textInputAction: TextInputAction.next,
                      errorText: state.fieldErrors['firstName'],
                      onChanged: controller.setFirstName,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      label: 'Nom (optionnel)',
                      textInputAction: TextInputAction.next,
                      onChanged: controller.setLastName,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      label: 'Email',
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      errorText: state.fieldErrors['email'],
                      onChanged: controller.setEmail,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      label: 'Mot de passe',
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.newPassword],
                      errorText: state.fieldErrors['password'],
                      onChanged: controller.setPassword,
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(
                            () => _obscurePassword = !_obscurePassword,
                          );
                        },
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      label: 'Confirmer le mot de passe',
                      obscureText: _obscurePasswordConfirm,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.newPassword],
                      errorText: state.fieldErrors['passwordConfirm'],
                      onChanged: controller.setPasswordConfirm,
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(
                            () => _obscurePasswordConfirm =
                                !_obscurePasswordConfirm,
                          );
                        },
                        icon: Icon(
                          _obscurePasswordConfirm
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _LegalCheckbox(
                      value: state.acceptedTerms && state.acceptedCharter,
                      errorText:
                          state.fieldErrors['acceptedTerms'] ??
                          state.fieldErrors['acceptedCharter'],
                      onChanged: controller.setAcceptedTerms,
                    ),
                    const SizedBox(height: AppSpacing.md),
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
                        style: typography.bodyMedium.copyWith(
                          color: colors.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xxl),
                    Row(
                      children: [
                        Expanded(child: Divider(color: colors.border)),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                          ),
                          child: Text(
                            'ou continuer avec',
                            style: typography.bodySmall.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: colors.border)),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Center(
                      child: const GoogleAuthButton(),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Déjà un compte ? ',
                          style: typography.bodyMedium.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const LoginPage(),
                              ),
                            );
                          },
                          child: Text(
                            'Se connecter',
                            style: typography.bodyMedium.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegalCheckbox extends StatelessWidget {
  const _LegalCheckbox({
    required this.value,
    required this.onChanged,
    this.errorText,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final linkStyle = typography.bodySmall.copyWith(
      color: colors.primary,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.underline,
      decorationColor: colors.primary,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
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
              child: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text.rich(
                  TextSpan(
                    style: typography.bodySmall.copyWith(
                      color: colors.textPrimary,
                    ),
                    children: [
                      const TextSpan(text: "J'accepte les "),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.baseline,
                        baseline: TextBaseline.alphabetic,
                        child: GestureDetector(
                          onTap: () => openLegalUrl(LegalUrls.cgv),
                          child: Text(
                            'conditions générales d\'utilisation',
                            style: linkStyle,
                          ),
                        ),
                      ),
                      const TextSpan(text: ' et la '),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.baseline,
                        baseline: TextBaseline.alphabetic,
                        child: GestureDetector(
                          onTap: () => openLegalUrl(LegalUrls.charter),
                          child: Text(
                            'charte d\'éthique',
                            style: linkStyle,
                          ),
                        ),
                      ),
                      const TextSpan(text: '.'),
                    ],
                  ),
                ),
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
