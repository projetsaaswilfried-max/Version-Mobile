import 'package:equatable/equatable.dart';

/// Outcome of parsing an inbound auth deep link.
sealed class AuthDeepLinkResult extends Equatable {
  const AuthDeepLinkResult();
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
