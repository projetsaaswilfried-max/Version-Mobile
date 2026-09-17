# Post-login routing (X07) + « Revenir plus tard » Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Après toute session établie, router suspendu → EXPIRED → onboarding → SessionStub ; ajouter « Revenir plus tard » (sans écrire `onboarding_completed`).

**Architecture:** Feature `profile/` (gate) Clean Arch : usecase pur `ResolvePostLoginRoute` + `ProfileGateRepository` (Supabase). Helper presentation `navigateAfterAuth` branché Splash / Login / OTP / deep link / A08. Onboarding : lien secondary → SessionStub direct.

**Tech Stack:** Flutter, Riverpod, Equatable, `supabase_flutter`, `flutter_test`.

## Global Constraints

- Pas de tiret cadratin / demi-cadratin dans code, docs, commits.
- Tokens design system uniquement (`context.colors`, `AppSpacing`, `AppButton`).
- Domain Dart pur (zéro Flutter / Supabase / Dio).
- Ordre gate strict (addendum §1.3) : `is_suspended` → `EXPIRED` → `!onboarding_completed` → homeStub.
- « Revenir plus tard » n'écrit jamais `onboarding_completed` et n'appelle pas le usecase.
- Shell 4 tabs (#7) hors scope : `homeStub` = `SessionStubPage`.
- Spec : `docs/superpowers/specs/2026-09-17-post-login-routing-design.md`.
- Branche d'implémentation : `feat/post-login-routing` (partir de `main` à jour ; merger la branche docs si besoin).
- Conventional Commits ; `flutter analyze` + `flutter test` verts avant MR.

---

## File map

| File | Role |
|---|---|
| `lib/features/profile/domain/entities/member_gate_snapshot.dart` | Snapshot gate |
| `lib/features/profile/domain/entities/post_login_destination.dart` | Sealed destinations |
| `lib/features/profile/domain/entities/subscription_status.dart` | Enum FREE/ACTIVE/CANCELED/EXPIRED |
| `lib/features/profile/domain/repositories/profile_gate_repository.dart` | Interface |
| `lib/features/profile/domain/usecases/resolve_post_login_route.dart` | Usecase pur |
| `lib/features/profile/data/datasources/profile_gate_remote_datasource.dart` | Interface data |
| `lib/features/profile/data/datasources/supabase_profile_gate_datasource.dart` | Selects Supabase |
| `lib/features/profile/data/repositories/profile_gate_repository_impl.dart` | Impl + map errors |
| `lib/features/profile/di/profile_providers.dart` | Providers + unconfigured |
| `lib/features/profile/presentation/navigation/navigate_after_auth.dart` | Helper navigation |
| `lib/features/profile/presentation/suspended/suspended_account_page.dart` | O06 |
| `lib/features/profile/presentation/expired/expired_subscription_page.dart` | Mur EXPIRED |
| `lib/features/onboarding/presentation/profile_onboarding/onboarding_flow_page.dart` | + Revenir plus tard |
| `lib/features/onboarding/presentation/splash/splash_page.dart` | Route via helper |
| `lib/features/auth/presentation/login/login_page.dart` | Idem |
| `lib/features/auth/presentation/otp/otp_page.dart` | Idem |
| `lib/features/auth/presentation/reset_password/reset_password_page.dart` | Idem |
| `lib/features/auth/presentation/deep_link/auth_deep_link_listener.dart` | OAuth → helper |
| Tests miroirs sous `test/features/profile/` + onboarding smoke |

---

### Task 1: Domain gate (entities + ResolvePostLoginRoute)

**Files:**
- Create: `lib/features/profile/domain/entities/subscription_status.dart`
- Create: `lib/features/profile/domain/entities/member_gate_snapshot.dart`
- Create: `lib/features/profile/domain/entities/post_login_destination.dart`
- Create: `lib/features/profile/domain/repositories/profile_gate_repository.dart`
- Create: `lib/features/profile/domain/usecases/resolve_post_login_route.dart`
- Test: `test/features/profile/domain/usecases/resolve_post_login_route_test.dart`

**Interfaces:**
- Produces: `ResolvePostLoginRoute.call(MemberGateSnapshot) → PostLoginDestination`
- Produces: `ProfileGateRepository.fetchGate() → Future<Result<MemberGateSnapshot>>`

- [ ] **Step 1: Write failing tests**

```dart
import 'package:agapeo/features/profile/domain/entities/member_gate_snapshot.dart';
import 'package:agapeo/features/profile/domain/entities/post_login_destination.dart';
import 'package:agapeo/features/profile/domain/entities/subscription_status.dart';
import 'package:agapeo/features/profile/domain/usecases/resolve_post_login_route.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const resolve = ResolvePostLoginRoute();

  test('suspended wins over expired and incomplete onboarding', () {
    final dest = resolve(
      const MemberGateSnapshot(
        isSuspended: true,
        subscriptionStatus: SubscriptionStatus.expired,
        onboardingCompleted: false,
      ),
    );
    expect(dest, PostLoginDestination.suspended);
  });

  test('expired when not suspended', () {
    expect(
      resolve(
        const MemberGateSnapshot(
          isSuspended: false,
          subscriptionStatus: SubscriptionStatus.expired,
          onboardingCompleted: true,
        ),
      ),
      PostLoginDestination.expired,
    );
  });

  test('onboarding when not suspended and not expired', () {
    expect(
      resolve(
        const MemberGateSnapshot(
          isSuspended: false,
          subscriptionStatus: SubscriptionStatus.free,
          onboardingCompleted: false,
        ),
      ),
      PostLoginDestination.onboarding,
    );
  });

  test('homeStub otherwise', () {
    expect(
      resolve(
        const MemberGateSnapshot(
          isSuspended: false,
          subscriptionStatus: SubscriptionStatus.active,
          onboardingCompleted: true,
        ),
      ),
      PostLoginDestination.homeStub,
    );
  });

  test('CANCELED is not EXPIRED wall', () {
    expect(
      resolve(
        const MemberGateSnapshot(
          isSuspended: false,
          subscriptionStatus: SubscriptionStatus.canceled,
          onboardingCompleted: true,
        ),
      ),
      PostLoginDestination.homeStub,
    );
  });
}
```

- [ ] **Step 2: Run test → expect FAIL (missing library)**

Run: `flutter test test/features/profile/domain/usecases/resolve_post_login_route_test.dart`  
Expected: FAIL compilation / missing file

- [ ] **Step 3: Implement domain types + usecase**

```dart
// subscription_status.dart
enum SubscriptionStatus { free, active, canceled, expired }

// member_gate_snapshot.dart
import 'package:equatable/equatable.dart';
import 'subscription_status.dart';

class MemberGateSnapshot extends Equatable {
  const MemberGateSnapshot({
    required this.isSuspended,
    required this.subscriptionStatus,
    required this.onboardingCompleted,
  });

  final bool isSuspended;
  final SubscriptionStatus subscriptionStatus;
  final bool onboardingCompleted;

  @override
  List<Object?> get props =>
      [isSuspended, subscriptionStatus, onboardingCompleted];
}

// post_login_destination.dart
enum PostLoginDestination { suspended, expired, onboarding, homeStub }

// profile_gate_repository.dart
import '../../../../core/error/result.dart';
import '../entities/member_gate_snapshot.dart';

abstract class ProfileGateRepository {
  Future<Result<MemberGateSnapshot>> fetchGate();
}

// resolve_post_login_route.dart
import '../entities/member_gate_snapshot.dart';
import '../entities/post_login_destination.dart';
import '../entities/subscription_status.dart';

class ResolvePostLoginRoute {
  const ResolvePostLoginRoute();

  PostLoginDestination call(MemberGateSnapshot snapshot) {
    if (snapshot.isSuspended) return PostLoginDestination.suspended;
    if (snapshot.subscriptionStatus == SubscriptionStatus.expired) {
      return PostLoginDestination.expired;
    }
    if (!snapshot.onboardingCompleted) {
      return PostLoginDestination.onboarding;
    }
    return PostLoginDestination.homeStub;
  }
}
```

- [ ] **Step 4: Run tests → PASS**

Run: `flutter test test/features/profile/domain/usecases/resolve_post_login_route_test.dart`  
Expected: All tests passed

- [ ] **Step 5: Commit**

```bash
git add lib/features/profile/domain test/features/profile/domain
git commit -m "feat(profile): ResolvePostLoginRoute et snapshot gate"
```

---

### Task 2: Data Supabase + providers

**Files:**
- Create: `lib/features/profile/data/datasources/profile_gate_remote_datasource.dart`
- Create: `lib/features/profile/data/datasources/supabase_profile_gate_datasource.dart`
- Create: `lib/features/profile/data/repositories/profile_gate_repository_impl.dart`
- Create: `lib/features/profile/di/profile_providers.dart`
- Test: `test/features/profile/data/profile_gate_repository_impl_test.dart` (fake datasource mapping)

**Interfaces:**
- Consumes: `ProfileGateRepository`, `MemberGateSnapshot`, `SubscriptionStatus`
- Produces: `profileGateRepositoryProvider`, `resolvePostLoginRouteProvider`
- Datasource: `Future<({bool isSuspended, String subscriptionStatus, bool onboardingCompleted})> fetchGateRaw()`

- [ ] **Step 1: Write failing repository mapping test**

```dart
// Fake remote returns strings; impl maps EXPIRED → enum; NetworkException → Err
```

Cover at least:
- `subscription_status: 'EXPIRED'` → `SubscriptionStatus.expired`
- unknown / null status → treat as `free` (safe default, not expired wall)
- `onboarding_completed` null → `false`

- [ ] **Step 2: Run → FAIL**

- [ ] **Step 3: Implement datasource + repository + providers**

`SupabaseProfileGateDataSource`:

```dart
// Pseudocode structure - implement fully in task
final userId = _client.auth.currentUser?.id;
if (userId == null) throw const UnauthorizedException('Session expirée.');

final profile = await _client
    .from('profiles')
    .select('onboarding_completed')
    .eq('id', userId)
    .maybeSingle();

final restricted = await _client
    .from('profile_restricted')
    .select('is_suspended, subscription_status')
    .eq('id', userId)
    .maybeSingle();
```

Parse with `Json(...)`. Map Postgrest/Auth errors to existing `NetworkException` / `UnauthorizedException` / `ServerException` like auth datasource.

`profile_providers.dart`:

```dart
final profileGateRepositoryProvider = Provider<ProfileGateRepository>((ref) {
  final env = AppEnvironment.current;
  if (env.supabaseUrl.isEmpty || env.supabaseAnonKey.isEmpty) {
    return const _UnconfiguredProfileGateRepository();
  }
  return ProfileGateRepositoryImpl(
    SupabaseProfileGateDataSource(ref.watch(supabaseClientProvider)),
  );
});

final resolvePostLoginRouteProvider = Provider(
  (_) => const ResolvePostLoginRoute(),
);
```

`_UnconfiguredProfileGateRepository.fetchGate` → `const Err(ServerFailure('Supabase non configuré...'))` (même ton que auth).

- [ ] **Step 4: Run mapping tests → PASS**

- [ ] **Step 5: Commit**

```bash
git add lib/features/profile/data lib/features/profile/di test/features/profile/data
git commit -m "feat(profile): lecture gate Supabase profiles + restricted"
```

---

### Task 3: O06 + mur EXPIRED + navigateAfterAuth

**Files:**
- Create: `lib/features/profile/presentation/suspended/suspended_account_page.dart`
- Create: `lib/features/profile/presentation/expired/expired_subscription_page.dart`
- Create: `lib/features/profile/presentation/navigation/navigate_after_auth.dart`
- Test: `test/features/profile/presentation/suspended/suspended_account_page_test.dart`
- Test: `test/features/profile/presentation/expired/expired_subscription_page_test.dart`

**Interfaces:**
- Consumes: `profileGateRepositoryProvider`, `resolvePostLoginRouteProvider`, `authRepositoryProvider` (email / signOut)
- Produces: `Future<void> navigateAfterAuth(WidgetRef ref, BuildContext context, {required String email})`

- [ ] **Step 1: Write smoke widget tests**

```dart
// suspended: finds « Compte suspendu », tap Déconnexion → WelcomePage
// expired: finds « Abonnement expiré », Déconnexion → WelcomePage
```

Override `signOutProvider` / use real `SignOut` with fake auth repo that returns Ok.

- [ ] **Step 2: Run → FAIL**

- [ ] **Step 3: Implement pages (tokens only) + helper**

```dart
Future<void> navigateAfterAuth(
  WidgetRef ref,
  BuildContext context, {
  required String email,
}) async {
  final gate = await ref.read(profileGateRepositoryProvider).fetchGate();
  if (!context.mounted) return;

  final Widget page;
  switch (gate) {
    case Ok(:final value):
      final dest = ref.read(resolvePostLoginRouteProvider)(value);
      page = switch (dest) {
        PostLoginDestination.suspended => const SuspendedAccountPage(),
        PostLoginDestination.expired => const ExpiredSubscriptionPage(),
        PostLoginDestination.onboarding => const OnboardingFlowPage(),
        PostLoginDestination.homeStub => SessionStubPage(email: email),
      };
    case Err(:final failure):
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.message)),
      );
      page = SessionStubPage(email: email);
  }

  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => page),
    (route) => false,
  );
}
```

For deep link listener (no reliable `BuildContext` snackbar): use `rootNavigatorKey` + overlay context like today for Err snackbars; call the same destination resolution (extract `Widget pageForGate(...)` if needed to avoid duplicating switch).

Déconnexion on O06 / EXPIRED:

```dart
await ref.read(signOutProvider)();
Navigator.of(context).pushAndRemoveUntil(
  MaterialPageRoute(builder: (_) => const WelcomePage()),
  (route) => false,
);
```

- [ ] **Step 4: Tests PASS**

- [ ] **Step 5: Commit**

```bash
git add lib/features/profile/presentation test/features/profile/presentation
git commit -m "feat(profile): O06, mur EXPIRED et navigateAfterAuth"
```

---

### Task 4: Brancher Splash / Login / OTP / A08 / deep link

**Files:**
- Modify: `lib/features/onboarding/presentation/splash/splash_page.dart`
- Modify: `lib/features/auth/presentation/login/login_page.dart`
- Modify: `lib/features/auth/presentation/otp/otp_page.dart`
- Modify: `lib/features/auth/presentation/reset_password/reset_password_page.dart`
- Modify: `lib/features/auth/presentation/deep_link/auth_deep_link_listener.dart`
- Adjust tests that assumed hard SessionStub after login/OTP if they break

**Interfaces:**
- Consumes: `navigateAfterAuth`
- Deep link OAuth success: resolve gate then navigate (not raw SessionStub)
- Password recovery: keep `ResetPasswordPage` first ; A08 success → `navigateAfterAuth`

- [ ] **Step 1: Identify failing widget tests**

Run: `flutter test test/features/auth test/features/onboarding`  
Note failures related to SessionStub assumptions.

- [ ] **Step 2: Replace navigations**

Login listen:

```dart
if (next.succeeded && previous?.succeeded != true) {
  await navigateAfterAuth(ref, context, email: next.email.trim());
}
```

OTP / ResetPassword: same pattern with `widget.email` / state email.

Splash `_resolveNextPage`: if session != null, cannot return Widget sync easily if gate is async - change `_route` to:

```dart
final session = ref.read(authRepositoryProvider).currentSession;
if (session != null) {
  await hold;
  if (!mounted) return;
  await navigateAfterAuth(ref, context, email: session.email);
  return;
}
// existing intro / welcome path after hold
```

AuthDeepLinkListener `AuthDeepLinkOauthSession`: call shared resolve + navigate via `rootNavigatorKey` (extract `navigateAfterAuthWithNav` or pass `NavigatorState`).

- [ ] **Step 3: Fix / update tests with `ProfileGateRepository` override**

```dart
class FakeProfileGateRepository implements ProfileGateRepository {
  FakeProfileGateRepository(this.snapshot);
  final MemberGateSnapshot snapshot;
  @override
  Future<Result<MemberGateSnapshot>> fetchGate() async => Ok(snapshot);
}
```

Default test override: `onboardingCompleted: true` → SessionStub (preserve old expectations) **or** update expectations to OnboardingFlowPage when false.

- [ ] **Step 4: `flutter test` auth + onboarding + profile → PASS**

- [ ] **Step 5: Commit**

```bash
git add lib/features/auth lib/features/onboarding/presentation/splash test
git commit -m "feat(auth): brancher navigateAfterAuth sur les entrées session"
```

---

### Task 5: « Revenir plus tard » sur O01-O05

**Files:**
- Modify: `lib/features/onboarding/presentation/profile_onboarding/onboarding_flow_page.dart`
- Test: `test/features/onboarding/presentation/profile_onboarding/onboarding_flow_page_test.dart` (create if missing)

**Interfaces:**
- Consumes: `authRepositoryProvider.currentSession?.email`
- Does **not** call `navigateAfterAuth` / `fetchGate`

- [ ] **Step 1: Write failing widget test**

```dart
testWidgets('shows Revenir plus tard and opens SessionStub without completing',
    (tester) async {
  // pump OnboardingFlowPage with ProviderScope
  expect(find.text('Revenir plus tard'), findsOneWidget);
  await tester.tap(find.text('Revenir plus tard'));
  await tester.pumpAndSettle();
  expect(find.byType(SessionStubPage), findsOneWidget);
  // provider state: completedLocally still false
});
```

- [ ] **Step 2: Run → FAIL**

- [ ] **Step 3: Add secondary link under primary CTA**

```dart
Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    AppButton(
      label: state.isLastStep ? 'Soumettre' : 'Suivant',
      onPressed: () { /* existing */ },
    ),
    const SizedBox(height: AppSpacing.sm),
    TextButton(
      onPressed: () {
        final email =
            ref.read(authRepositoryProvider).currentSession?.email ?? '';
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => SessionStubPage(email: email),
          ),
          (route) => false,
        );
      },
      child: Text(
        'Revenir plus tard',
        style: context.typography.bodyMedium.copyWith(
          color: colors.primary,
        ),
      ),
    ),
  ],
)
```

Import auth providers + SessionStub. No `finishWithoutSubmit`.

- [ ] **Step 4: Test PASS**

- [ ] **Step 5: Commit**

```bash
git add lib/features/onboarding/presentation/profile_onboarding test/features/onboarding
git commit -m "feat(onboarding): CTA Revenir plus tard vers SessionStub"
```

---

### Task 6: Analyze + full test + MR

- [ ] **Step 1: Run**

```bash
flutter analyze
flutter test
```

Expected: no issues / all tests passed

- [ ] **Step 2: Manual checklist (with dart-defines)**

- Login compte `onboarding_completed=false` → OnboardingFlow  
- « Revenir plus tard » → SessionStub  
- Kill app, relaunch with session → onboarding again  
- (si possible) suspendu / EXPIRED

- [ ] **Step 3: Push + PR**

```bash
git push -u origin HEAD
gh pr create --title "feat(profile): routage post-login X07 + Revenir plus tard" --body "$(cat <<'EOF'
## Summary
- ResolvePostLoginRoute (suspendu → EXPIRED → onboarding → SessionStub)
- Lecture Supabase profiles + profile_restricted
- CTA Revenir plus tard (sans onboarding_completed)
- O06 + mur EXPIRED minimaux

## Test plan
- [ ] flutter analyze / test
- [ ] Login onboarding incomplet
- [ ] Revenir plus tard puis relogin
- [ ] (staging) suspendu / EXPIRED

Closes #6
EOF
)"
```

---

## Spec coverage check

| Spec item | Task |
|---|---|
| ResolvePostLoginRoute + priorité | 1 |
| Lecture Supabase gate | 2 |
| navigateAfterAuth + O06 + EXPIRED | 3 |
| Splash / Login / OTP / deep link / A08 | 4 |
| Revenir plus tard | 5 |
| Analyze / test / MR | 6 |
| Pas d'écriture onboarding_completed sur skip | 5 (explicit) |
| Shell #7 hors scope | homeStub = SessionStub |
