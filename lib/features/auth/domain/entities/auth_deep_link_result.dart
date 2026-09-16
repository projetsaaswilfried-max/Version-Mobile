import 'package:equatable/equatable.dart';

import 'auth_session.dart';

/// Outcome of parsing an inbound auth deep link.
sealed class AuthDeepLinkResult extends Equatable {
  const AuthDeepLinkResult();
}

class AuthDeepLinkOauthSession extends AuthDeepLinkResult {
  const AuthDeepLinkOauthSession(this.session);

  final AuthSession session;

  @override
  List<Object?> get props => [session];
}

class AuthDeepLinkPasswordRecovery extends AuthDeepLinkResult {
  const AuthDeepLinkPasswordRecovery();

  @override
  List<Object?> get props => [];
}

class AuthDeepLinkIgnored extends AuthDeepLinkResult {
  const AuthDeepLinkIgnored();

  @override
  List<Object?> get props => [];
}
