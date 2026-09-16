import 'package:agapeo/core/error/failure.dart';
import 'package:agapeo/core/error/result.dart';
import 'package:agapeo/features/auth/domain/entities/auth_session.dart';
import 'package:agapeo/features/auth/domain/usecases/update_password.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/auth_test_fakes.dart';

void main() {
  test('rejects short password', () async {
    final repo = FakeAuthRepository();
    final result = await UpdatePassword(repo)(
      password: 'Ab1',
      passwordConfirm: 'Ab1',
    );
    expect(result, isA<Err>());
    final err = result as Err;
    expect(err.failure, isA<ValidationFailure>());
    expect(
      (err.failure as ValidationFailure).fieldErrors?['password'],
      isNotNull,
    );
  });

  test('rejects password mismatch on passwordConfirm', () async {
    final repo = FakeAuthRepository();
    final result = await UpdatePassword(repo)(
      password: 'Password1',
      passwordConfirm: 'Password2',
    );
    expect(result, isA<Err>());
    final err = result as Err;
    expect(
      (err.failure as ValidationFailure).fieldErrors?['passwordConfirm'],
      isNotNull,
    );
  });

  test('delegates to repository when valid', () async {
    final repo = FakeAuthRepository(
      updatePasswordResult: const Ok(AuthSession(id: '1', email: 'a@b.co')),
    );
    final result = await UpdatePassword(repo)(
      password: 'Password1',
      passwordConfirm: 'Password1',
    );
    expect(result, isA<Ok>());
    expect(repo.updatePasswordCalled, isTrue);
  });
}
