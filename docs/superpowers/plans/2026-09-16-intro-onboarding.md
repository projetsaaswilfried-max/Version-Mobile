# Intro onboarding 3 slides Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remplacer l’age gate en tête de flux par un carousel d’intro 3 slides (style Nestle), puis Welcome.

**Architecture:** `IntroStore` (SharedPreferences `agapeo_intro_seen`) + `IntroOnboardingPage` (PageView). Splash route session → stub, introSeen → Welcome, sinon Intro. Age gate conservé mais débranché.

**Tech Stack:** Flutter, Riverpod, SharedPreferences, Equatable si utile, flutter_test.

## Global Constraints

- Spec : `docs/superpowers/specs/2026-09-16-intro-onboarding-design.md`
- Tokens only (`AppButton`, `context.colors` / `typography`, `AppSpacing`, `AppAssets`)
- Pas de tirets cadratins / demi-cadratins
- Pas de Google / O01–O05 / age gate dans le flux
- Copy exacte des 3 slides dans la spec
- Layout A : illustration haute + texte + dots + CTA ; « Passer » en haut

---

### Task 1: IntroStore (domain + data + provider)

**Files:**
- Create: `lib/features/onboarding/domain/repositories/intro_store.dart`
- Create: `lib/features/onboarding/data/datasources/intro_local_datasource.dart`
- Create: `lib/features/onboarding/data/repositories/intro_store_impl.dart`
- Create: `lib/features/onboarding/di/onboarding_providers.dart`
- Modify: `lib/main.dart` (override `introStoreProvider`)
- Test: `test/features/onboarding/data/intro_store_test.dart` (ou fake + unit via prefs mock in-memory)

**Interfaces:**
- Produces: `IntroStore { Future<bool> isSeen(); Future<void> markSeen(); }`
- Produces: `introStoreProvider` (throw UnimplementedError until override)

- [ ] **Step 1:** Interface + datasource clé `agapeo_intro_seen` + impl + provider
- [ ] **Step 2:** Override dans `main` avec les mêmes `SharedPreferences` que l’age gate
- [ ] **Step 3:** Fake `FakeIntroStore` dans `test/helpers/`
- [ ] **Step 4:** Commit `feat(onboarding): IntroStore et flag intro_seen`

---

### Task 2: IntroOnboardingPage (UI)

**Files:**
- Create: `lib/features/onboarding/presentation/intro/intro_onboarding_page.dart`
- Test: `test/features/onboarding/presentation/intro/intro_onboarding_page_test.dart`

**Interfaces:**
- Consumes: `introStoreProvider`, `WelcomePage`
- Produces: page navigable ; Continuer/Passer → `markSeen` + `pushReplacement(WelcomePage)`

- [ ] **Step 1:** Widget test failing (titres, Passer → Welcome)
- [ ] **Step 2:** PageView 3 slides, dots, Suivant / Continuer, Passer
- [ ] **Step 3:** Tests verts
- [ ] **Step 4:** Commit `feat(onboarding): carousel intro 3 slides`

---

### Task 3: Splash hop + régression age gate

**Files:**
- Modify: `lib/features/onboarding/presentation/splash/splash_page.dart`
- Modify: `test/features/onboarding/presentation/splash/splash_page_test.dart`

**Interfaces:**
- Consumes: `introStoreProvider` à la place de `ageGateStoreProvider` pour le hop non-session

- [ ] **Step 1:** Tests splash → Intro / Welcome / stub ; plus d’AgeGate
- [ ] **Step 2:** Implémenter le hop
- [ ] **Step 3:** `flutter test` splash + intro ; analyze
- [ ] **Step 4:** Commit `feat(onboarding): splash route vers intro`

---

## Manual check

- [ ] Premier lancement simulateur : 3 slides → Welcome
- [ ] Relancer app : Splash → Welcome (pas d’intro)
- [ ] Aucun écran 18+
