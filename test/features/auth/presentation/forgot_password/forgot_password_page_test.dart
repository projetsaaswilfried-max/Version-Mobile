import 'package:agapeo/core/error/result.dart';
import 'package:agapeo/core/theme/app_theme.dart';
import 'package:agapeo/core/widgets/app_text_field.dart';
import 'package:agapeo/features/auth/di/auth_providers.dart';
import 'package:agapeo/features/auth/presentation/forgot_password/forgot_password_controller.dart';
import 'package:agapeo/features/auth/presentation/forgot_password/forgot_password_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/auth_test_fakes.dart';

class _ResetAuthRepository extends FakeAuthRepository {
  @override
  Future<Result<void>> requestPasswordReset({required String email}) async =>
      const Ok(null);
}

void main() {
  testWidgets('shows email field, CTA and intro copy', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: const ForgotPasswordPage(),
        ),
      ),
    );

    expect(find.byType(AppTextField), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Envoyer'), findsOneWidget);
    expect(find.textContaining('Si un compte existe'), findsOneWidget);
    expect(find.text('Google'), findsNothing);
  });

  testWidgets('success shows generic message regardless of account', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_ResetAuthRepository()),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const ForgotPasswordPage(),
        ),
      ),
    );

    final container = ProviderScope.containerOf(
      tester.element(find.byType(ForgotPasswordPage)),
    );
    final controller = container.read(
      forgotPasswordControllerProvider.notifier,
    );
    controller.setEmail('a@b.co');
    await controller.submit();
    await tester.pumpAndSettle();

    expect(
      find.text(ForgotPasswordController.genericSuccessMessage),
      findsOneWidget,
    );
  });
}
