import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/result.dart';
import '../../../../core/error/user_facing_message.dart';
import '../../../../core/navigation/root_navigator.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../di/auth_providers.dart';
import '../../domain/entities/auth_deep_link_result.dart';
import '../reset_password/reset_password_page.dart';

/// Listens for the password-reset deep link and navigates accordingly.
/// Google Sign-In is native (no browser, no deep link) — this is the only
/// auth deep link left.
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

  // app_links can deliver the app-launch link both via getInitialLink()
  // and as the first uriLinkStream event, depending on platform/timing.
  // Auth codes are single-use, so handling it twice would fail the second
  // attempt for no reason — dedupe on the exact URI.
  Uri? _lastHandledUri;

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
    if (_lastHandledUri == uri) return;
    _lastHandledUri = uri;

    final result = await ref
        .read(authRepositoryProvider)
        .handleAuthDeepLink(uri);
    final nav = rootNavigatorKey.currentState;
    if (nav == null) return;
    switch (result) {
      case Ok(:final value):
        switch (value) {
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
      case Err(:final failure):
        final context = nav.overlay?.context;
        if (context == null || !context.mounted) return;
        AppToast.show(context, userFacingMessage(failure));
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
