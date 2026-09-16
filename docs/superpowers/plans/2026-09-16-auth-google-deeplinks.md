# Auth Google + deep links + A08 (MR2) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Brancher Google OAuth réel, deep links iOS/Android, et l’écran A08 nouveau mot de passe (issue #5 MR2).

**Architecture:** Extension Clean Arch `auth/` + listener `app_links` + URLs `DeepLinkUrls`. Session via `supabase_flutter` ; succès → `SessionStubPage`. Ops host/consoles documentés hors app.

**Tech Stack:** Flutter, Riverpod, Equatable, `supabase_flutter`, `app_links`, `flutter_test`.

## Global Constraints

- Pas de tiret cadratin / demi-cadratin dans code, docs, commits.
- Tokens design system uniquement (pas de couleurs en dur).
- Domain Dart pur (zéro Flutter / Supabase).
- Après succès Google / A08 → stub session (#6 hors scope).
- Paths : `https://www.agapeo.love/auth/callback` et `…/auth/reset`.
- Conventional Commits ; branche `feat/auth-google-deeplinks`.
- Spec : `docs/superpowers/specs/2026-09-16-auth-google-deeplinks-design.md`.

---

## File map

| File | Role |
|---|---|
| `lib/core/config/deep_link_urls.dart` | URLs callback / reset |
| `lib/features/auth/domain/repositories/auth_repository.dart` | + `signInWithGoogle`, `updatePassword`, `handleAuthDeepLink` |
| `lib/features/auth/domain/usecases/sign_in_with_google.dart` | Use case |
| `lib/features/auth/domain/usecases/update_password.dart` | Use case A08 |
| `lib/features/auth/data/datasources/auth_remote_datasource.dart` | Interface étendue |
| `lib/features/auth/data/datasources/supabase_auth_datasource.dart` | OAuth, session URL, updateUser, redirectTo reset |
| `lib/features/auth/data/repositories/auth_repository_impl.dart` | Mapping |
| `lib/features/auth/di/auth_providers.dart` | Providers + fakes |
| `lib/features/auth/presentation/widgets/google_sign_in_button.dart` | Retirer stub snackbar helper si inutilisé |
| `lib/features/auth/presentation/google/google_sign_in_controller.dart` | Notifier partagé Welcome/Login/Register |
| `lib/features/auth/presentation/reset_password/*` | A08 page / state / controller |
| `lib/features/auth/presentation/deep_link/auth_deep_link_listener.dart` | Widget / binding listener |
| `lib/main.dart` | Wrap listener ; deps |
| `ios/Runner/Runner.entitlements` | Associated Domains |
| `ios/Runner/Info.plist` | si besoin |
| `android/.../AndroidManifest.xml` | App Links intent-filters |
| `pubspec.yaml` | `app_links` |
| tests miroirs | domain / data / presentation |

---

### Task 1: DeepLinkUrls + domain (Google + updatePassword)

**Files:**
- Create: `lib/core/config/deep_link_urls.dart`
- Modify: `auth_repository.dart`
- Create: `sign_in_with_google.dart`, `update_password.dart`
- Test: `test/features/auth/domain/usecases/update_password_test.dart`, `sign_in_with_google_test.dart`
- Modify: `test/helpers/auth_test_fakes.dart`

- [ ] **Step 1: Write failing tests for UpdatePassword and SignInWithGoogle**

```dart
// update_password_test.dart — rejects short password; mismatch on passwordConfirm; delegates when valid
// sign_in_with_google_test.dart — delegates to repo.signInWithGoogle
```

- [ ] **Step 2: Run tests → expect FAIL**

- [ ] **Step 3: Implement DeepLinkUrls, repo methods, use cases, FakeAuthRepository stubs**

```dart
class DeepLinkUrls {
  static const callback = 'https://www.agapeo.love/auth/callback';
  static const reset = 'https://www.agapeo.love/auth/reset';
}
```

`AuthRepository` additions:

```dart
Future<Result<AuthSession>> signInWithGoogle();
Future<Result<AuthSession>> updatePassword({required String password});
/// Returns session if OAuth callback; `Ok(null)` if reset recovery started; Err if fail.
Future<Result<AuthSession?>> handleAuthDeepLink(Uri uri);
```

`UpdatePassword` : validate password + confirm with `AuthValidators.password`, then `_repo.updatePassword`.

- [ ] **Step 4: Run tests → PASS**

- [ ] **Step 5: Commit**

```bash
git add lib/core/config/deep_link_urls.dart lib/features/auth/domain test/features/auth/domain test/helpers/auth_test_fakes.dart
git commit -m "feat(auth): domain Google OAuth et update password"
```

---

### Task 2: Data layer Supabase

**Files:**
- Modify: `auth_remote_datasource.dart`, `supabase_auth_datasource.dart`, `auth_repository_impl.dart`
- Test: extend `auth_repository_impl_test.dart` with fake remote methods

- [ ] **Step 1: Failing tests** mapping `signInWithGoogle` / `updatePassword` / `handleAuthDeepLink` success + AuthException

- [ ] **Step 2: Implement**

`signInWithGoogle`:

```dart
await _client.auth.signInWithOAuth(
  OAuthProvider.google,
  redirectTo: DeepLinkUrls.callback,
  authScreenLaunchMode: LaunchMode.externalApplication,
);
// Session arrives via deep link / onAuthStateChange — return current if already set,
// else throw or return pending: prefer handleAuthDeepLink for session completion.
```

Note: `signInWithOAuth` returns `bool` (launched). Design: `signInWithGoogle` launches OAuth and returns `Ok` only when `currentSession` already present after await; otherwise return a dedicated flow where UI waits on `authStateChanges` **or** `handleAuthDeepLink` completes the session.

**Practical choice for this codebase:**  
- `signInWithGoogle` calls `signInWithOAuth` and returns `Ok(currentSession)` if session appears quickly; else `Ok` with listening left to deep link + `authStateChanges` in the controller (controller listens until session or timeout/cancel).  
- Simpler alternative: repository method launches OAuth (`Result<void>`), controller listens `authStateChanges` for next non-null session. Prefer **`Result<void> signInWithGoogle()`** launch-only + controller listen — update domain from Task 1 if needed to `Result<void>` for launch.

**Lock-in:** Change Task 1 API to:

```dart
Future<Result<void>> signInWithGoogle(); // launches browser
Future<Result<AuthSession>> updatePassword({required String password});
Future<Result<AuthDeepLinkResult>> handleAuthDeepLink(Uri uri);
```

Where `AuthDeepLinkResult` is an enum/entity: `oauthSession(AuthSession)`, `passwordRecovery`, `ignored`.

`requestPasswordReset` must pass `redirectTo: DeepLinkUrls.reset`.

- [ ] **Step 3: Tests PASS**

- [ ] **Step 4: Commit** `feat(auth): data Supabase OAuth, deep link et reset redirect`

---

### Task 3: Native App Links / Universal Links + app_links

**Files:**
- `pubspec.yaml` : `app_links: ^6.x` (latest compatible)
- `AndroidManifest.xml` : intent-filter https host `www.agapeo.love` paths `/auth/callback`, `/auth/reset`
- `ios/Runner/Runner.entitlements` : `applinks:www.agapeo.love`
- Xcode project reference to entitlements if missing
- Create: `lib/features/auth/presentation/deep_link/auth_deep_link_controller.dart` (or core service)

- [ ] **Step 1: Add dependency** `flutter pub add app_links`

- [ ] **Step 2: Android intent-filters** (`autoVerify=true`)

- [ ] **Step 3: iOS Associated Domains entitlements**

- [ ] **Step 4: Unit test pure router** `AuthDeepLinkRouter.resolve(Uri) → enum` (no platform)

- [ ] **Step 5: Commit** `feat(auth): app_links et configuration native deep links`

---

### Task 4: A08 Reset password UI + controller

**Files:**
- Create: `reset_password_state.dart`, `reset_password_controller.dart`, `reset_password_page.dart`
- Tests: controller + page smoke

- [ ] **Step 1: Failing controller tests** (validation, success → succeeded, expired error)

- [ ] **Step 2: Implement page Datify-style** (comme Login)

- [ ] **Step 3: Tests PASS**

- [ ] **Step 4: Commit** `feat(auth): écran A08 nouveau mot de passe`

---

### Task 5: Wire Google + deep link listener in UI

**Files:**
- `google_sign_in_controller.dart` (autoDispose)
- Update Welcome / Login / Registration
- Remove `showGoogleComingSoon`
- `AuthDeepLinkListener` wrapping `MaterialApp` home or above navigator
- Splash: if initial link is reset → A08 after min duration; if session from callback → stub
- Update `request_password_reset` already uses repo with redirectTo
- Update tests (no « bientôt »)

- [ ] **Step 1: Failing widget tests** Google no longer shows coming soon; deep link routing smoke with fake

- [ ] **Step 2: Implement wiring**

- [ ] **Step 3: `flutter analyze` + `flutter test` PASS**

- [ ] **Step 4: Commit** `feat(auth): brancher Google OAuth et listener deep links`

---

### Task 6: Finalisation

- [ ] **Step 1:** Mettre à jour `docs/superpowers/specs/2026-09-16-auth-email-otp-design.md` ligne MR2 → pointer vers spec MR2 (optionnel 1 ligne)

- [ ] **Step 2:** `flutter analyze` + `flutter test`

- [ ] **Step 3:** Commit docs si besoin ; push ; ouvrir / mettre à jour PR

```bash
git push -u origin HEAD
gh pr create --title "feat(auth): Google OAuth, deep links et A08 (MR2 #5)" --body "..."
```

---

## Manual test plan

Voir checklist dans la spec (ops host + Google console requis pour E2E réel).
