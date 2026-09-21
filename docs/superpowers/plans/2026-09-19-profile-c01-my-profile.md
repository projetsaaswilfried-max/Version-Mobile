# Profil C01 Mon Profil Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Écran C01 Mon Profil (photos 2 max, identité « vu », bio, switch déménagement, Enregistrer) depuis le hub.

**Architecture:** `GetMyProfile` / `SaveMyProfile` dans `profile/` (approche B). Pas d'import Discover, pas de gonflement `ProfileFieldsSnapshot`. Hub : `ProfileHubSection.profile` → `MyProfilePage`.

**Tech Stack:** Flutter, Riverpod `Notifier`, Equatable, supabase_flutter, `Result`/`Failure`, tokens, `image_picker`, `AppTextField`, sheet photo onboarding.

**Spec :** `docs/superpowers/specs/2026-09-19-profile-c01-my-profile-design.md`

## Global Constraints

- Branche `feat/profile-c01` empilée sur `feat/profile-c00` ; Conventional Commits FR ; pas de Co-Authored-By
- Tokens only ; pas de tiret cadratin ni demi-cadratin
- Pas d'import `features/discover` ; pas d'extension S02 snapshot
- Photos : max 2 ; `VERIFIED` lecture seule ; sinon add/remove, slot 0 primaire, `DRAFT`
- Bio ≤600 côté UI et domain
- Switch déménagement masqué si colonne absente
- Après save : snackbar, pop, `profileHubControllerProvider.notifier.loadInitial()` + `ref.invalidate(profileFieldsProvider)`
- `flutter analyze` + `flutter test` ; `bash scripts/ios_dev.sh restart` après Dart

## File map

```
lib/features/profile/
  domain/entities/my_profile.dart
  domain/entities/my_profile_photo.dart
  domain/repositories/my_profile_repository.dart
  domain/usecases/get_my_profile.dart
  domain/usecases/save_my_profile.dart
  data/datasources/my_profile_remote_datasource.dart
  data/datasources/supabase_my_profile_datasource.dart
  data/repositories/my_profile_repository_impl.dart
  di/profile_providers.dart
  presentation/my_profile/
    my_profile_page.dart
    my_profile_controller.dart
    my_profile_state.dart
    widgets/my_profile_photo_grid.dart
    widgets/my_profile_form.dart
    widgets/my_profile_skeleton.dart
    widgets/my_profile_error.dart

lib/features/profile/presentation/hub/profile_hub_body.dart
```

Tests miroir + update `profile_hub_body_test` (Mon Profil ne snackbar plus).
Fake : étendre `test/helpers/profile_test_fakes.dart`.

---

### Task 1: Domain MyProfile + Save validation

**Files:**
- Create: `lib/features/profile/domain/entities/my_profile_photo.dart`
- Create: `lib/features/profile/domain/entities/my_profile.dart`
- Create: `lib/features/profile/domain/repositories/my_profile_repository.dart`
- Create: `lib/features/profile/domain/usecases/get_my_profile.dart`
- Create: `lib/features/profile/domain/usecases/save_my_profile.dart`
- Test: `test/features/profile/domain/usecases/save_my_profile_test.dart`

**Interfaces:**
- Produces: `MyProfilePhoto({String? id, String? publicUrl, String? localPath})`
- Produces: `MyProfile` avec `firstName`, `lastName`, `city`, `profession`, `bio`, `willingToRelocate`, `relocateAvailable`, `genderLabel`, `birthDateLabel`, `country`, `isVerified`, `photos`
- Produces: `GetMyProfile.call()` → `Future<Result<MyProfile>>`
- Produces: `SaveMyProfile.call(MyProfile)` → `Future<Result<void>>`
- Bio >600 → `Err(ValidationFailure('La bio ne peut pas dépasser 600 caractères.'))` sans appeler le repo
- Si `isVerified` : passer au repo une copie avec `photos` identiques à celles du **dernier Get** (le usecase reçoit `originalPhotos` OU le repo save ignore photo mutations). Plus simple : `SaveMyProfile` strip : si `profile.isVerified`, `save(profile.copyWith(photos: const []))` ne marche pas (effacerait). Donc : flag `savePhotos` = `!profile.isVerified` passé au repo.

```dart
abstract class MyProfileRepository {
  Future<Result<MyProfile>> fetchMine();
  Future<Result<void>> save(MyProfile profile, {required bool savePhotos});
}

class SaveMyProfile {
  const SaveMyProfile(this._repo);
  final MyProfileRepository _repo;

  static const maxBioLength = 600;

  Future<Result<void>> call(MyProfile profile) async {
    if (profile.bio.trim().length > maxBioLength) {
      return const Err(
        ValidationFailure('La bio ne peut pas dépasser 600 caractères.'),
      );
    }
    return _repo.save(profile, savePhotos: !profile.isVerified);
  }
}
```

- [ ] **Step 1:** Tests failants (bio trop longue ; VERIFIED → `savePhotos: false` ; non vérifié → `true`)
- [ ] **Step 2:** Run FAIL
- [ ] **Step 3:** Entities + usecases + repo interface
- [ ] **Step 4:** Tests PASS
- [ ] **Step 5:** Commit `feat(profile): domain C01 Mon Profil`

---

### Task 2: Data Get / Save + photos + relocate fallback

**Files:**
- Create: `lib/features/profile/data/datasources/my_profile_remote_datasource.dart`
- Create: `lib/features/profile/data/datasources/supabase_my_profile_datasource.dart`
- Create: `lib/features/profile/data/repositories/my_profile_repository_impl.dart`
- Test: `test/features/profile/data/my_profile_repository_impl_test.dart`

**Interfaces:**
- Select profil : `first_name, last_name, gender, birth_date, country, city, profession, bio, photo_verification_status` + tentative colonnes relocate : `willing_to_relocate`, `ready_to_relocate`, `open_to_relocate` (comme Discover `_looksLikeMissingColumn`, retirer la colonne et retry)
- Photos : `profile_photos` `id, storage_path, url, is_primary` order primary first
- URL publique : bucket `profile-photos` (copier `getPublicUrl`, pas d'import discover)
- Save champs : `update` des éditables ; n'inclure relocate que si `relocateAvailable`
- Save photos si `savePhotos` : supprimer les ids absents du draft, upload `localPath` (copie logique onboarding `slot_N.jpg`, `DRAFT`, `is_primary` slot 0)
- Labels locked : `FEMALE` → `Femme`, `MALE` → `Homme`, sinon brut ; date `dd/mm/yyyy`

Fake remote dans le test repo : mapping + `savePhotos` flag.

- [ ] **Step 1:** Tests failants mapping + savePhotos
- [ ] **Step 2:** Run FAIL
- [ ] **Step 3:** Datasource + impl
- [ ] **Step 4:** Tests PASS
- [ ] **Step 5:** Commit `feat(profile): data C01 get et save`

---

### Task 3: Controller, state, providers

**Files:**
- Create: `lib/features/profile/presentation/my_profile/my_profile_state.dart`
- Create: `lib/features/profile/presentation/my_profile/my_profile_controller.dart`
- Modify: `lib/features/profile/di/profile_providers.dart`
- Modify: `test/helpers/profile_test_fakes.dart`
- Test: `test/features/profile/presentation/my_profile/my_profile_controller_test.dart`

**Interfaces:**
- `myProfileRepositoryProvider` + unconfigured `Err`
- `getMyProfileProvider` / `saveMyProfileProvider`
- `myProfileControllerProvider` autoDispose
- State : `profile`, `isInitialLoading`, `isSaving`, `errorMessage`, `saveError`
- `loadInitial` / `retry` / setters champs / `addLocalPhoto` / `removePhotoAt` (no-op si verified) / `save()` → `Result`

`FakeMyProfileRepository` : `fetchResult`, `saveResult`, `lastSavePhotos`.

- [ ] **Step 1:** Tests controller load / save / verified ignore remove
- [ ] **Step 2:** FAIL
- [ ] **Step 3:** Implement
- [ ] **Step 4:** PASS
- [ ] **Step 5:** Commit `feat(profile): controller C01`

---

### Task 4: UI + hub

**Files:**
- Create presentation widgets + `my_profile_page.dart`
- Modify: `profile_hub_body.dart` (`profile` → `MyProfilePage`)
- Modify: `test/features/profile/presentation/hub/profile_hub_body_test.dart`
- Test: `test/features/profile/presentation/my_profile/my_profile_page_test.dart`

**UI:**
- AppBar « Mon Profil » + back
- Skeleton / `Impossible de charger le profil` + Réessayer
- Grille 2 slots : `http` → `AppNetworkImage`, path local → `Image.file`. `VERIFIED` : pas add/remove. Sinon add → **même sheet** que `ProfilePhotoStep` (Caméra / Galerie)
- `AppTextField` prénom, nom, ville, profession, bio (`maxLength: 600`, `maxLines: 5`) + texte compteur `n/600`
- Locked : `typography.bodySmall` sous les champs
- `SwitchListTile` « Prêt à déménager » si `relocateAvailable`
- `AppButton` Enregistrer sticky bas, `isLoading: isSaving`
- Save Ok : snackbar `Profil enregistré.`, pop, hub `loadInitial`, `invalidate(profileFieldsProvider)`

Hub test : tap Mon Profil → `MyProfilePage` (plus `Bientôt`). Override `myProfileRepositoryProvider`.

- [ ] **Step 1:** Widget tests FAIL
- [ ] **Step 2:** Implement UI + wire
- [ ] **Step 3:** PASS
- [ ] **Step 4:** Commit `feat(profile): écran C01 Mon Profil`

---

### Task 5: Analyze, suite, simulateur

- [ ] `flutter analyze`
- [ ] `flutter test`
- [ ] `bash scripts/ios_dev.sh restart`

## Hors plan

- C16, quota 10, Foi/C03, profil public, Premium, EXPIRED
