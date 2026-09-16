import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/result.dart';
import '../../../../core/navigation/root_navigator.dart';
import '../../di/auth_providers.dart';
import '../../domain/entities/auth_deep_link_result.dart';
import '../reset_password/reset_password_page.dart';
import '../session_stub/session_stub_page.dart';

/// Listens for OAuth / password-reset deep links and navigates accordingly.
class AuthDeepLinkListener extends ConsumerStatefulWidget {
  const AuthDeepLinkListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AuthDeepLinkListener> createState() =>
      _AuthDeepLinkListenerState();
}

class _AuthDeepLinkListenerState extends ConsumerState<AuthDeepLinkListener> {
  StreamSubscription<Uri>? _sub;
  final _appLinks = AppLinks();

  @override
  void initState() {
    super.initState();
    _sub = _appLinks.uriLinkStream.listen(_onUri);
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) _onUri(uri);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _onUri(Uri uri) async {
    final result = await ref
        .read(authRepositoryProvider)
        .handleAuthDeepLink(uri);
    final nav = rootNavigatorKey.currentState;
    if (nav == null) return;
    switch (result) {
      case Ok(:final value):
        switch (value) {
          case AuthDeepLinkOauthSession(:final session):
            nav.pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (_) => SessionStubPage(email: session.email),
              ),
              (route) => false,
            );
          case AuthDeepLinkPasswordRecovery():
            final email =
                ref.read(authRepositoryProvider).currentSession?.email ?? '';
            nav.pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (_) => ResetPasswordPage(email: email),
              ),
              (route) => false,
            );
          case AuthDeepLinkIgnored():
            break;
        }
      case Err():
        break;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
