import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/legal_urls.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../forgot_password/forgot_password_page.dart';
import '../otp/otp_page.dart';
import '../registration/registration_page.dart';
import '../session_stub/session_stub_page.dart';
import '../widgets/google_auth_button.dart';
import '../widgets/legal_link_text.dart';
import 'login_controller.dart';

/// Datify-inspired login: strong headline, filled fields, social row.
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    ref.listen(loginControllerProvider, (previous, next) {
      if (next.succeeded && previous?.succeeded != true) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => SessionStubPage(email: next.email.trim()),
          ),
          (route) => false,
        );
        return;
      }
      if (next.emailNotConfirmed && previous?.emailNotConfirmed != true) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => OtpPage(email: next.email.trim())),
        );
      }
    });

    final state = ref.watch(loginControllerProvider);
    final controller = ref.read(loginControllerProvider.notifier);
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
                icon: Icon(Icons.arrow_back_ios_new_rounded, color: colors.textPrimary),
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
                      'Connexion',
                      style: typography.headline.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 28,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Heureux de te revoir sur Agapeo.',
                      style: typography.bodyMedium.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxxl),
                    AppTextField(
                      label: 'Email',
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      errorText: state.fieldErrors['email'],
                      onChanged: controller.setEmail,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppTextField(
                      label: 'Mot de passe',
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      errorText: state.fieldErrors['password'],
                      onChanged: controller.setPassword,
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ForgotPasswordPage(),
                            ),
                          );
                        },
                        child: Text(
                          'Mot de passe oublié ?',
                          style: typography.bodySmall.copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
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
                          'Pas encore de compte ? ',
                          style: typography.bodyMedium.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const RegistrationPage(),
                              ),
                            );
                          },
                          child: Text(
                            'Créer un compte',
                            style: typography.bodyMedium.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () => openLegalUrl(LegalUrls.cgv),
                          child: Text(
                            'CGU',
                            style: typography.bodySmall.copyWith(
                              color: colors.primary,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => openLegalUrl(LegalUrls.privacy),
                          child: Text(
                            'Confidentialité',
                            style: typography.bodySmall.copyWith(
                              color: colors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
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
