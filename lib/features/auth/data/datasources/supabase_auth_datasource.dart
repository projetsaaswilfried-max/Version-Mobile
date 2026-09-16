import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/exceptions.dart';
import 'auth_remote_datasource.dart';

class SupabaseAuthDataSource implements AuthRemoteDataSource {
  SupabaseAuthDataSource(this._client);

  final SupabaseClient _client;

  ({String id, String email}) _mapUser(User user) =>
      (id: user.id, email: user.email ?? '');

  @override
  ({String id, String email})? get currentUser {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    return _mapUser(user);
  }

  @override
  Stream<({String id, String email})?> get onAuthStateChange =>
      _client.auth.onAuthStateChange.map((state) {
        final user = state.session?.user;
        if (user == null) return null;
        return _mapUser(user);
      });

  @override
  Future<({String id, String email})> signInWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final user = res.user;
      if (user == null) {
        throw const UnauthorizedException('Identifiants incorrects.');
      }
      return _mapUser(user);
    } on AuthException catch (e) {
      throw _mapAuthException(e);
    }
  }

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required String firstName,
    String? lastName,
  }) async {
    try {
      await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'first_name': firstName,
          if (lastName != null && lastName.isNotEmpty) 'last_name': lastName,
        },
      );
    } on AuthException catch (e) {
      throw _mapAuthException(e);
    }
  }

  @override
  Future<({String id, String email})> verifyEmailOtp({
    required String email,
    required String token,
  }) async {
    try {
      final res = await _client.auth.verifyOTP(
        type: OtpType.signup,
        email: email,
        token: token,
      );
      final user = res.user;
      if (user == null) {
        throw const ValidationException('Code incorrect ou expiré.');
      }
      return _mapUser(user);
    } on AuthException catch (e) {
      throw _mapAuthException(e);
    }
  }

  @override
  Future<void> resendSignupEmail({required String email}) async {
    try {
      await _client.auth.resend(type: OtpType.signup, email: email);
    } on AuthException catch (e) {
      throw _mapAuthException(e);
    }
  }

  @override
  Future<void> requestPasswordReset({required String email}) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      throw _mapAuthException(e);
    }
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Exception _mapAuthException(AuthException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('invalid login') || msg.contains('invalid credentials')) {
      return const UnauthorizedException('Email ou mot de passe incorrect.');
    }
    if (msg.contains('email not confirmed')) {
      return const UnauthorizedException(
        'Email non confirmé. Vérifie ta boîte mail ou saisis le code.',
      );
    }
    if (msg.contains('user already registered')) {
      return const ValidationException(
        'Un compte existe déjà avec cet email.',
        fieldErrors: {'email': 'Un compte existe déjà avec cet email.'},
      );
    }
    if (msg.contains('network') || msg.contains('socket')) {
      return NetworkException(e.message);
    }
    return ServerException(e.message);
  }
}
