import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/navigation/root_navigator.dart';
import '../../../home/presentation/home_shell_page.dart';
import '../../../onboarding/presentation/profile_onboarding/onboarding_flow_page.dart';
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

/// Resolves [gate] to a page. Caller is responsible for Err snackbars.
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
/// On [Err]: snackbar + defensive [HomeShellPage].
Future<void> navigateAfterAuth(
  WidgetRef ref,
  BuildContext context, {
  required String email,
}) async {
  final gate = await ref.read(profileGateRepositoryProvider).fetchGate();
  if (!context.mounted) return;

  final page = pageForGate(
    gate,
    ref.read(resolvePostLoginRouteProvider),
    email: email,
  );

  if (gate case Err(:final failure)) {
    _showGateFailureSnackBar(context, failure);
  }

  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => page),
    (route) => false,
  );
}

/// Same as [navigateAfterAuth] but via [NavigatorState] (deep-link listener,
/// where [BuildContext] snackbars are unreliable). Uses [rootNavigatorKey]
/// overlay context for Err snackbars when [nav] has no overlay of its own.
Future<void> navigateAfterAuthWithNav(
  WidgetRef ref,
  NavigatorState nav, {
  required String email,
}) async {
  final gate = await ref.read(profileGateRepositoryProvider).fetchGate();

  final page = pageForGate(
    gate,
    ref.read(resolvePostLoginRouteProvider),
    email: email,
  );

  if (gate case Err(:final failure)) {
    final overlayContext =
        nav.overlay?.context ?? rootNavigatorKey.currentState?.overlay?.context;
    if (overlayContext != null && overlayContext.mounted) {
      _showGateFailureSnackBar(overlayContext, failure);
    }
  }

  nav.pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => page),
    (route) => false,
  );
}

void _showGateFailureSnackBar(BuildContext context, Failure failure) {
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(failure.message)));
}
