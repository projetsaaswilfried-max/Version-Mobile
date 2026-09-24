import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../notifications/presentation/notifications_controller.dart';
import '../../notifications/presentation/open_notification_target.dart';
import '../di/push_notifications_providers.dart';

/// Écoute les messages FCM pour toute la durée de vie de l'app - pas
/// d'accès à un [BuildContext] widget, même pattern que
/// [AuthDeepLinkListener] (rootNavigatorKey, pas de contexte requis).
///
/// Pas de bannière au premier plan (juste rafraîchir la liste/le badge).
/// Le tap (arrière-plan/app fermée) route directement vers la cible via
/// [openNotificationTarget], même logique que le tap sur une ligne de
/// `NotificationsPage` - le payload push transporte les mêmes données
/// (`type`/`targetUrl`/`actorId`) que la table `notifications`.
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
        (message) => _openTarget(message.data),
      );
      FirebaseMessaging.instance.getInitialMessage().then((message) {
        if (message != null) _openTarget(message.data);
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

  /// Le backend confirme que le payload push transporte les mêmes données
  /// que la ligne `notifications` correspondante - `targetUrl` confirmé
  /// (camelCase). `type`/`actorId` pas confirmés à l'écriture de ce code :
  /// on tente les deux casses plausibles ; s'ils sont absents, le switch
  /// par défaut de [openNotificationTarget] retombe sur `targetUrl` seul
  /// (extraction de l'id de conversation), sans jamais planter.
  void _openTarget(Map<String, dynamic> data) {
    openNotificationTarget(
      ref,
      type: data['type'] as String?,
      targetUrl: (data['targetUrl'] ?? data['target_url']) as String?,
      actorId: (data['actorId'] ?? data['actor_id']) as String?,
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
