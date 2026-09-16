/// Pure path matching for auth deep links (testable without Supabase).
enum AuthDeepLinkKind { oauthCallback, passwordReset, ignored }

class AuthDeepLinkRouter {
  const AuthDeepLinkRouter._();

  static AuthDeepLinkKind kind(Uri uri) {
    final hostOk =
        uri.host == 'www.agapeo.love' || uri.host == 'agapeo.love';
    if (!hostOk) return AuthDeepLinkKind.ignored;

    final path = uri.path.endsWith('/') && uri.path.length > 1
        ? uri.path.substring(0, uri.path.length - 1)
        : uri.path;

    return switch (path) {
      '/auth/callback' => AuthDeepLinkKind.oauthCallback,
      '/auth/reset' => AuthDeepLinkKind.passwordReset,
      _ => AuthDeepLinkKind.ignored,
    };
  }
}
