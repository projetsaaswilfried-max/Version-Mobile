# Feedback AppToast + confirmation déconnexion Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remplacer tous les SnackBar de feedback (succès et erreurs) par `AppToast`, adoucir les messages techniques, et confirmer toute déconnexion via `AppConfirmDialog`.

**Architecture:** Ajouter `userFacingMessage` (core/error) + helper `confirmAndSignOut` (auth presentation). Migrer les call sites `ScaffoldMessenger.showSnackBar` listés dans la spec vers `AppToast.show`. Les erreurs inline formulaire restent inchangées.

**Tech Stack:** Flutter, Riverpod, `AppToast`, `AppConfirmDialog`, `Failure` / `Result`, tests `flutter_test`.

**Spec :** `docs/superpowers/specs/2026-09-21-feedback-toast-signout-design.md`

## Global Constraints

- Conventional Commits FR ; pas de Co-Authored-By ; pas de tiret cadratin / demi-cadratin
- Tokens only ; réutiliser `AppToast` / `AppConfirmDialog` existants
- Erreurs et succès → toast ; inline form errors hors scope
- Textes FR clairs inchangés ; adoucir seulement techniques / anglais / vides
- Copy déco : titre `Se déconnecter ?` ; message `Tu pourras te reconnecter à tout moment.` ; confirm `Déconnexion` ; cancel `Annuler`
- Après Dart : `bash scripts/android_dev.sh restart` (ou ios)
- `flutter analyze` + tests ciblés au vert avant commit de cloture

## File map

```
lib/core/error/user_facing_message.dart          # create
lib/core/widgets/app_toast.dart                  # inchangé (API déjà OK)
lib/features/auth/presentation/sign_out/
  confirm_and_sign_out.dart                      # create
lib/features/profile/presentation/account/
  account_save_feedback.dart                     # SnackBar → AppToast
lib/features/home/presentation/tabs/
  profile_tab_page.dart                          # confirmAndSignOut
lib/features/profile/presentation/suspended/
  suspended_account_page.dart
lib/features/profile/presentation/expired/
  expired_subscription_page.dart
+ tous les call sites SnackBar de la spec

test/core/error/user_facing_message_test.dart
test/features/home/... / suspended / expired     # confirmer dialog
docs/decisions.md                                # D27
```

---

### Task 1: `userFacingMessage`

**Files:**
- Create: `lib/core/error/user_facing_message.dart`
- Test: `test/core/error/user_facing_message_test.dart`

**Interfaces:**
- Produces: `String userFacingMessage(Failure failure)` et `String userFacingMessageFromRaw(String? raw, {Failure? fallbackType})`
- Heuristique `_looksTechnical` : vide, contient `PGRST` / `Postgrest` / `Exception` / `supabase` (case-insensitive), ou message majoritairement ASCII sans accent et avec mots anglais courants (`error`, `failed`, `invalid`, `network`)
- Si technique ou vide : retourner le message défaut du sous-type Failure (`NetworkFailure` → `Pas de connexion internet.`, etc.) ; si seul un String est fourni sans Failure → `Une erreur inattendue est survenue.`
- Si non technique : retourner `failure.message` / raw trimmé tel quel

- [ ] **Step 1: Write failing tests**

```dart
import 'package:agapeo/core/error/failure.dart';
import 'package:agapeo/core/error/user_facing_message.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keeps clear French Failure message', () {
    expect(
      userFacingMessage(const NetworkFailure('Pas de connexion internet.')),
      'Pas de connexion internet.',
    );
    expect(
      userFacingMessage(const ValidationFailure('Mot de passe trop court.')),
      'Mot de passe trop court.',
    );
  });

  test('softens empty and technical messages', () {
    expect(userFacingMessage(const ServerFailure('')), 'Une erreur serveur est survenue.');
    expect(
      userFacingMessage(const ServerFailure('PGRST116: JSON object requested')),
      'Une erreur serveur est survenue.',
    );
    expect(
      userFacingMessageFromRaw('AuthRetryableFetchException: Failed'),
      "Une erreur inattendue est survenue.",
    );
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/error/user_facing_message_test.dart`  
Expected: FAIL (library undefined)

- [ ] **Step 3: Implement**

```dart
import 'failure.dart';

String userFacingMessage(Failure failure) {
  final raw = failure.message.trim();
  if (raw.isEmpty || _looksTechnical(raw)) {
    return _defaultFor(failure);
  }
  return raw;
}

String userFacingMessageFromRaw(String? raw) {
  final value = raw?.trim() ?? '';
  if (value.isEmpty || _looksTechnical(value)) {
    return const UnknownFailure().message;
  }
  return value;
}

String _defaultFor(Failure failure) => switch (failure) {
  NetworkFailure() => const NetworkFailure().message,
  ServerFailure() => const ServerFailure().message,
  UnauthorizedFailure() => const UnauthorizedFailure().message,
  EmailNotConfirmedFailure() => const EmailNotConfirmedFailure().message,
  ValidationFailure() => failure.message.trim().isEmpty
      ? const UnknownFailure().message
      : failure.message,
  CacheFailure() => const CacheFailure().message,
  UnknownFailure() => const UnknownFailure().message,
};

bool _looksTechnical(String raw) {
  final lower = raw.toLowerCase();
  if (lower.contains('pgrst') ||
      lower.contains('postgrest') ||
      lower.contains('supabase') ||
      lower.contains('exception') ||
      lower.contains('stacktrace')) {
    return true;
  }
  const englishHints = ['failed', 'error', 'invalid', 'network request', 'jwt'];
  for (final hint in englishHints) {
    if (lower.contains(hint)) return true;
  }
  return false;
}
```

Note: un message FR contenant le mot « erreur » ne doit PAS être softéné uniquement pour ça. Ajuster : ne matcher `error` / `failed` que si la chaîne n'a **pas** d'accent FR typique (`éèàùçê`) **ou** si un pattern technique ci-dessus matche. Préférer :

```dart
bool _looksTechnical(String raw) {
  final lower = raw.toLowerCase();
  if (RegExp(r'pgrst\d*|postgrest|supabase|exception|stack.?trace', caseSensitive: false)
      .hasMatch(raw)) {
    return true;
  }
  final hasFrenchMark = RegExp(r'[éèêëàâùûôîïç]').hasMatch(lower);
  if (hasFrenchMark) return false;
  return RegExp(r'\b(failed|error|invalid|jwt|unauthorized)\b', caseSensitive: false)
      .hasMatch(raw);
}
```

Ajuster les tests si besoin pour coller à cette heuristique.

- [ ] **Step 4: Run tests PASS**

Run: `flutter test test/core/error/user_facing_message_test.dart`

- [ ] **Step 5: Commit**

```bash
git add lib/core/error/user_facing_message.dart test/core/error/user_facing_message_test.dart
git commit -m "$(cat <<'EOF'
feat(core): helper userFacingMessage pour toasts

EOF
)"
```

---

### Task 2: Migrer `account_save_feedback` + Mon Profil + compte email/mdp

**Files:**
- Modify: `lib/features/profile/presentation/account/account_save_feedback.dart`
- Modify: `lib/features/profile/presentation/my_profile/my_profile_page.dart`
- Modify: `lib/features/profile/presentation/security/change_email_page.dart`
- Modify: `lib/features/profile/presentation/security/change_password_page.dart`
- Modify tests that assert SnackBar for these if any

**Interfaces:**
- Consumes: `AppToast.show(context, message, isError: false)` pour succès
- Produces: plus de `ScaffoldMessenger` dans ces fichiers pour le feedback

- [ ] **Step 1: Update `account_save_feedback.dart`**

```dart
import '../../../../core/widgets/app_toast.dart';
// ...
AppToast.show(context, message, isError: false);
Navigator.of(context).pop();
```

- [ ] **Step 2: Same pattern on my_profile / change_email / change_password**

Succès :
- `Profil enregistré.` → `isError: false`
- `Vérifie ta boîte mail pour confirmer.` → `isError: false`
- `Mot de passe mis à jour.` → `isError: false`

- [ ] **Step 3: Run related tests**

Run: `flutter test test/features/profile/presentation/my_profile/`  
Expected: PASS (assertions texte snackbar → toast text still `find.text` works for Overlay)

Si un test cherche `SnackBar`, le remplacer par `find.text('Profil enregistré.')`.

- [ ] **Step 4: Commit**

```bash
git add lib/features/profile/presentation/account/account_save_feedback.dart \
  lib/features/profile/presentation/my_profile/my_profile_page.dart \
  lib/features/profile/presentation/security/change_email_page.dart \
  lib/features/profile/presentation/security/change_password_page.dart \
  test/features/profile/presentation/my_profile/
git commit -m "$(cat <<'EOF'
feat(profile): feedback compte et Mon Profil via AppToast

EOF
)"
```

---

### Task 3: Migrer auth, gate, onboarding

**Files:**
- Modify: `lib/features/auth/presentation/widgets/google_auth_button.dart`
- Modify: `lib/features/auth/presentation/deep_link/auth_deep_link_listener.dart`
- Modify: `lib/features/profile/presentation/navigation/navigate_after_auth.dart`
- Modify: `lib/features/onboarding/presentation/profile_onboarding/onboarding_flow_page.dart`

**Interfaces:**
- Erreurs : `AppToast.show(context, userFacingMessage(failure))` ou `userFacingMessageFromRaw(message)`
- Renommer `_showGateFailureSnackBar` → `_showGateFailureToast`

- [ ] **Step 1: Remplacer chaque `showSnackBar` d'erreur par AppToast + userFacingMessage**

Exemple gate :

```dart
void _showGateFailureToast(BuildContext context, Failure failure) {
  AppToast.show(context, userFacingMessage(failure));
}
```

Onboarding submitError / message → `userFacingMessageFromRaw` si String, sinon Failure.

- [ ] **Step 2: Run**

Run: `flutter test test/features/auth/ test/features/onboarding/presentation/` (sous-ensemble existant si trop long)  
Expected: PASS ; corriger asserts SnackBar

- [ ] **Step 3: Commit**

```bash
git commit -m "$(cat <<'EOF'
feat(auth): erreurs gate, Google et onboarding via AppToast

EOF
)"
```

(Ajouter les fichiers touchés au `git add`.)

---

### Task 4: Migrer Fil, Découvrir, Messages, Safety

**Files:**
- Modify: `lib/features/feed/presentation/feed_body.dart`
- Modify: `lib/features/feed/presentation/widgets/feed_comments_sheet.dart`
- Modify: `lib/features/feed/presentation/pages/post_detail_page.dart`
- Modify: `lib/features/feed/presentation/widgets/feed_post_card.dart`
- Modify: `lib/features/discover/presentation/discover_body.dart`
- Modify: `lib/features/discover/presentation/search/discover_search_page.dart`
- Modify: `lib/features/discover/presentation/widgets/discover_invite_sheet.dart`
- Modify: `lib/features/messages/presentation/thread/conversation_thread_page.dart`
- Modify: `lib/features/safety/presentation/widgets/profile_safety_sheet.dart`
- Modify: `lib/features/safety/presentation/widgets/report_sheet.dart`

**Interfaces:**
- Succès / bientôt : `AppToast.show(..., isError: false)` (bientôt = info, pas erreur)
- Erreurs : `isError: true` (défaut) + `userFacingMessage` / `userFacingMessageFromRaw`
- Dans `discover_invite_sheet` : retirer `hideCurrentSnackBar` / messenger ; toast unique géré par `AppToast`

- [ ] **Step 1: Migrer chaque call site**

Règle « bientôt » : `isError: false` (ex. `Vérification du profil : bientôt`, `Média : bientôt`).

Block error fallback déjà FR : passer par `userFacingMessage(failure)` (garde le FR custom si présent).

- [ ] **Step 2: Grep residual**

Run: `rg "showSnackBar|SnackBar\\(" lib/`  
Expected: plus aucun usage de feedback SnackBar (hors commentaires éventuels)

- [ ] **Step 3: Run smoke tests feed/discover/messages si présents**

Run: `flutter test test/features/feed/ test/features/discover/ test/features/messages/ test/features/safety/ 2>/dev/null | tail -20`  
Corriger les asserts SnackBar.

- [ ] **Step 4: Commit**

```bash
git commit -m "$(cat <<'EOF'
feat(ux): migrer feedback Fil Découvrir Messages Safety vers AppToast

EOF
)"
```

---

### Task 5: `confirmAndSignOut` + 3 pages + tests

**Files:**
- Create: `lib/features/auth/presentation/sign_out/confirm_and_sign_out.dart`
- Modify: `lib/features/home/presentation/tabs/profile_tab_page.dart`
- Modify: `lib/features/profile/presentation/suspended/suspended_account_page.dart`
- Modify: `lib/features/profile/presentation/expired/expired_subscription_page.dart`
- Modify: `test/features/home/presentation/home_shell_page_test.dart`
- Modify: `test/features/profile/presentation/suspended/suspended_account_page_test.dart`
- Modify: `test/features/profile/presentation/expired/expired_subscription_page_test.dart`
- Modify: `test/features/auth/presentation/auth_controllers_auto_dispose_test.dart` (si tap Déconnexion)

**Interfaces:**
- Produces:

```dart
Future<void> confirmAndSignOut(BuildContext context, WidgetRef ref) async {
  final confirmed = await AppConfirmDialog.show(
    context,
    title: 'Se déconnecter ?',
    message: 'Tu pourras te reconnecter à tout moment.',
    confirmLabel: 'Déconnexion',
  );
  if (confirmed != true || !context.mounted) return;
  final result = await ref.read(signOutProvider)();
  if (!context.mounted) return;
  switch (result) {
    case Ok<void>():
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const WelcomePage()),
        (_) => false,
      );
    case Err<void>(:final failure):
      AppToast.show(context, userFacingMessage(failure));
  }
}
```

- [ ] **Step 1: Update failing tests d'abord**

Dans `home_shell_page_test`, `suspended_account_page_test`, `expired_subscription_page_test` :

```dart
await tester.tap(find.text('Déconnexion'));
await tester.pumpAndSettle();
expect(find.text('Se déconnecter ?'), findsOneWidget);
// Annuler ne déconnecte pas (test dédié optionnel)
await tester.tap(find.widgetWithText(AppButton, 'Déconnexion').last);
// ou: find.text('Déconnexion') après le dialog - préférer le bouton confirm du sheet
await tester.pumpAndSettle();
expect(find.byType(WelcomePage), findsOneWidget);
```

Ajouter un test court « Annuler garde la session » sur suspended : tap Déconnexion → tap Annuler → toujours `SuspendedAccountPage`.

- [ ] **Step 2: Run tests FAIL (pas de dialog)**

Run: `flutter test test/features/profile/presentation/suspended/suspended_account_page_test.dart`  
Expected: FAIL on `Se déconnecter ?`

- [ ] **Step 3: Implement helper + wire 3 pages**

Remplacer `_signOut` local par `onPressed: () => confirmAndSignOut(context, ref)`.

- [ ] **Step 4: Run PASS**

Run:

```bash
flutter test \
  test/features/home/presentation/home_shell_page_test.dart \
  test/features/profile/presentation/suspended/ \
  test/features/profile/presentation/expired/ \
  test/features/auth/presentation/auth_controllers_auto_dispose_test.dart
```

- [ ] **Step 5: Commit**

```bash
git commit -m "$(cat <<'EOF'
feat(auth): confirmation AppConfirmDialog avant déconnexion

EOF
)"
```

---

### Task 6: Docs D27 + verify + restart

**Files:**
- Modify: `docs/decisions.md` (append D27 après D26)

- [ ] **Step 1: Append D27**

```markdown
### D27 - Feedback transient AppToast + confirmation déconnexion
*2026-09-21 · réf. spec `2026-09-21-feedback-toast-signout-design.md`*

Succès et erreurs transientes passent par `AppToast` (plus de SnackBar Material
pour ce feedback). Messages techniques adoucis via `userFacingMessage`.
Toute déconnexion (hub, suspendu, abo expiré) passe par `AppConfirmDialog`.
```

- [ ] **Step 2: Grep final + analyze + tests**

```bash
rg "showSnackBar|SnackBar\\(" lib/ --glob '*.dart'
flutter analyze lib/core/error lib/core/widgets/app_toast.dart \
  lib/features/auth/presentation/sign_out \
  lib/features/profile/presentation/account \
  lib/features/home/presentation/tabs/profile_tab_page.dart
flutter test test/core/error/user_facing_message_test.dart \
  test/features/profile/presentation/my_profile/ \
  test/features/profile/presentation/suspended/ \
  test/features/profile/presentation/expired/ \
  test/features/home/presentation/home_shell_page_test.dart
```

Expected: 0 SnackBar feedback ; analyze clean ; tests PASS

- [ ] **Step 3: Restart session**

```bash
bash scripts/android_dev.sh restart || bash scripts/android_dev.sh start
```

- [ ] **Step 4: Commit docs**

```bash
git add docs/decisions.md
git commit -m "$(cat <<'EOF'
docs(core): D27 AppToast feedback et confirmation déconnexion

EOF
)"
```

---

## Spec coverage check

| Spec item | Task |
|---|---|
| AppToast erreurs + succès | 2–4 |
| userFacingMessage | 1 |
| Migration call sites listés | 2–4 |
| Inline form hors scope | (explicite) |
| confirm déco hub/suspendu/expiré | 5 |
| Copy confirm | 5 |
| Tests message + déco | 1, 5 |
| D27 | 6 |
