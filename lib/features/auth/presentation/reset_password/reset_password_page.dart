import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/user_facing_message.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../profile/presentation/navigation/navigate_after_auth.dart';
import '../../di/auth_providers.dart';
import '../login/login_page.dart';
import 'reset_password_controller.dart';

/// A08 — set a new password after recovery deep link.
class ResetPasswordPage extends ConsumerStatefulWidget {
  const ResetPasswordPage({super.key, this.email = ''});

  final String email;

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  Widget build(BuildContext context) {
    ref.listen(resetPasswordControllerProvider, (previous, next) async {
      if (!next.succeeded || previous?.succeeded == true) return;
      final email = widget.email.isNotEmpty
          ? widget.email
          : (ref.read(authRepositoryProvider).currentSession?.email ?? '');
      await navigateAfterAuth(ref, context, email: email);
    });

    final state = ref.watch(resetPasswordControllerProvider);
    final controller = ref.read(resetPasswordControllerProvider.notifier);
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
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false,
                  );
                },
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
                      'Nouveau mot de passe',
                      style: typography.headline.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 28,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Choisis un mot de passe sécurisé pour ton compte.',
                      style: typography.bodyMedium.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxxl),
                    if (state.formError != null) ...[
                      Text(
                        userFacingMessageFromRaw(state.formError),
                        style: typography.bodyMedium.copyWith(
                          color: colors.error,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    AppTextField(
                      label: 'Mot de passe',
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.newPassword],
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
                    const SizedBox(height: AppSpacing.lg),
                    AppTextField(
                      label: 'Confirmer le mot de passe',
                      obscureText: _obscureConfirm,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.newPassword],
                      errorText: state.fieldErrors['passwordConfirm'],
                      onChanged: controller.setPasswordConfirm,
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() => _obscureConfirm = !_obscureConfirm);
                        },
                        icon: Icon(
                          _obscureConfirm
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxxl),
                    AppButton(
                      label: 'Enregistrer',
                      isLoading: state.isLoading,
                      onPressed: state.isLoading ? null : controller.submit,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                          (route) => false,
                        );
                      },
                      child: Text(
                        'Retour à la connexion',
                        style: typography.bodyMedium.copyWith(
                          color: colors.primary,
                        ),
                      ),
                    ),
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
