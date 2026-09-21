# Onboarding API + S02 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Brancher le flow onboarding 3 steps sur Supabase (profil + photo Storage) et afficher le bandeau S02 tant que le profil est incomplet (`Closes #8`, delta D5).

**Architecture:** Clean Architecture feature-first. Domain/data sous `features/onboarding/` pour submit/finish ; complétude pure sous `features/profile/` ; bandeau dans `home/`. Controller Riverpod existant appelle les usecases. Selfie / `verification_requests` hors scope (D5).

**Tech Stack:** Flutter, Riverpod, Equatable, `supabase_flutter`, `Result`/`Failure`, tokens `core/theme`.

**Spec :** `docs/superpowers/specs/2026-09-17-onboarding-api-s02-design.md` (alignée D5)  
**Stack Git :** branche `feat/onboarding-api` depuis `feat/onboarding-ui-redesign` ; PR empilée (`Stacked on #30` · `Closes #8`)

## Global Constraints

- Feature-first, flèches vers l’intérieur ; domain Dart pur (zéro Flutter/Dio/Supabase)
- Tokens only (`context.colors` / `AppSpacing` / `AppRadius`) : jamais de couleur/taille en dur
- `onboarding_completed` ≠ `VERIFIED` : jamais forcer la vérif photo
- « Revenir plus tard » : **aucune** écriture `onboarding_completed`
- Mapping enums DB : `gender` `MALE`/`FEMALE` ; `marital_status` `SINGLE_NO_CHILDREN` / `DIVORCED` / `WIDOWED` (UI `single` → `SINGLE_NO_CHILDREN`)
- Genre UI `other` : si le serveur n’accepte que MALE/FEMALE, renvoyer `ValidationFailure` explicite (pas de mapping silencieux)
- Conventional Commits FR, pas de `Co-Authored-By`, pas de tirets cadratins
- `flutter analyze` propre + `flutter test` verts avant fin de PR

## File map

```
lib/features/onboarding/
  domain/
    entities/onboarding_submit_payload.dart
    repositories/onboarding_repository.dart
    usecases/submit_onboarding.dart
    usecases/finish_without_verification.dart
    mapping/onboarding_db_mapping.dart
  data/
    datasources/onboarding_remote_datasource.dart
    datasources/supabase_onboarding_datasource.dart
    repositories/onboarding_repository_impl.dart
  di/onboarding_providers.dart
  presentation/profile_onboarding/
    onboarding_flow_controller.dart   # branche usecases
    onboarding_flow_state.dart        # isSubmitting / submitError
    onboarding_flow_page.dart         # snackbars réseau

lib/features/profile/
  domain/
    entities/profile_fields_snapshot.dart
    entities/profile_completeness.dart
    repositories/profile_fields_repository.dart
    usecases/compute_profile_completeness.dart
  data/
    datasources/…                    # select champs profil + has_primary_photo
    repositories/profile_fields_repository_impl.dart
  di/profile_providers.dart          # + completeness provider

lib/features/home/presentation/
  widgets/incomplete_profile_banner.dart
  home_shell_page.dart
```

---

### Task 1: Mapping DB + payload domain

**Files:**
- Create: `lib/features/onboarding/domain/mapping/onboarding_db_mapping.dart`
- Create: `lib/features/onboarding/domain/entities/onboarding_submit_payload.dart`
- Test: `test/features/onboarding/domain/mapping/onboarding_db_mapping_test.dart`

**Interfaces:**
- Produces: `OnboardingSubmitPayload.fromDraft(OnboardingDraft)`, `genderToDb`, `maritalToDb`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:agapeo/features/onboarding/domain/mapping/onboarding_db_mapping.dart';
import 'package:agapeo/features/onboarding/presentation/profile_onboarding/onboarding_draft.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps man/woman and marital single', () {
    expect(genderToDb(OnboardingGender.man), 'MALE');
    expect(genderToDb(OnboardingGender.woman), 'FEMALE');
    expect(genderToDb(OnboardingGender.other), isNull);
    expect(maritalToDb(OnboardingMaritalStatus.single), 'SINGLE_NO_CHILDREN');
    expect(maritalToDb(OnboardingMaritalStatus.divorced), 'DIVORCED');
    expect(maritalToDb(OnboardingMaritalStatus.widowed), 'WIDOWED');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/onboarding/domain/mapping/onboarding_db_mapping_test.dart`  
Expected: FAIL (library not found)

- [ ] **Step 3: Write minimal implementation**

```dart
import '../../presentation/profile_onboarding/onboarding_draft.dart';

String? genderToDb(OnboardingGender gender) {
  switch (gender) {
    case OnboardingGender.man:
      return 'MALE';
    case OnboardingGender.woman:
      return 'FEMALE';
    case OnboardingGender.other:
      return null;
  }
}

String maritalToDb(OnboardingMaritalStatus status) {
  switch (status) {
    case OnboardingMaritalStatus.single:
      return 'SINGLE_NO_CHILDREN';
    case OnboardingMaritalStatus.divorced:
      return 'DIVORCED';
    case OnboardingMaritalStatus.widowed:
      return 'WIDOWED';
  }
}

class OnboardingSubmitPayload {
  const OnboardingSubmitPayload({
    required this.genderDb,
    required this.birthDate,
    required this.country,
    required this.faithConfession,
    required this.maritalStatusDb,
    required this.whyMarriage,
    this.profilePhotoPath,
  });

  final String genderDb;
  final DateTime birthDate;
  final String country;
  final String faithConfession;
  final String maritalStatusDb;
  final String whyMarriage;
  final String? profilePhotoPath;

  /// Returns null if draft cannot be mapped (ex. gender other).
  static OnboardingSubmitPayload? tryFromDraft(OnboardingDraft draft) {
    final g = draft.gender;
    final b = draft.birthDate;
    final c = draft.country;
    final m = draft.maritalStatus;
    if (g == null || b == null || c == null || m == null) return null;
    final genderDb = genderToDb(g);
    if (genderDb == null) return null;
    return OnboardingSubmitPayload(
      genderDb: genderDb,
      birthDate: b,
      country: c,
      faithConfession: draft.faithConfession.trim(),
      maritalStatusDb: maritalToDb(m),
      whyMarriage: draft.whyMarriage.trim(),
      profilePhotoPath: draft.profilePhotoPath,
    );
  }
}
```

Note: si le domain ne doit pas importer `presentation/`, **déplacer** `OnboardingDraft` (+ enums) vers `domain/entities/` dans cette tâche (refactor import paths tests + presentation). Préférer ce refactor dès le Step 3 si le linter bloque.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/onboarding/domain/mapping/onboarding_db_mapping_test.dart`  
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/onboarding/domain test/features/onboarding/domain
git commit -m "feat(onboarding): mapping enums DB et payload submit"
```

---

### Task 2: OnboardingRepository + usecases

**Files:**
- Create: `lib/features/onboarding/domain/repositories/onboarding_repository.dart`
- Create: `lib/features/onboarding/domain/usecases/submit_onboarding.dart`
- Create: `lib/features/onboarding/domain/usecases/finish_without_verification.dart`
- Test: `test/features/onboarding/domain/usecases/submit_onboarding_test.dart`
- Test: `test/features/onboarding/domain/usecases/finish_without_verification_test.dart`

**Interfaces:**
- Consumes: `OnboardingSubmitPayload`
- Produces:

```dart
abstract class OnboardingRepository {
  Future<Result<void>> submit(OnboardingSubmitPayload payload);
  Future<Result<void>> finishWithoutVerification(OnboardingSubmitPayload payload);
}
```

- [ ] **Step 1: Failing usecase tests with fake repo**

```dart
class _FakeRepo implements OnboardingRepository {
  final calls = <String>[];
  Result<void> next = const Ok(null);
  @override
  Future<Result<void>> submit(OnboardingSubmitPayload p) async {
    calls.add('submit:${p.profilePhotoPath}');
    return next;
  }
  @override
  Future<Result<void>> finishWithoutVerification(OnboardingSubmitPayload p) async {
    calls.add('finish');
    return next;
  }
}

test('SubmitOnboarding requires photo path and delegates', () async {
  final repo = _FakeRepo();
  final uc = SubmitOnboarding(repo);
  final draft = OnboardingDraft(
    gender: OnboardingGender.woman,
    birthDate: DateTime(1995, 1, 1),
    country: 'France',
    faithConfession: 'Évangélique',
    maritalStatus: OnboardingMaritalStatus.single,
    whyMarriage: 'Alliance',
    profilePhotoPath: '/tmp/a.jpg',
  );
  final r = await uc(draft);
  expect(r, isA<Ok<void>>());
  expect(repo.calls, ['submit:/tmp/a.jpg']);
});

test('SubmitOnboarding fails without photo', () async {
  final uc = SubmitOnboarding(_FakeRepo());
  final draft = OnboardingDraft(
    gender: OnboardingGender.woman,
    birthDate: DateTime(1995, 1, 1),
    country: 'France',
    faithConfession: 'Évangélique',
    maritalStatus: OnboardingMaritalStatus.single,
    whyMarriage: 'Alliance',
  );
  final r = await uc(draft);
  expect(r, isA<Err<void>>());
});

test('FinishWithoutVerification allows missing photo', () async {
  final repo = _FakeRepo();
  final r = await FinishWithoutVerification(repo)(OnboardingDraft(
    gender: OnboardingGender.man,
    birthDate: DateTime(1990, 5, 5),
    country: 'Sénégal',
    faithConfession: 'Catholique',
    maritalStatus: OnboardingMaritalStatus.divorced,
    whyMarriage: 'Famille',
  ));
  expect(r, isA<Ok<void>>());
  expect(repo.calls, ['finish']);
});
```

- [ ] **Step 2: Run tests (expect FAIL)**

Run: `flutter test test/features/onboarding/domain/usecases/`

- [ ] **Step 3: Implement usecases**

```dart
class SubmitOnboarding {
  const SubmitOnboarding(this._repo);
  final OnboardingRepository _repo;
  Future<Result<void>> call(OnboardingDraft draft) async {
    final payload = OnboardingSubmitPayload.tryFromDraft(draft);
    if (payload == null) {
      return const Err(ValidationFailure('Profil incomplet ou genre non supporté.'));
    }
    if (payload.profilePhotoPath == null || payload.profilePhotoPath!.isEmpty) {
      return const Err(ValidationFailure('Ajoute une photo pour terminer.'));
    }
    return _repo.submit(payload);
  }
}

class FinishWithoutVerification {
  const FinishWithoutVerification(this._repo);
  final OnboardingRepository _repo;
  Future<Result<void>> call(OnboardingDraft draft) async {
    final payload = OnboardingSubmitPayload.tryFromDraft(draft);
    if (payload == null) {
      return const Err(ValidationFailure('Profil incomplet ou genre non supporté.'));
    }
    return _repo.finishWithoutVerification(payload);
  }
}
```

- [ ] **Step 4: Tests PASS**

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(onboarding): usecases submit et finish without verification"
```

---

### Task 3: Supabase datasource + repository impl

**Files:**
- Create: `lib/features/onboarding/data/datasources/onboarding_remote_datasource.dart`
- Create: `lib/features/onboarding/data/datasources/supabase_onboarding_datasource.dart`
- Create: `lib/features/onboarding/data/repositories/onboarding_repository_impl.dart`
- Create: `lib/features/onboarding/di/onboarding_providers.dart`
- Test: `test/features/onboarding/data/repositories/onboarding_repository_impl_test.dart` (fake datasource)

**Interfaces:**
- Consumes: `SupabaseClient`, payload
- Produces: `OnboardingRemoteDataSource` avec :

```dart
abstract class OnboardingRemoteDataSource {
  Future<void> updateProfileFields({
    required String genderDb,
    required DateTime birthDate,
    required String country,
    required String faithConfession,
    required String maritalStatusDb,
    required String whyMarriage,
    required bool onboardingCompleted,
  });
  Future<void> uploadPrimaryPhoto({required String localPath});
}
```

Ordre **submit** : upload photo → update profiles (`onboarding_completed: true`).  
Ordre **finish** : update profiles seulement (`onboarding_completed: true`).

Storage : bucket aligné web (vérifier nom exact dans le code web / docs ; candidat typique `profile-photos` / `avatars`). Chemin : `{uid}/primary_{timestamp}.jpg`. Row `profile_photos` : `is_primary: true`, `moderation_status` selon convention existante (`DRAFT` ou `PENDING`). Si la table exige des colonnes inconnues, lire une row exemple ou le PRD §18 et documenter dans le commit.

Colonnes `profiles` à écrire (noms à confirmer contre le schéma live si besoin) :
- `gender`, `birth_date`, `country`
- confession / dénomination (chercher le nom web : souvent `denomination` ou `faith_confession`)
- `marital_status`
- why marriage (souvent `why_marriage` / `marriage_vision`)
- `onboarding_completed`

Avant d’implémenter le datasource, **Step 0** : sonder une fois (script/`select` authentifié) ou lire le code web pour les noms exacts ; noter les noms réels dans un commentaire du datasource.

Mapping erreurs Postgrest/Storage → `NetworkFailure` / `ServerFailure` / `UnauthorizedFailure` dans l’impl repo (catch + map, comme `ProfileGateRepositoryImpl`).

Provider : miroir `profileGateRepositoryProvider` (stub `_Unconfigured` si dart-defines absents).

- [ ] **Step 1: Fake datasource + repo test (upload then update order)**

- [ ] **Step 2: FAIL puis impl**

- [ ] **Step 3: Commit**

```bash
git commit -m "feat(onboarding): datasource Supabase profil et photo"
```

---

### Task 4: Brancher le controller + page

**Files:**
- Modify: `lib/features/onboarding/presentation/profile_onboarding/onboarding_flow_state.dart`
- Modify: `lib/features/onboarding/presentation/profile_onboarding/onboarding_flow_controller.dart`
- Modify: `lib/features/onboarding/presentation/profile_onboarding/onboarding_flow_page.dart`
- Test: `test/features/onboarding/presentation/profile_onboarding/onboarding_flow_controller_test.dart`
- Test: `test/features/onboarding/presentation/profile_onboarding/onboarding_flow_page_test.dart`

**State add :** `isSubmitting`, `submitError` (String?), clear on new action.

**Controller :**
- Inject usecases via constructeur ou `ref` (si Notifier : lire providers dans les méthodes async)
- `submit()` → `SubmitOnboarding` ; succès → `completedLocally = true` (garder flag pour tests) **et** navigation HomeShell gérée page
- `skipPhoto()` → `FinishWithoutVerification` (plus seulement local)
- `Revenir plus tard` : **ne pas** appeler les usecases

**Page :**
- Sur Err : SnackBar `failure.message` ; rester sur step photo
- Sur Ok : `pushAndRemoveUntil(HomeShell)` (remplacer snackbar « hors ligne »)
- Désactiver CTAs si `isSubmitting`

- [ ] **Step 1: Tests controller avec overrides providers (fake usecases/repo)**

- [ ] **Step 2: Impl + maj tests page (Passer → finish API ; Terminer → submit API)**

- [ ] **Step 3: Commit**

```bash
git commit -m "feat(onboarding): brancher submit et skip sur Supabase"
```

---

### Task 5: ProfileCompleteness + lecture champs

**Files:**
- Create: `lib/features/profile/domain/entities/profile_fields_snapshot.dart`
- Create: `lib/features/profile/domain/entities/profile_completeness.dart`
- Create: `lib/features/profile/domain/usecases/compute_profile_completeness.dart`
- Create: `lib/features/profile/domain/repositories/profile_fields_repository.dart`
- Create: data datasource/repo + providers
- Test: `test/features/profile/domain/usecases/compute_profile_completeness_test.dart`

**Interfaces:**

```dart
class ProfileFieldsSnapshot extends Equatable {
  const ProfileFieldsSnapshot({
    required this.hasGender,
    required this.hasBirthDate,
    required this.hasCountry,
    required this.hasPrimaryPhoto,
    required this.hasFaithConfession,
    required this.hasWhyMarriage,
  });
  // bools…
}

class ProfileCompleteness extends Equatable {
  const ProfileCompleteness({required this.isComplete, required this.missingKeys});
  final bool isComplete;
  final List<String> missingKeys; // 'photo' | 'confession' | 'whyMarriage' | 'gender' | 'birthDate' | 'country'
}

class ComputeProfileCompleteness {
  const ComputeProfileCompleteness();
  ProfileCompleteness call(ProfileFieldsSnapshot s) { /* pure */ }
}
```

Libellés S02 (présentation) :
- `photo` → Photos
- `confession` → Confession
- `whyMarriage` → Pourquoi le mariage
- `gender` / `birthDate` / `country` → Essentiels (grouper ou lister)

Select datasource : champs profil + existence photo primaire (`profile_photos` where `is_primary` ou `storage_path` non null).

Provider async : `FutureProvider<ProfileCompleteness>` ou `Notifier` qui refetch au resume shell.

- [ ] **Step 1–5: TDD pure completeness, puis data, commit**

```bash
git commit -m "feat(profile): calcul complétude pour bandeau S02"
```

---

### Task 6: Bandeau S02 dans HomeShell

**Files:**
- Create: `lib/features/home/presentation/widgets/incomplete_profile_banner.dart`
- Modify: `lib/features/home/presentation/home_shell_page.dart`
- Test: `test/features/home/presentation/widgets/incomplete_profile_banner_test.dart`
- Test: `test/features/home/presentation/home_shell_page_test.dart`

**UI :**
- Si `!isComplete` : bandeau au-dessus de l’`IndexedStack` (tous onglets)
- Titre « Profil incomplet » ; sous-texte jusqu’à 4 libellés ; CTA « Compléter » → `Navigator.push(OnboardingFlowPage)`
- Tokens only ; pas de card lourde

- [ ] **Step 1: Widget test visible / hidden / tap**

- [ ] **Step 2: Impl + wire shell**

- [ ] **Step 3: Commit**

```bash
git commit -m "feat(home): bandeau S02 profil incomplet"
```

---

### Task 7: Verrouillage essentials (reprise)

**Files:**
- Modify essentials step + controller : si snapshot serveur a genre/DOB/pays non null, champs read-only
- Test: smoke read-only

Hydrater le draft depuis `ProfileFieldsSnapshot` (ou un `fetchOnboardingDraft`) au `build()` du controller si session présente.

- [ ] Commit: `feat(onboarding): verrouiller essentials deja en base`

---

### Task 8: Analyze, tests, PR

- [ ] `flutter analyze` + `flutter test`
- [ ] Push `feat/onboarding-api`
- [ ] `gh pr create` base = `feat/onboarding-ui-redesign` (ou `main` si #30 mergée)

Body :

```markdown
## Summary
- Persistance Supabase onboarding 3 steps (submit photo / finish without photo)
- Bandeau S02 + ProfileCompleteness
- Stacked on #30 · Closes #8 (delta D5 : selfie hors scope)

## Test plan
- [ ] Terminer avec photo → Storage + profiles + home
- [ ] Passer → onboarding_completed, bandeau S02
- [ ] Revenir plus tard → pas d’écriture completed
- [ ] Shell : bandeau si incomplet ; disparait si complet
- [ ] analyze + test verts
```

---

## Spec coverage (self-review)

| Spec | Task |
|---|---|
| Submit avec photo, pas VERIFIED | 2–4 |
| Passer / finish without verification | 2–4 |
| Revenir plus tard sans write | 4 (explicit) |
| S02 bandeau | 5–6 |
| Verrouillage essentials | 7 |
| Failures / unconfigured Supabase | 3 |
| D5 pas de selfie | Global + hors scope |

## Execution handoff

Plan prêt. Options :
1. **SDD** (subagent-driven-development) tâche par tâche dans cette session
2. **executing-plans** avec checkpoints

Dis laquelle tu veux.
