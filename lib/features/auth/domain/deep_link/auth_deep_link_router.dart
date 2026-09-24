/// Pure path matching for auth deep links (testable without Supabase).
///
/// Google Sign-In is native (no browser, no deep link) - `/auth/callback`
/// was its OAuth redirect and no longer exists. Password reset is the only
/// auth deep link left.
enum AuthDeepLinkKind { passwordReset, ignored }

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
      '/auth/reset' => AuthDeepLinkKind.passwordReset,
      _ => AuthDeepLinkKind.ignored,
    };
  }
}
