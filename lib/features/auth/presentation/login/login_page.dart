import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/legal_urls.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../forgot_password/forgot_password_page.dart';
import '../registration/registration_page.dart';
import '../session_stub/session_stub_page.dart';
import '../widgets/legal_link_text.dart';
import 'login_controller.dart';

class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(loginControllerProvider, (previous, next) {
      if (!next.succeeded || previous?.succeeded == true) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => SessionStubPage(email: next.email.trim()),
        ),
        (route) => false,
      );
    });

    final state = ref.watch(loginControllerProvider);
    final controller = ref.read(loginControllerProvider.notifier);
    final colors = context.colors;
    final typography = context.typography;

    return Scaffold(
      appBar: AppBar(title: const Text('Connexion')),
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
              Align(
                alignment: Alignment.centerRight,
                child: AppButton(
                  label: 'Mot de passe oublié',
                  variant: AppButtonVariant.text,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ForgotPasswordPage(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: 'Se connecter',
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
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                label: 'Créer un compte',
                variant: AppButtonVariant.text,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RegistrationPage()),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: AppSpacing.sm,
                children: [
                  AppButton(
                    label: 'CGU',
                    variant: AppButtonVariant.text,
                    onPressed: () => openLegalUrl(LegalUrls.cgv),
                  ),
                  AppButton(
                    label: 'Confidentialité',
                    variant: AppButtonVariant.text,
                    onPressed: () => openLegalUrl(LegalUrls.privacy),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
