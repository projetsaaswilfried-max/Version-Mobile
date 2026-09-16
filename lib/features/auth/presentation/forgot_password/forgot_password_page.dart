import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import 'forgot_password_controller.dart';

class ForgotPasswordPage extends ConsumerWidget {
  const ForgotPasswordPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(forgotPasswordControllerProvider);
    final controller = ref.read(forgotPasswordControllerProvider.notifier);
    final colors = context.colors;
    final typography = context.typography;

    return Scaffold(
      appBar: AppBar(title: const Text('Mot de passe oublié')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Indique ton adresse email. Si un compte existe, tu recevras un lien pour réinitialiser ton mot de passe.',
                style: typography.bodyMedium.copyWith(
                  color: colors.textSecondary,
                ),
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
              AppButton(
                label: 'Envoyer',
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
              if (state.successMessage != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  state.successMessage!,
                  textAlign: TextAlign.center,
                  style: typography.bodyMedium.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
