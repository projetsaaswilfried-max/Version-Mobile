# Profile onboarding UI (O01–O05 local) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans or implement task-by-task. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Livrer le flow onboarding profil en local (UI + Riverpod), entrée depuis le stub, sans API.

**Architecture:** `OnboardingFlowPage` + PageView + `OnboardingDraft` unique autoDispose.

**Tech Stack:** Flutter, Riverpod, Equatable, `image_picker`, `camera` (O03), tokens design system.

## Global Constraints

- Pas d’écriture Supabase / Dio
- Tokens only ; pas de tiret cadratin
- Spec : `docs/superpowers/specs/2026-09-16-profile-onboarding-ui-design.md`
- CTA stub temporaire « Continuer l’onboarding »

---

### Task 1: Draft + validation + controller

- [ ] Create `onboarding_draft.dart`, validators, `onboarding_flow_controller.dart`
- [ ] Tests unit `canGoNext`
- [ ] Commit `feat(onboarding): draft et validation O01–O05`

### Task 2: Flow page + steps UI (O01–O05)

- [ ] `onboarding_flow_page.dart` + 5 steps
- [ ] O02 `image_picker` ; O03 `camera` (fallback message si indispo simu)
- [ ] Wire stub CTA
- [ ] Widget smoke + commit `feat(onboarding): flow profil local depuis le stub`

### Task 3: Verify

- [ ] `flutter analyze` + `flutter test`
- [ ] Push + PR
