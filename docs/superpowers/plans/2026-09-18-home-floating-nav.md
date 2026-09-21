# Capsule flottante S01 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remplacer le `NavigationBar` collé par une capsule flottante inset, 4 onglets D4 inchangés, le fil passant derrière.

**Architecture:** `HomeFloatingNavBar` en overlay dans un `Stack` du body du shell (pas `bottomNavigationBar`). `HomeTab` porte `label` + `iconAsset`. Inset bas des listes via `HomeFloatingNavBar.scrollClearance`.

**Tech Stack:** Flutter, Riverpod, tokens `AppSpacing` / `AppColors` / `AppShadows` / `AppRadius`, `BackdropFilter`.

## Global Constraints

- 4 onglets Fil / Découvrir / Messages / Profil, labels toujours visibles
- Tokens uniquement, pas de couleur en dur hors `withValues(alpha:)`
- Pas de `NavigationBar` Material
- Fond `surface` 0.82 + blur sigma 16
- Pas de commit sauf demande explicite

---

### Task 1: Tests shell (RED)

**Files:**
- Modify: `test/features/home/presentation/home_shell_page_test.dart`
- Test: same

**Interfaces:**
- Produces: attentes `HomeFloatingNavBar`, 0 `NavigationBar` / `NavigationDestination`, 4 labels, sémantique selected

- [ ] Remplacer `NavigationDestination` par `HomeFloatingNavBar` + absence de `NavigationBar`
- [ ] Lancer les tests shell : FAIL (type inconnu / 0 widgets)

### Task 2: Widget nav + enum + shell (GREEN)

**Files:**
- Modify: `lib/features/home/presentation/home_tab.dart`
- Create: `lib/features/home/presentation/widgets/home_floating_nav_bar.dart`
- Modify: `lib/features/home/presentation/home_shell_page.dart`

**Interfaces:**
- Produces: `HomeTab.label`, `HomeTab.iconAsset`, `HomeFloatingNavBar({selectedIndex, onSelect})`, `HomeFloatingNavBar.scrollClearance(BuildContext)`

- [ ] Enum + capsule stadium + overlay Stack
- [ ] Tests shell verts

### Task 3: Inset listes

**Files:**
- Modify: `lib/features/feed/presentation/feed_body.dart`
- Modify: `lib/features/home/presentation/tabs/profile_tab_page.dart`
- Modify: `lib/features/home/presentation/tabs/home_tab_placeholder.dart`

- [ ] Padding bas = `scrollClearance` (Fil, Profil, placeholders)
- [ ] Tests home + feed verts, analyze, `ios_dev.sh reload`
