# Profil C00 hub Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remplacer le stub de l'onglet Profil par le hub Mon compte (identité + 8 sections PRD §14).

**Architecture:** Feature `profile/` existante. `GetProfileHub` dans `profile/domain` (approche B : aucun import Découvrir). Data = étendre le repo **fields** (select nom / vérif / photo primaire). `ProfileTabPage` = AppBar + body + Déconnexion toujours visible.

**Tech Stack:** Flutter, Riverpod `Notifier`, Equatable, supabase_flutter, `Result`/`Failure`, tokens `core/theme`.

**Spec :** `docs/superpowers/specs/2026-09-19-profile-c00-hub-design.md`

## Global Constraints

- Branche `feat/profile-c00` empilée sur #43 ; Conventional Commits FR ; pas de Co-Authored-By
- Tokens only (`context.colors`, `context.typography`, `AppSpacing`, `AppRadius`) ; pas de tiret cadratin ni demi-cadratin
- Pas d'import `features/discover`
- Hors slice : aperçu profil public réel, C01–C03 / C05–C16, P01, mur EXPIRED, second bandeau S02, `go_router`
- Badge vérifié uniquement si `photo_verification_status == VERIFIED` (case-insensitive)
- Nom affiché = `first_name` + `last_name` trim ; si vide → email de session
- Photo absente → placeholder (pas de crash)
- Snackbar stubs : `Bientôt`
- `flutter analyze` propre + `flutter test` verts
- Session iOS : `bash scripts/ios_dev.sh restart` après Dart (jamais demander un hot reload)

## File map

```
lib/features/profile/
  domain/entities/profile_hub.dart
  domain/entities/profile_hub_section.dart
  domain/usecases/get_profile_hub.dart
  domain/entities/profile_fields_snapshot.dart          # + firstName, lastName, photoVerificationStatus, primaryPhotoUrl
  domain/repositories/profile_fields_repository.dart    # inchangé (fetchFields)
  data/datasources/profile_fields_remote_datasource.dart
  data/datasources/supabase_profile_fields_datasource.dart
  data/repositories/profile_fields_repository_impl.dart
  di/profile_providers.dart                             # getProfileHubProvider
  presentation/hub/
    profile_hub_controller.dart
    profile_hub_state.dart
    profile_hub_body.dart
    widgets/profile_hub_header.dart
    widgets/profile_hub_row.dart
    widgets/profile_hub_skeleton.dart
    widgets/profile_hub_error.dart

lib/features/home/presentation/tabs/profile_tab_page.dart
```

Tests miroir sous `test/features/profile/` + mise à jour `test/features/home/presentation/tabs/profile_tab_page_test.dart`.
Fake : `test/helpers/profile_test_fakes.dart`.

---

### Task 1: Domain hub (mapping nom / badge / photo)

**Files:**
- Create: `lib/features/profile/domain/entities/profile_hub.dart`
- Create: `lib/features/profile/domain/entities/profile_hub_section.dart`
- Create: `lib/features/profile/domain/usecases/get_profile_hub.dart`
- Modify: `lib/features/profile/domain/entities/profile_fields_snapshot.dart`
- Test: `test/features/profile/domain/entities/profile_hub_test.dart`
- Test: `test/features/profile/domain/usecases/get_profile_hub_test.dart`

**Interfaces:**
- Consumes: `ProfileFieldsRepository.fetchFields()` → `Future<Result<ProfileFieldsSnapshot>>`
- Produces: `ProfileHub.fromFields(ProfileFieldsSnapshot fields, {required String fallbackEmail})`
- Produces: `GetProfileHub.call({required String fallbackEmail})` → `Future<Result<ProfileHub>>`
- Produces: `enum ProfileHubSection` + `label` (8 libellés spec)

- [ ] **Step 1: Write the failing domain tests**

`profile_fields_snapshot.dart` : ajouter les champs optionnels (constructeurs existants restent valides) :

```dart
this.firstName,
this.lastName,
this.photoVerificationStatus,
this.primaryPhotoUrl,
```

Les ajouter à `props`.

`test/features/profile/domain/entities/profile_hub_test.dart` :

```dart
import 'package:agapeo/features/profile/domain/entities/profile_fields_snapshot.dart';
import 'package:agapeo/features/profile/domain/entities/profile_hub.dart';
import 'package:agapeo/features/profile/domain/entities/profile_hub_section.dart';
import 'package:flutter_test/flutter_test.dart';

ProfileFieldsSnapshot fields({
  String? firstName,
  String? lastName,
  String? photoVerificationStatus,
  String? primaryPhotoUrl,
}) {
  return ProfileFieldsSnapshot(
    hasGender: true,
    hasBirthDate: true,
    hasCountry: true,
    hasPrimaryPhoto: primaryPhotoUrl != null,
    hasFaithConfession: true,
    hasWhyMarriage: true,
    firstName: firstName,
    lastName: lastName,
    photoVerificationStatus: photoVerificationStatus,
    primaryPhotoUrl: primaryPhotoUrl,
  );
}

void main() {
  test('joins first and last name', () {
    final hub = ProfileHub.fromFields(
      fields(firstName: 'Léa', lastName: 'Martin'),
      fallbackEmail: 'lea@agapeo.love',
    );
    expect(hub.displayName, 'Léa Martin');
    expect(hub.isVerified, isFalse);
    expect(hub.photoUrl, isNull);
  });

  test('falls back to session email when name is blank', () {
    final hub = ProfileHub.fromFields(
      fields(firstName: '  ', lastName: null),
      fallbackEmail: 'lea@agapeo.love',
    );
    expect(hub.displayName, 'lea@agapeo.love');
  });

  test('badge only when VERIFIED', () {
    expect(
      ProfileHub.fromFields(
        fields(photoVerificationStatus: 'verified'),
        fallbackEmail: 'a@b.c',
      ).isVerified,
      isTrue,
    );
    expect(
      ProfileHub.fromFields(
        fields(photoVerificationStatus: 'PENDING'),
        fallbackEmail: 'a@b.c',
      ).isVerified,
      isFalse,
    );
  });

  test('keeps primary photo url or null', () {
    expect(
      ProfileHub.fromFields(
        fields(primaryPhotoUrl: 'https://cdn/p.jpg'),
        fallbackEmail: 'a@b.c',
      ).photoUrl,
      'https://cdn/p.jpg',
    );
    expect(
      ProfileHub.fromFields(fields(), fallbackEmail: 'a@b.c').photoUrl,
      isNull,
    );
  });

  test('exposes the 8 PRD section labels', () {
    expect(ProfileHubSection.values.map((s) => s.label).toList(), [
      'Mon Profil',
      'Ma Foi',
      'Plus d\'infos',
      'Mes Publications',
      'Mes Favoris',
      'Qui s\'intéresse à moi',
      'Confidentialité',
      'Compte & Sécurité',
    ]);
  });
}
```

`test/features/profile/domain/usecases/get_profile_hub_test.dart` : fake repo inline.

```dart
class _Repo implements ProfileFieldsRepository {
  _Repo(this.result);
  final Result<ProfileFieldsSnapshot> result;
  @override
  Future<Result<ProfileFieldsSnapshot>> fetchFields() async => result;
}

void main() {
  test('maps Ok snapshot to ProfileHub', () async {
    final usecase = GetProfileHub(
      _Repo(
        Ok(
          ProfileFieldsSnapshot(
            hasGender: true,
            hasBirthDate: true,
            hasCountry: true,
            hasPrimaryPhoto: false,
            hasFaithConfession: true,
            hasWhyMarriage: true,
            firstName: 'Paul',
            lastName: 'N.',
            photoVerificationStatus: 'VERIFIED',
          ),
        ),
      ),
    );
    final result = await usecase(fallbackEmail: 'paul@agapeo.love');
    final hub = (result as Ok<ProfileHub>).value;
    expect(hub.displayName, 'Paul N.');
    expect(hub.isVerified, isTrue);
  });

  test('forwards Err', () async {
    const failure = NetworkFailure('offline');
    final usecase = GetProfileHub(_Repo(const Err(failure)));
    final result = await usecase(fallbackEmail: 'a@b.c');
    expect((result as Err<ProfileHub>).failure, failure);
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/features/profile/domain/entities/profile_hub_test.dart test/features/profile/domain/usecases/get_profile_hub_test.dart`

Expected: FAIL (library not found / `fromFields` undefined).

- [ ] **Step 3: Minimal implementation**

`ProfileHub` :

```dart
class ProfileHub extends Equatable {
  const ProfileHub({
    required this.displayName,
    required this.isVerified,
    this.photoUrl,
  });

  final String displayName;
  final String? photoUrl;
  final bool isVerified;

  factory ProfileHub.fromFields(
    ProfileFieldsSnapshot fields, {
    required String fallbackEmail,
  }) {
    final parts = [fields.firstName, fields.lastName]
        .map((value) => value?.trim() ?? '')
        .where((value) => value.isNotEmpty)
        .toList();
    final name = parts.join(' ');
    final email = fallbackEmail.trim();
    final url = fields.primaryPhotoUrl?.trim();
    return ProfileHub(
      displayName: name.isNotEmpty ? name : email,
      photoUrl: (url == null || url.isEmpty) ? null : url,
      isVerified:
          (fields.photoVerificationStatus ?? '').toUpperCase() == 'VERIFIED',
    );
  }
}
```

`ProfileHubSection` :

```dart
enum ProfileHubSection {
  profile,
  faith,
  moreInfo,
  posts,
  favorites,
  interested,
  privacy,
  account;

  String get label => switch (this) {
    ProfileHubSection.profile => 'Mon Profil',
    ProfileHubSection.faith => 'Ma Foi',
    ProfileHubSection.moreInfo => 'Plus d\'infos',
    ProfileHubSection.posts => 'Mes Publications',
    ProfileHubSection.favorites => 'Mes Favoris',
    ProfileHubSection.interested => 'Qui s\'intéresse à moi',
    ProfileHubSection.privacy => 'Confidentialité',
    ProfileHubSection.account => 'Compte & Sécurité',
  };
}
```

`GetProfileHub` :

```dart
class GetProfileHub {
  const GetProfileHub(this._repo);
  final ProfileFieldsRepository _repo;

  Future<Result<ProfileHub>> call({required String fallbackEmail}) async {
    final result = await _repo.fetchFields();
    return switch (result) {
      Ok(:final value) => Ok(
        ProfileHub.fromFields(value, fallbackEmail: fallbackEmail),
      ),
      Err(:final failure) => Err(failure),
    };
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/features/profile/domain/entities/profile_hub_test.dart test/features/profile/domain/usecases/get_profile_hub_test.dart test/features/profile/domain/usecases/compute_profile_completeness_test.dart`

Expected: PASS (complétude inchangée).

- [ ] **Step 5: Commit**

```bash
git add lib/features/profile/domain test/features/profile/domain
git commit -m "$(cat <<'EOF'
feat(profile): domain hub C00

EOF
)"
```

---

### Task 2: Data fields (nom, vérif, URL photo)

**Files:**
- Modify: `lib/features/profile/data/datasources/profile_fields_remote_datasource.dart`
- Modify: `lib/features/profile/data/datasources/supabase_profile_fields_datasource.dart`
- Modify: `lib/features/profile/data/repositories/profile_fields_repository_impl.dart`
- Test: `test/features/profile/data/profile_fields_repository_impl_test.dart`

**Interfaces:**
- Consumes: `profiles` select `gender, birth_date, country, church_denomination, why_marriage, first_name, last_name, photo_verification_status`
- Consumes: `profile_photos` select `storage_path, url` where `is_primary = true`
- Produces: record `fetchFieldsRaw` enrichi + mapping repo vers snapshot
- Bucket photos : `profile-photos` (même que Découvrir, **copier** `getPublicUrl` ici, ne pas importer discover)

Étendre le record `fetchFieldsRaw` :

```dart
({
  String? gender,
  String? birthDate,
  String? country,
  String? denomination,
  String? whyMarriage,
  bool hasPrimaryPhoto,
  String? firstName,
  String? lastName,
  String? photoVerificationStatus,
  String? primaryPhotoUrl,
})
```

URL photo dans le datasource :

```dart
String? _primaryPhotoUrl(Map<String, dynamic>? photo) {
  if (photo == null) return null;
  for (final key in ['url', 'public_url', 'storage_path', 'path']) {
    final value = photo[key];
    if (value is String && value.isNotEmpty) {
      return _publicPhotoUrl(value);
    }
  }
  return null;
}

String _publicPhotoUrl(String path) {
  if (path.startsWith('http://') || path.startsWith('https://')) return path;
  return _client.storage.from('profile-photos').getPublicUrl(path);
}
```

Repo : passer `firstName`, `lastName`, `photoVerificationStatus`, `primaryPhotoUrl` au snapshot (trim, vide → null).

- [ ] **Step 1: Write the failing repo test**

Fake remote renvoyant le record étendu. Tester :
1. mapping nom / VERIFIED / URL
2. `hasPrimaryPhoto: true` + URL nulle si photo sans chemin
3. `Err` si le remote throw `NetworkException`

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/profile/data/profile_fields_repository_impl_test.dart`

Expected: FAIL (record incomplet / champs absents).

- [ ] **Step 3: Implement datasource + repo mapping**

Select profil : `'gender, birth_date, country, church_denomination, why_marriage, first_name, last_name, photo_verification_status'`

Select photo : `'storage_path, url'` (garder `eq('is_primary', true).maybeSingle()`).

`_UnconfiguredProfileFieldsRepository` inchangé (toujours `Err`).

- [ ] **Step 4: Run tests**

Run: `flutter test test/features/profile/data/profile_fields_repository_impl_test.dart test/features/profile/domain/`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/profile/data lib/features/profile/domain/entities/profile_fields_snapshot.dart test/features/profile/data
git commit -m "$(cat <<'EOF'
feat(profile): fields nom, vérif et photo

EOF
)"
```

Si le snapshot a déjà été étendu au Task 1, ne pas le re-committer ici s'il est déjà dans HEAD.

---

### Task 3: Controller, state, providers

**Files:**
- Create: `lib/features/profile/presentation/hub/profile_hub_state.dart`
- Create: `lib/features/profile/presentation/hub/profile_hub_controller.dart`
- Modify: `lib/features/profile/di/profile_providers.dart`
- Create: `test/helpers/profile_test_fakes.dart`
- Test: `test/features/profile/presentation/hub/profile_hub_controller_test.dart`

**Interfaces:**
- Consumes: `GetProfileHub` + `authRepositoryProvider.currentSession?.email ?? ''`
- Produces: `profileHubControllerProvider` (`NotifierProvider.autoDispose`)
- Produces: `ProfileHubState` (`hub`, `isInitialLoading`, `isRefreshing`, `errorMessage`) + `copyWith(clearError:)`
- Produces: `loadInitial` / `retry` / `refresh` (même schéma que `MessagesController`)

`getProfileHubProvider` :

```dart
final getProfileHubProvider = Provider<GetProfileHub>((ref) {
  return GetProfileHub(ref.watch(profileFieldsRepositoryProvider));
});
```

Controller `build()` : `Future<void>.microtask(loadInitial)` puis `ProfileHubState(isInitialLoading: true)`.

Email : `ref.read(authRepositoryProvider).currentSession?.email ?? ''`.

Refresh en erreur sans hub précédent : afficher l'erreur. Refresh avec hub déjà chargé : garder le hub, `isRefreshing` seulement (comme Messages).

`FakeProfileFieldsRepository` dans `test/helpers/profile_test_fakes.dart` :

```dart
class FakeProfileFieldsRepository implements ProfileFieldsRepository {
  FakeProfileFieldsRepository({
    this.result = const Err(ServerFailure('unset')),
  });
  Result<ProfileFieldsSnapshot> result;
  int fetchCalls = 0;
  @override
  Future<Result<ProfileFieldsSnapshot>> fetchFields() async {
    fetchCalls++;
    return result;
  }
}
```

Tests controller (ProviderContainer) :
1. load Ok → `hub.displayName` + `!isInitialLoading`
2. load Err → `errorMessage` non null, `hub == null`
3. retry après Err → second `fetchCalls`, hub rempli

- [ ] **Step 1: Write failing controller tests**
- [ ] **Step 2: Run to verify FAIL**
- [ ] **Step 3: Implement state / controller / providers**
- [ ] **Step 4: Run to verify PASS**
- [ ] **Step 5: Commit** `feat(profile): controller hub C00`

---

### Task 4: UI hub + wire tab

**Files:**
- Create: `lib/features/profile/presentation/hub/profile_hub_body.dart`
- Create: `lib/features/profile/presentation/hub/widgets/profile_hub_header.dart`
- Create: `lib/features/profile/presentation/hub/widgets/profile_hub_row.dart`
- Create: `lib/features/profile/presentation/hub/widgets/profile_hub_skeleton.dart`
- Create: `lib/features/profile/presentation/hub/widgets/profile_hub_error.dart`
- Modify: `lib/features/home/presentation/tabs/profile_tab_page.dart`
- Test: `test/features/profile/presentation/hub/profile_hub_body_test.dart`
- Modify: `test/features/home/presentation/tabs/profile_tab_page_test.dart`

**Interfaces:**
- Consumes: `profileHubControllerProvider`, `ProfileHubSection.values`
- Produces: UI C00

**Chrome (identique Découvrir / Messages) :**

```dart
Scaffold(
  appBar: AppBar(
    automaticallyImplyLeading: false,
    centerTitle: false,
    title: const Padding(
      padding: EdgeInsets.only(left: AppSpacing.sm),
      child: Text('Profil'),
    ),
  ),
  body: Column(
    children: [
      Expanded(
        child: ProfileHubBody(
          bottomPadding: AppSpacing.lg,
        ),
      ),
      Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.sm,
          AppSpacing.xl,
          HomeFloatingNavBar.scrollClearance(context),
        ),
        child: AppButton(
          label: 'Déconnexion',
          variant: AppButtonVariant.secondary,
          onPressed: () => _signOut(context, ref),
        ),
      ),
    ],
  ),
)
```

Déconnexion **hors** du body : visible en skeleton et en erreur.

**Body :** `RefreshIndicator` + `CustomScrollView` (`AlwaysScrollableScrollPhysics`) + `bottomPadding` sur le dernier sliver.

États :
- `isInitialLoading` → `ProfileHubSkeleton` (avatar `CircleAvatar(radius: AppSpacing.xxl)` + barre `AppSpacing.skeletonTitleWidth` + 8 lignes `AppSpacing.skeletonMetaWidth`)
- `errorMessage != null && hub == null` → `ProfileHubError` (`Impossible de charger le profil` + `Réessayer`)
- sinon header + 8 rows

**Header :**
- Avatar `radius: AppSpacing.xxl`. Photo : `ClipOval` + `AppNetworkImage`. Sinon `Icons.person_outline` (`colors.textSecondary`).
- Nom : `typography.headline`, 1 ligne, ellipsis. `Semantics` badge `Icons.verified` (`colors.verified`, size `AppSpacing.lg`) si `isVerified`.
- `TextButton` « Voir mon profil public » → snackbar `Bientôt` (minSize 48).
- `TextButton` « Modifier » → `Navigator.push` `OnboardingFlowPage`.

**Rows :** `ListTile` + chevron `colors.textSecondary`. `minVerticalPadding` pour cible ≥ 48.

| Section | Action |
|---|---|
| `posts` | `Navigator.push` `MyPostsPage` |
| les 7 autres | snackbar `Bientôt` |

Supprimer du tab : titre centré, email brut, ListTile unique, bouton « Continuer l'onboarding ».

**Tests widget** (`pump` + `pump` comme Messages, overrides `authRepositoryProvider` + `profileFieldsRepositoryProvider` + `feedRepositoryProvider` pour C04) :

1. 8 libellés + nom affiché + badge Semantics `Vérifié`
2. tap `Mes Publications` → `MyPostsPage`
3. tap `Voir mon profil public` et `Mon Profil` → snackbar `Bientôt`
4. tap `Modifier` → `OnboardingFlowPage`
5. erreur : `Réessayer` + `Déconnexion` présents
6. tab test existant : toujours ouvre `MyPostsPage` (après load Ok)

- [ ] **Step 1: Write failing widget tests**
- [ ] **Step 2: Run to verify FAIL**
- [ ] **Step 3: Implement widgets + ProfileTabPage**
- [ ] **Step 4: Run widget tests PASS**
- [ ] **Step 5: Commit** `feat(profile): hub C00 identité et sections`

---

### Task 5: Analyze, suite, simulateur

- [ ] **Step 1:** `flutter analyze` (propre, 0 error)
- [ ] **Step 2:** `flutter test` (suite verte)
- [ ] **Step 3:** `bash scripts/ios_dev.sh restart` (hot restart si session running)
- [ ] **Step 4:** Commit vide interdit ; s'il reste du formatage, `dart format` + commit `style(profile): format hub C00`

## Hors plan

- C01–C03, C05–C16, aperçu public réel, Premium, mur EXPIRED, S02 dupliqué, `go_router`
