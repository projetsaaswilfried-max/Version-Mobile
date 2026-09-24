import 'package:agapeo/core/error/result.dart';
import 'package:agapeo/features/auth/domain/entities/auth_session.dart';
import 'package:agapeo/features/auth/domain/usecases/sign_in_with_google.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/auth_test_fakes.dart';

void main() {
  test('delegates to repository', () async {
    final repo = FakeAuthRepository(
      signInWithGoogleResult: const Ok(
        AuthSession(id: '1', email: 'a@b.co'),
      ),
    );
    final result = await SignInWithGoogle(repo)();
    expect(result, isA<Ok>());
    expect(repo.signInWithGoogleCalled, isTrue);
  });
}
