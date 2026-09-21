# Onboarding 3 steps + heroes (D5) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remplacer le flow 5 steps par 3 steps (Essentiels → Foi → Photo skippable) avec heroes illustration et warning skip photo.

**Architecture:** Réutiliser widgets core existants. Adapter draft/validators/controller/flow page. Nouveaux `FaithWhyStep`, `ProfilePhotoStep`, `OnboardingStepHero`. Placeholders SVG brand. Local only.

**Tech Stack:** Flutter, Riverpod, Equatable, `image_picker`, tokens, `flutter_test`.

## Global Constraints

- Pas de tiret cadratin / demi-cadratin.
- Tokens only ; `AppAssets` pour chemins.
- Spec : `docs/superpowers/specs/2026-09-17-onboarding-3steps-heroes-design.md` + D5.
- Branche : `feat/onboarding-ui-redesign`.
- Local only (pas API). Conventional Commits ; analyze + tests verts.

---

## File map

| File | Role |
|---|---|
| `onboarding_draft.dart` | `profilePhotoPath`, drop selfie/photos multi from validators path |
| `onboarding_flow_state.dart` | `stepCount = 3`, `skippedPhoto` |
| `onboarding_flow_controller.dart` | pick camera/gallery, `skipPhoto()`, `submit()` sur step 2 photo |
| `widgets/onboarding_step_hero.dart` | hero image + title + subtitle |
| `steps/faith_why_step.dart` | confession + marital + whyMarriage |
| `steps/profile_photo_step.dart` | preview + camera/gallery |
| `steps/essentials_step.dart` | wrap with hero |
| `onboarding_flow_page.dart` | 3 pages, footer Passer/Terminer, no Revenir steps 0-1 |
| `app_assets.dart` + `assets/images/onboarding/` + pubspec | 3 hero SVGs |
| Delete unused : `photos_step`, `selfie_step`, `preferences_step` (+ tests) |
| Tests validators + flow + faith + photo |

---

### Task 1: Draft + validators + state (3 steps)

**Files:**
- Modify: `onboarding_draft.dart`, `onboarding_flow_state.dart`
- Modify: `test/.../onboarding_validators_test.dart`

**Interfaces:**
- `OnboardingDraft.profilePhotoPath` (String?) ; keep `photoPaths`/`selfiePath` removed or unused - prefer rename: remove `selfiePath`/`photoPaths` from draft if only profile photo needed; use `profilePhotoPath` + `clearProfilePhoto`
- `OnboardingFlowState.stepCount = 3`, `skippedPhoto` bool
- Validators: step 0 essentials ; step 1 faith+why ; step 2 empty errors (photo optional)

- [ ] **Step 1: Update failing validators tests** for steps 0/1/2 new mapping

```dart
test('step 1 requires confession, marital, whyMarriage', () {
  expect(OnboardingValidators.canGoNext(1, const OnboardingDraft()), isFalse);
  expect(
    OnboardingValidators.canGoNext(
      1,
      const OnboardingDraft(
        faithConfession: 'Protestante',
        maritalStatus: OnboardingMaritalStatus.single,
        whyMarriage: 'Pour bâtir une famille dans la foi.',
      ),
    ),
    isTrue,
  );
});

test('step 2 photo is optional for canGoNext', () {
  expect(OnboardingValidators.canGoNext(2, const OnboardingDraft()), isTrue);
});
```

Remove old photo/selfie/step4 tests.

- [ ] **Step 2: Run - expect FAIL**

Run: `flutter test test/features/onboarding/presentation/profile_onboarding/onboarding_validators_test.dart`

- [ ] **Step 3: Implement draft/state/validators**

`errorsForStep`:
- 0: gender, birthDate, country (unchanged)
- 1: faithConfession, maritalStatus, whyMarriage
- 2: `{}` always

`OnboardingDraft`: replace `selfiePath`/`photoPaths` with `profilePhotoPath` (update Equatable/copyWith). Remove `maxFreePhotos` if unused.

`OnboardingFlowState`: `stepCount = 3`, add `skippedPhoto` (default false) to state + copyWith + props. Deprecate/remove `skippedVerification` or map skip photo → `skippedPhoto` and keep `skippedVerification` false.

- [ ] **Step 4: Run PASS + commit**

```bash
git commit -m "$(cat <<'EOF'
refactor(onboarding): draft et validators pour 3 steps

EOF
)"
```

---

### Task 2: Controller pick + skipPhoto + submit

**Files:**
- Modify: `onboarding_flow_controller.dart`
- Test: `test/.../onboarding_flow_controller_test.dart` (unit with fake picker optional - or test via state after skipPhoto/submit)

**Interfaces:**
- `Future<void> pickProfilePhoto(ImageSource source)`
- `void clearProfilePhoto()`
- `bool submit()` validates step 2 (always ok) then `completedLocally=true`, `skippedPhoto=false`
- `void skipPhoto()` → `completedLocally=true`, `skippedPhoto=true`
- Remove `addPhoto`/`removePhoto`/`captureSelfie`/`clearSelfie`/`finishWithoutSubmit` or replace

- [ ] **Step 1: Write test**

```dart
test('skipPhoto completes with skippedPhoto', () {
  final c = /* read notifier via ProviderContainer */;
  c.skipPhoto();
  final s = container.read(onboardingFlowProvider);
  expect(s.completedLocally, isTrue);
  expect(s.skippedPhoto, isTrue);
});
```

- [ ] **Step 2: Implement controller methods**

```dart
Future<void> pickProfilePhoto(ImageSource source) async {
  final file = await _picker.pickImage(
    source: source,
    preferredCameraDevice: source == ImageSource.camera
        ? CameraDevice.front
        : CameraDevice.rear,
    imageQuality: 85,
  );
  if (file == null) return;
  updateDraft((d) => d.copyWith(profilePhotoPath: file.path));
}

void skipPhoto() {
  state = state.copyWith(
    completedLocally: true,
    skippedPhoto: true,
    fieldErrors: const {},
  );
}

bool submit() {
  // last step = photo optional
  state = state.copyWith(
    completedLocally: true,
    skippedPhoto: false,
    fieldErrors: const {},
  );
  return true;
}
```

Fix `updateDraft` to clear `skippedPhoto`/`completedLocally` appropriately.

- [ ] **Step 3: PASS + commit** `feat(onboarding): controller photo pick et skip`

---

### Task 3: Heroes assets + OnboardingStepHero

**Files:**
- Create: `assets/images/onboarding/hero_essentials.svg` (simple soft shapes, primary tint)
- Create: `hero_faith.svg`, `hero_photo.svg`
- Modify: `app_assets.dart`, `pubspec.yaml` (`assets/images/onboarding/`)
- Create: `widgets/onboarding_step_hero.dart`
- Test: widget smoke finds title

**Interfaces:**
- `OnboardingStepHero({required String asset, required String title, required String subtitle})`
- Height ~160, `AppSvg` or `SvgPicture.asset`, title headline, subtitle secondary

- [ ] Create minimal valid SVGs (circles/hearts soft, no text)
- [ ] Widget + test + commit `feat(onboarding): OnboardingStepHero et placeholders`

---

### Task 4: FaithWhyStep + ProfilePhotoStep + Essentials hero

**Files:**
- Create: `steps/faith_why_step.dart`
- Create: `steps/profile_photo_step.dart`
- Modify: `steps/essentials_step.dart` (add hero at top)
- Delete: `photos_step.dart`, `selfie_step.dart`, `preferences_step.dart` + obsolete tests
- Tests: faith_why + profile_photo smokes

**FaithWhyStep:** hero + AppTextField confession + AppOptionCards marital + AppTextField whyMarriage

**ProfilePhotoStep:** hero + preview (Image.file or placeholder) + AppButton camera + AppButton gallery secondary + clear

- [ ] Implement + tests + commit `feat(onboarding): steps foi et photo profil`

---

### Task 5: Wire OnboardingFlowPage (3 pages, footer)

**Files:**
- Modify: `onboarding_flow_page.dart`
- Modify: `onboarding_flow_page_test.dart` + fix broken step tests

**Behavior:**
- PageView: Essentials, FaithWhy, ProfilePhoto
- Progress uses `stepCount` (3)
- Steps 0-1: only Continuer ; **no** « Revenir plus tard »
- Step 2 (last):
  - If no photo: primary « Terminer » disabled OR primary = Continuer with photo required? Spec: Passer + Terminer when photo present
  - Primary: `Terminer` if `profilePhotoPath != null` else hide or disable ; always show « Passer »
  - Passer → `showDialog` with exact warning copy → Annuler / Continuer sans photo → `skipPhoto()`
  - Terminer → `submit()`
- Listen `completedLocally` → snackbar + pop (message differs if skippedPhoto)
- Optional « Revenir plus tard » only on step 2 (secondary under Passer) per spec « si conservé » - **include** on step 2 only

Dialog copy exact:
`Sans photo, ton profil ne sera pas vérifié ni visible. Tu pourras en ajouter plus tard.`

- [ ] Tests:
  - no Revenir on step 0
  - Passer shows dialog
  - confirm skip → HomeShell / pop completed
- [ ] Commit `feat(onboarding): flow 3 steps footer skip photo`

---

### Task 6: Cleanup tests + analyze + hot smoke docs

**Files:** remove/fix all tests referencing SelfieStep, PhotosStep, ChoiceChip faith, 5 steps
- Run `flutter analyze` + `flutter test`
- Commit `test(onboarding): aligner smokes sur flow 3 steps`

---

## Spec coverage

| Spec | Task |
|---|---|
| stepCount 3 | 1, 5 |
| Faith + why | 1, 4 |
| Photo camera/gallery + skip warning | 2, 4, 5 |
| Heroes | 3, 4 |
| No Revenir steps 1-2 | 5 |
| Delete old steps | 4 |
| Local only | Global |
