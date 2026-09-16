import 'package:agapeo/core/error/exceptions.dart';
import 'package:agapeo/core/error/failure.dart';
import 'package:agapeo/core/error/result.dart';
import 'package:agapeo/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:agapeo/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:agapeo/features/auth/domain/entities/auth_deep_link_result.dart';
import 'package:agapeo/features/auth/domain/entities/auth_session.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeSupabaseAuthDataSource implements AuthRemoteDataSource {
  Exception? toThrow;

  @override
  ({String id, String email})? get currentUser => null;

  @override
  Stream<({String id, String email})?> get onAuthStateChange =>
      const Stream.empty();

  Future<T> _orThrow<T>(T value) async {
    if (toThrow != null) throw toThrow!;
    return value;
  }

  @override
  Future<({String id, String email})> signInWithPassword({
    required String email,
    required String password,
  }) async {
    if (toThrow != null) throw toThrow!;
    return (id: 'u1', email: email);
  }

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required String firstName,
    String? lastName,
  }) => _orThrow(null);

  @override
  Future<({String id, String email})> verifyEmailOtp({
    required String email,
    required String token,
  }) async {
    if (toThrow != null) throw toThrow!;
    return (id: 'u1', email: email);
  }

  @override
  Future<void> resendSignupEmail({required String email}) => _orThrow(null);

  @override
  Future<void> requestPasswordReset({required String email}) => _orThrow(null);

  @override
  Future<void> signInWithGoogle() => _orThrow(null);

  @override
  Future<({String id, String email})> updatePassword({
    required String password,
  }) async {
    if (toThrow != null) throw toThrow!;
    return (id: 'u1', email: 'a@b.co');
  }

  @override
  Future<AuthDeepLinkResult> handleAuthDeepLink(Uri uri) async {
    if (toThrow != null) throw toThrow!;
    return const AuthDeepLinkIgnored();
  }

  @override
  Future<void> signOut() => _orThrow(null);
}

void main() {
  late FakeSupabaseAuthDataSource datasource;
  late AuthRepositoryImpl repository;

  setUp(() {
    datasource = FakeSupabaseAuthDataSource();
    repository = AuthRepositoryImpl(datasource);
  });

  const email = 'a@b.co';
  const password = 'Abcdefg1';

  test('signInWithPassword maps success to Ok AuthSession', () async {
    final result = await repository.signInWithPassword(
      email: email,
      password: password,
    );

    expect(result, isA<Ok<AuthSession>>());
    expect(
      (result as Ok<AuthSession>).value,
      const AuthSession(id: 'u1', email: email),
    );
  });

  test(
    'signInWithPassword maps UnauthorizedException to UnauthorizedFailure',
    () async {
      datasource.toThrow = const UnauthorizedException('Invalid login');

      final result = await repository.signInWithPassword(
        email: email,
        password: password,
      );

      expect(result, isA<Err<AuthSession>>());
      final failure = (result as Err<AuthSession>).failure;
      expect(failure, isA<UnauthorizedFailure>());
      expect(failure.message, isNotEmpty);
    },
  );

  test('signInWithPassword maps NetworkException to NetworkFailure', () async {
    datasource.toThrow = const NetworkException('offline');

    final result = await repository.signInWithPassword(
      email: email,
      password: password,
    );

    expect(result, isA<Err<AuthSession>>());
    final failure = (result as Err<AuthSession>).failure;
    expect(failure, isA<NetworkFailure>());
    expect(failure.message, 'offline');
  });

  test(
    'signInWithPassword maps ValidationException keeping fieldErrors',
    () async {
      datasource.toThrow = const ValidationException(
        'Un compte existe déjà avec cet email.',
        fieldErrors: {'email': 'Un compte existe déjà avec cet email.'},
      );

      final result = await repository.signInWithPassword(
        email: email,
        password: password,
      );

      expect(result, isA<Err<AuthSession>>());
      final failure = (result as Err<AuthSession>).failure;
      expect(failure, isA<ValidationFailure>());
      expect((failure as ValidationFailure).fieldErrors, {
        'email': 'Un compte existe déjà avec cet email.',
      });
    },
  );

  test('signInWithPassword maps ServerException to ServerFailure', () async {
    datasource.toThrow = const ServerException('boom');

    final result = await repository.signInWithPassword(
      email: email,
      password: password,
    );

    expect(result, isA<Err<AuthSession>>());
    final failure = (result as Err<AuthSession>).failure;
    expect(failure, isA<ServerFailure>());
    expect(failure.message, 'boom');
  });

  test(
    'signInWithPassword maps unknown exceptions to UnknownFailure',
    () async {
      datasource.toThrow = _UnexpectedException();

      final result = await repository.signInWithPassword(
        email: email,
        password: password,
      );

      expect(result, isA<Err<AuthSession>>());
      expect((result as Err<AuthSession>).failure, isA<UnknownFailure>());
    },
  );
}

class _UnexpectedException implements Exception {}
