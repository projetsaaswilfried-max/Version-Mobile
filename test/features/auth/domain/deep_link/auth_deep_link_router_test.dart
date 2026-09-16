import 'package:agapeo/features/auth/domain/deep_link/auth_deep_link_router.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('classifies oauth callback', () {
    final uri = Uri.parse('https://www.agapeo.love/auth/callback?code=abc');
    expect(AuthDeepLinkRouter.kind(uri), AuthDeepLinkKind.oauthCallback);
  });

  test('classifies password reset', () {
    final uri = Uri.parse('https://www.agapeo.love/auth/reset#access_token=x');
    expect(AuthDeepLinkRouter.kind(uri), AuthDeepLinkKind.passwordReset);
  });

  test('ignores unknown host or path', () {
    expect(
      AuthDeepLinkRouter.kind(Uri.parse('https://evil.com/auth/callback')),
      AuthDeepLinkKind.ignored,
    );
    expect(
      AuthDeepLinkRouter.kind(Uri.parse('https://www.agapeo.love/other')),
      AuthDeepLinkKind.ignored,
    );
  });
}
