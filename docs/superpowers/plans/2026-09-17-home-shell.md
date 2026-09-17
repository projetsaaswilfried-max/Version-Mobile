# Home shell (S01/S04) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remplacer `SessionStubPage` par un shell 4 onglets (Fil, Découvrir, Messages, Profil) + cloche → stub notifications, empilé sur #28.

**Architecture:** Feature `home/presentation` : `HomeShellPage` (`NavigationBar` + `IndexedStack` + `homeShellIndexProvider`). Routeur `PostLoginDestination.home` et « Revenir plus tard » pointent vers le shell. Suppression du session stub.

**Tech Stack:** Flutter, Riverpod, Equatable (si besoin), `flutter_svg` / `AppSvg`, `flutter_test`.

## Global Constraints

- Pas de tiret cadratin / demi-cadratin dans code, docs, commits.
- Tokens design system uniquement (`context.colors`, `AppSpacing`, `AppButton`, `AppSvg` + `AppAssets`).
- Labels exacts : `Fil`, `Découvrir`, `Messages`, `Profil`, `Continuer l'onboarding`, `Déconnexion`, `Notifications`, `Revenir plus tard` (inchangé).
- Badge cloche : uniquement si count > 0 ; count = 0 → pas de badge.
- Pas de `go_router` ; pas de Navigator imbriqué par tab.
- Branche `feat/home-shell` (déjà créée depuis `feat/post-login-routing`) ; PR **base = `feat/post-login-routing`**, pas `main`.
- Spec : `docs/superpowers/specs/2026-09-17-home-shell-design.md`.
- Conventional Commits ; `flutter analyze` + `flutter test` verts avant PR.
- Stacked on #28 · Closes #7.

---

## File map

| File | Role |
|---|---|
| `lib/features/home/presentation/home_tab.dart` | Enum 4 tabs |
| `lib/features/home/presentation/home_shell_controller.dart` | Notifier index |
| `lib/features/home/presentation/home_shell_page.dart` | Shell UI |
| `lib/features/home/presentation/tabs/feed_tab_page.dart` | Fil + AppBar cloche |
| `lib/features/home/presentation/tabs/discover_tab_page.dart` | Placeholder |
| `lib/features/home/presentation/tabs/messages_tab_page.dart` | Placeholder |
| `lib/features/home/presentation/tabs/profile_tab_page.dart` | Onboarding + logout |
| `lib/features/home/presentation/notifications/notifications_stub_page.dart` | Stub N01 |
| `lib/features/profile/domain/entities/post_login_destination.dart` | `homeStub` → `home` |
| `lib/features/profile/domain/usecases/resolve_post_login_route.dart` | Return `home` |
| `lib/features/profile/presentation/navigation/navigate_after_auth.dart` | `HomeShellPage` |
| `lib/features/onboarding/.../onboarding_flow_page.dart` | Revenir plus tard → shell |
| Delete: `lib/features/auth/presentation/session_stub/*` | Stub retiré |
| Tests : home shell + maj SessionStub → HomeShell | |

---

### Task 1: HomeShell UI + controller (TDD)

**Files:**
- Create: all `lib/features/home/presentation/**` listed above
- Test: `test/features/home/presentation/home_shell_page_test.dart`

**Interfaces:**
- Produces: `HomeShellPage`, `homeShellIndexProvider`, `HomeTab` enum
- Consumes: `AppSvg`, `AppAssets`, `signOutProvider`, `authRepositoryProvider`, `OnboardingFlowPage`, `WelcomePage`

- [ ] **Step 1: Write failing widget tests**

```dart
testWidgets('shows four nav destinations and no fifth', (tester) async {
  await tester.pumpWidget(/* ProviderScope + MaterialApp(home: HomeShellPage()) */);
  expect(find.text('Fil'), findsWidgets);
  expect(find.text('Découvrir'), findsOneWidget);
  expect(find.text('Messages'), findsOneWidget);
  expect(find.text('Profil'), findsOneWidget);
  expect(find.byType(NavigationDestination), findsNWidgets(4));
});

testWidgets('selecting Découvrir shows discover placeholder', ...);
testWidgets('bell opens notifications stub without badge at zero', ...);
testWidgets('profile Continuer l\'onboarding opens OnboardingFlowPage', ...);
testWidgets('profile Déconnexion opens WelcomePage', ...);
```

Use `FakeAuthRepository` with `currentSession` email for profile. Override `authRepositoryProvider`.

- [ ] **Step 2: Run → FAIL (missing HomeShellPage)**

Run: `flutter test test/features/home/presentation/home_shell_page_test.dart`

- [ ] **Step 3: Implement**

```dart
enum HomeTab { feed, discover, messages, profile }

class HomeShellController extends Notifier<int> {
  @override
  int build() => 0;
  void select(int index) => state = index;
}

final homeShellIndexProvider =
    NotifierProvider<HomeShellController, int>(HomeShellController.new);
```

`HomeShellPage`: `Scaffold` with `body: IndexedStack(index: watch, children: [Feed, Discover, Messages, Profile])`, `bottomNavigationBar: NavigationBar(...)`.

`FeedTabPage`: `Scaffold` with `AppBar(title: Text('Fil'), actions: [IconButton(icon: Icon(Icons.notifications_outlined), onPressed: push NotificationsStub)])` - **no Badge** when unread = 0.

`ProfileTabPage`: email from session; buttons as spec; signOut → Welcome with `pushAndRemoveUntil`.

Placeholder body helper: centered title + `Bientôt`.

Icons: `AppSvg(AppAssets.icFeed, size: 24, color: ...)` selected vs unselected via `colors.primary` / `colors.textSecondary`.

- [ ] **Step 4: Tests PASS**

- [ ] **Step 5: Commit**

```bash
git add lib/features/home test/features/home
git commit -m "feat(home): shell 4 onglets, cloche et stub notifications"
```

---

### Task 2: Brancher routeur + Revenir plus tard ; supprimer SessionStub

**Files:**
- Modify: `post_login_destination.dart`, `resolve_post_login_route.dart`, `navigate_after_auth.dart`
- Modify: `onboarding_flow_page.dart`
- Delete: `session_stub_page.dart` (+ test file)
- Modify tests listing `SessionStubPage` / `homeStub` (grep)

**Interfaces:**
- Consumes: `HomeShellPage`
- Produces: `PostLoginDestination.home`

- [ ] **Step 1: Update domain test expectations to `home`**

```dart
test('home otherwise', () {
  expect(resolve(... onboardingCompleted: true ...), PostLoginDestination.home);
});
```

Run domain test → FAIL until rename.

- [ ] **Step 2: Rename enum + usecase return**

`homeStub` → `home` everywhere in lib + tests.

- [ ] **Step 3: Wire navigation**

```dart
PostLoginDestination.home => const HomeShellPage(),
// Err fallback:
Err() => const HomeShellPage(),
```

Revenir plus tard:

```dart
Navigator.of(context).pushAndRemoveUntil(
  MaterialPageRoute(builder: (_) => const HomeShellPage()),
  (route) => false,
);
```

Delete session stub sources and `session_stub_page_test.dart`.

Update:
- `onboarding_flow_page_test` (Revenir plus tard → HomeShell)
- `splash_page_test`, `auth_controllers_auto_dispose_test`
- Comments in `auth_test_fakes.dart`

- [ ] **Step 4: `flutter test` focused suites → PASS**

- [ ] **Step 5: Commit**

```bash
git add -u lib test
git commit -m "feat(home): remplacer SessionStub par HomeShell dans le routeur"
```

---

### Task 3: Analyze + full test + stacked PR

- [ ] **Step 1:**

```bash
flutter analyze
flutter test
```

Expected: clean / all passed

- [ ] **Step 2: Push and open PR onto stack base**

```bash
git push -u origin feat/home-shell
gh pr create --base feat/post-login-routing --title "feat(home): shell 4 onglets + cloche (S01/S04)" --body "$(cat <<'EOF'
## Summary
- HomeShell 4 tabs (Fil, Découvrir, Messages, Profil) + placeholders
- Cloche Fil → stub Notifications (pas de badge à 0)
- Profil : Continuer l'onboarding + Déconnexion
- Remplace SessionStub dans le routeur et Revenir plus tard

## Stack
Stacked on #28 (`feat/post-login-routing`). Retarget to `main` after #28 merges.

## Test plan
- [x] flutter analyze / test
- [ ] Login → shell
- [ ] Revenir plus tard → shell
- [ ] Cloche → stub notifications
- [ ] Déconnexion → Welcome

Closes #7
EOF
)"
```

- [ ] **Step 3: Update #28 body stack table** if needed (link PR #N as item 2)

---

## Spec coverage

| Spec item | Task |
|---|---|
| HomeShell + 4 tabs + IndexedStack | 1 |
| Cloche + stub N01, no badge at 0 | 1 |
| Profil onboarding + logout | 1 |
| home enum + routeur + Revenir plus tard | 2 |
| Delete SessionStub | 2 |
| Stacked PR | 3 |
