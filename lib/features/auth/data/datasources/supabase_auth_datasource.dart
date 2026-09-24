import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/deep_link_urls.dart';
import '../../../../core/config/google_sign_in_config.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/deep_link/auth_deep_link_router.dart';
import '../../domain/entities/auth_deep_link_result.dart';
import 'auth_remote_datasource.dart';

class SupabaseAuthDataSource implements AuthRemoteDataSource {
  SupabaseAuthDataSource(this._client);

  final SupabaseClient _client;

  /// `initialize()` doit être appelé exactement une fois avant tout autre
  /// appel à `GoogleSignIn.instance` - mémorisé pour rester idempotent
  /// entre deux tentatives de connexion.
  Future<void>? _googleSignInInit;

  Future<void> _ensureGoogleSignInInitialized() {
    return _googleSignInInit ??= GoogleSignIn.instance.initialize(
      clientId: GoogleSignInConfig.iosClientId,
      serverClientId: GoogleSignInConfig.webClientId,
    );
  }

  ({String id, String email}) _mapUser(User user) =>
      (id: user.id, email: user.email ?? '');

  /// Nonce brut, envoyé à Supabase - Apple ne reçoit que son hash SHA-256
  /// (voir [signInWithApple]), pour se prémunir des attaques par rejeu.
  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

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
      await _client.auth.resetPasswordForEmail(
        email,
        redirectTo: DeepLinkUrls.reset,
      );
    } on AuthException catch (e) {
      throw _mapAuthException(e);
    }
  }

  @override
  Future<({String id, String email})> signInWithGoogle() async {
    try {
      await _ensureGoogleSignInInitialized();
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw const UnauthorizedException(
          'Connexion Google impossible (jeton manquant).',
        );
      }
      final res = await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );
      final user = res.user;
      if (user == null) {
        throw const UnauthorizedException('Connexion Google impossible.');
      }
      return _mapUser(user);
    } on GoogleSignInException catch (e) {
      throw e.code == GoogleSignInExceptionCode.canceled
          ? const UnauthorizedException('Connexion Google annulée.')
          : const ServerException('Connexion Google impossible.');
    } on AuthException catch (e) {
      throw _mapAuthException(e);
    }
  }

  @override
  Future<({String id, String email})> signInWithApple() async {
    try {
      final rawNonce = _generateNonce();
      final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );
      final idToken = credential.identityToken;
      if (idToken == null) {
        throw const UnauthorizedException(
          'Connexion Apple impossible (jeton manquant).',
        );
      }
      final res = await _client.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );
      final user = res.user;
      if (user == null) {
        throw const UnauthorizedException('Connexion Apple impossible.');
      }
      return _mapUser(user);
    } on SignInWithAppleAuthorizationException catch (e) {
      throw e.code == AuthorizationErrorCode.canceled
          ? const UnauthorizedException('Connexion Apple annulée.')
          : const ServerException('Connexion Apple impossible.');
    } on AuthException catch (e) {
      throw _mapAuthException(e);
    }
  }

  @override
  Future<({String id, String email})> updatePassword({
    required String password,
  }) async {
    try {
      final res = await _client.auth.updateUser(
        UserAttributes(password: password),
      );
      final user = res.user;
      if (user == null) {
        throw const ValidationException(
          'Impossible de mettre à jour le mot de passe.',
        );
      }
      return _mapUser(user);
    } on AuthException catch (e) {
      throw _mapAuthException(e);
    }
  }

  @override
  Future<AuthDeepLinkResult> handleAuthDeepLink(Uri uri) async {
    if (AuthDeepLinkRouter.kind(uri) == AuthDeepLinkKind.ignored) {
      return const AuthDeepLinkIgnored();
    }
    try {
      await _client.auth.getSessionFromUrl(uri);
      return const AuthDeepLinkPasswordRecovery();
    } on AuthException catch (e) {
      throw _mapAuthException(e);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } on AuthException catch (e) {
      throw _mapAuthException(e);
    }
  }

  static const _invalidCredentials = UnauthorizedException(
    'Email ou mot de passe incorrect.',
  );
  static const _emailNotConfirmed = EmailNotConfirmedException(
    'Email non confirmé. Confirme ton compte pour continuer.',
  );
  static const _userAlreadyExists = ValidationException(
    'Un compte existe déjà avec cet email.',
    fieldErrors: {'email': 'Un compte existe déjà avec cet email.'},
  );
  static const _rateLimited = ServerException(
    'Trop de demandes. Réessaie dans quelques minutes.',
  );

  /// `AuthException.code` est la source la plus fiable ; le message n'est
  /// utilisé qu'en repli (codes absents sur les anciennes réponses GoTrue).
  Exception _mapAuthException(AuthException e) {
    switch (e.code) {
      case 'invalid_credentials':
        return _invalidCredentials;
      case 'email_not_confirmed':
        return _emailNotConfirmed;
      case 'user_already_exists':
        return _userAlreadyExists;
      case 'over_email_send_rate_limit':
        return _rateLimited;
    }

    final msg = e.message.toLowerCase();
    if (msg.contains('invalid login') || msg.contains('invalid credentials')) {
      return _invalidCredentials;
    }
    if (msg.contains('email not confirmed')) {
      return _emailNotConfirmed;
    }
    if (msg.contains('user already registered')) {
      return _userAlreadyExists;
    }
    if (msg.contains('rate limit')) {
      return _rateLimited;
    }
    if (msg.contains('network') || msg.contains('socket')) {
      return NetworkException(e.message);
    }
    return e.message.trim().isEmpty
        ? const ServerException('Une erreur serveur est survenue.')
        : ServerException(e.message);
  }
}
