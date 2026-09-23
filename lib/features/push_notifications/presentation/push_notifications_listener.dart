import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/navigation/root_navigator.dart';
import '../../notifications/presentation/notifications_controller.dart';
import '../../notifications/presentation/notifications_page.dart';
import '../di/push_notifications_providers.dart';

/// Écoute les messages FCM pour toute la durée de vie de l'app - pas
/// d'accès à un [BuildContext] widget, même pattern que
/// [AuthDeepLinkListener] (rootNavigatorKey, pas de contexte requis).
///
/// Décisions confirmées (2026-09-23) : pas de bannière au premier plan
/// (juste rafraîchir la liste/le badge), le tap ouvre toujours la liste
/// `NotificationsPage` (qui a déjà la logique de navigation par cible)
/// plutôt qu'un deep-link direct depuis le payload push.
class PushNotificationsListener extends ConsumerStatefulWidget {
  const PushNotificationsListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<PushNotificationsListener> createState() =>
      _PushNotificationsListenerState();
}

class _PushNotificationsListenerState
    extends ConsumerState<PushNotificationsListener>
    with WidgetsBindingObserver {
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<RemoteMessage>? _openedAppSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    try {
      _tokenRefreshSub = FirebaseMessaging.instance.onTokenRefresh.listen(
        _onTokenRefresh,
      );
      _foregroundSub = FirebaseMessaging.onMessage.listen((_) {
        ref.invalidate(notificationsControllerProvider);
      });
      _openedAppSub = FirebaseMessaging.onMessageOpenedApp.listen(
        (_) => _openNotifications(),
      );
      FirebaseMessaging.instance.getInitialMessage().then((message) {
        if (message != null) _openNotifications();
      });
    } catch (_) {
      // Firebase non initialisé (tests, env sans config native) - jamais
      // bloquant pour le reste de l'app.
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tokenRefreshSub?.cancel();
    _foregroundSub?.cancel();
    _openedAppSub?.cancel();
    super.dispose();
  }

  /// Un push reçu en arrière-plan ne passe ni par [FirebaseMessaging.onMessage]
  /// (premier plan uniquement) ni par `onMessageOpenedApp` (seulement si
  /// l'utilisateur tape la notif) - sans ça, revenir sur l'app par un
  /// simple retour (pas un tap sur la notif) laissait la liste obsolète.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(notificationsControllerProvider);
    }
  }

  Future<void> _onTokenRefresh(String token) async {
    if (Supabase.instance.client.auth.currentUser == null) return;
    await ref
        .read(deviceTokensRepositoryProvider)
        .registerToken(
          token: token,
          platform: Platform.isIOS ? 'ios' : 'android',
        );
  }

  void _openNotifications() {
    final nav = rootNavigatorKey.currentState;
    if (nav == null) return;
    nav.push(MaterialPageRoute<void>(builder: (_) => const NotificationsPage()));
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
