import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/error/user_facing_message.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../home/presentation/home_shell_page.dart';
import '../../../onboarding/presentation/profile_onboarding/onboarding_flow_page.dart';
import '../../../push_notifications/di/push_notifications_providers.dart';
import '../../di/profile_providers.dart';
import '../../domain/entities/member_gate_snapshot.dart';
import '../../domain/entities/post_login_destination.dart';
import '../../domain/usecases/resolve_post_login_route.dart';
import '../expired/expired_subscription_page.dart';
import '../suspended/suspended_account_page.dart';

/// Maps a resolved post-login destination to its page.
Widget pageForDestination(
  PostLoginDestination destination, {
  required String email,
}) {
  return switch (destination) {
    PostLoginDestination.suspended => const SuspendedAccountPage(),
    PostLoginDestination.expired => const ExpiredSubscriptionPage(),
    PostLoginDestination.onboarding => const OnboardingFlowPage(),
    PostLoginDestination.home => const HomeShellPage(),
  };
}

/// Resolves [gate] to a page. Caller is responsible for Err toasts.
Widget pageForGate(
  Result<MemberGateSnapshot> gate,
  ResolvePostLoginRoute resolve, {
  required String email,
}) {
  return switch (gate) {
    Ok(:final value) => pageForDestination(resolve(value), email: email),
    Err() => const HomeShellPage(),
  };
}

/// After a session is established, fetch the gate and navigate to the
/// destination (suspended / expired / onboarding / home).
///
/// On [Err]: toast + defensive [HomeShellPage].
Future<void> navigateAfterAuth(
  WidgetRef ref,
  BuildContext context, {
  required String email,
}) async {
  _prefetchProfileFields(ref);
  _registerPushToken(ref);
  final gate = await ref.read(profileGateRepositoryProvider).fetchGate();
  if (!context.mounted) return;

  final page = pageForGate(
    gate,
    ref.read(resolvePostLoginRouteProvider),
    email: email,
  );

  if (gate case Err(:final failure)) {
    _showGateFailureToast(context, failure);
  }

  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => page),
    (route) => false,
  );
}

void _prefetchProfileFields(WidgetRef ref) {
  try {
    // `profileFieldsProvider` est un cache session-wide (pas autoDispose) :
    // sans cet invalidate, une reconnexion avec un autre compte réutilisait
    // les champs (et donc la complétude) du précédent utilisateur jusqu'au
    // redémarrage de l'app.
    ref.invalidate(profileFieldsProvider);
    unawaited(
      ref.read(profileFieldsProvider.future).then((_) {}, onError: (_) {}),
    );
  } catch (_) {
    // Env non configuré : le gate reste la source de vérité pour la nav.
  }
}

/// Demande la permission de notifications et enregistre le token FCM.
/// Fire-and-forget : ne doit jamais bloquer/retarder la navigation
/// post-connexion, même si Firebase n'est pas configuré (tests) ou que la
/// permission est refusée.
void _registerPushToken(WidgetRef ref) {
  unawaited(
    () async {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;
      final token = await messaging.getToken();
      if (token == null) return;
      await ref
          .read(deviceTokensRepositoryProvider)
          .registerToken(
            token: token,
            platform: Platform.isIOS ? 'ios' : 'android',
          );
    }().catchError((_) {}),
  );
}

void _showGateFailureToast(BuildContext context, Failure failure) {
  AppToast.show(context, userFacingMessage(failure));
}
