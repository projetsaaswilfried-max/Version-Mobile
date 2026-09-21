# Édition profil unifiée (C01 enrichi) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Le crayon hub et « Mon Profil » ouvrent un C01 enrichi (identité + confession / situation / pourquoi le mariage), sans repasser par l’onboarding pour éditer.

**Architecture:** Étendre `MyProfile` / datasource / controller / page existants. Charger et sauver `church_denomination`, `why_marriage`, `marital_status` sur `profiles` avec le même save C01. Navigation hub : crayon → `MyProfilePage` ; bannière complétion → onboarding seulement si essentiels manquants.

**Tech Stack:** Flutter, Riverpod `Notifier`, Equatable, supabase_flutter, `Result`/`Failure`, tokens DS, `AppTextField`, `AppSelectField`, `AppOptionRows`, `AppSettingsRow`, mappings onboarding (`maritalToDb`, `churchDenominations`).

**Spec :** `docs/superpowers/specs/2026-09-21-profile-edit-unified-design.md`

## Global Constraints

- Conventional Commits FR (`feat(profile): …`) ; pas de Co-Authored-By ; pas de tiret cadratin / demi-cadratin
- Tokens only (`context.colors` / `AppSpacing` / widgets `core/widgets`)
- Genre / DOB / pays : lecture seule ; jamais dans le patch save
- Save foi partielle : ne pas écraser verset / témoignage via `SaveFaithDetails` full object si on patch seulement 3 colonnes côté my_profile
- Photos `VERIFIED` : lecture seule (comportement C01 actuel)
- Après save succès : snackbar + `profileHubControllerProvider.notifier.loadInitial()` + `ref.invalidate(profileFieldsProvider)` (pattern C01 actuel)
- `flutter analyze` + tests ciblés au vert ; `bash scripts/android_dev.sh restart` (ou ios) après Dart

## File map

```
lib/features/profile/
  domain/entities/my_profile.dart                    # + denomination, whyMarriage, maritalStatusDb
  domain/mapping/marital_status_label.dart           # + maritalStatusToOnboardingId / from
  data/datasources/my_profile_remote_datasource.dart # MyProfileRaw étendu
  data/datasources/supabase_my_profile_datasource.dart
  presentation/my_profile/
    my_profile_state.dart                            # inchangé si champs sur MyProfile
    my_profile_controller.dart
    my_profile_page.dart
  presentation/hub/profile_hub_body.dart             # crayon + bannière

docs/decisions.md
docs/screens-prd.md
docs/superpowers/specs/2026-09-21-profile-edit-unified-design.md  # déjà écrit

test/features/profile/...
test/helpers/profile_test_fakes.dart
```

---

### Task 1: Domain MyProfile + mapping marital DB ↔ UI

**Files:**
- Modify: `lib/features/profile/domain/entities/my_profile.dart`
- Modify: `lib/features/profile/domain/mapping/marital_status_label.dart`
- Modify: `test/helpers/profile_test_fakes.dart`
- Test: `test/features/profile/domain/mapping/marital_status_mapping_test.dart` (create)

**Interfaces:**
- Produces: `MyProfile` with `denomination`, `whyMarriage`, `maritalStatusDb` (`String?`)
- Produces: `String? maritalStatusToOnboardingId(String? db)` and `String? maritalStatusFromOnboardingId(String id)` returning DB values (`SINGLE_NO_CHILDREN`, …)
- Consumes: ids onboarding `single` / `singleWithChildren` / `divorced` / `widowed` (alignés `OnboardingMaritalStatus.name`)

- [ ] **Step 1: Write failing mapping tests**

```dart
import 'package:agapeo/features/profile/domain/mapping/marital_status_label.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maritalStatusToOnboardingId maps DB enums', () {
    expect(maritalStatusToOnboardingId('SINGLE_NO_CHILDREN'), 'single');
    expect(maritalStatusToOnboardingId('SINGLE'), 'single');
    expect(maritalStatusToOnboardingId('SINGLE_WITH_CHILDREN'), 'singleWithChildren');
    expect(maritalStatusToOnboardingId('DIVORCED'), 'divorced');
    expect(maritalStatusToOnboardingId('WIDOWED'), 'widowed');
    expect(maritalStatusToOnboardingId(null), isNull);
  });

  test('maritalStatusFromOnboardingId maps UI ids to DB', () {
    expect(maritalStatusFromOnboardingId('single'), 'SINGLE_NO_CHILDREN');
    expect(maritalStatusFromOnboardingId('singleWithChildren'), 'SINGLE_WITH_CHILDREN');
    expect(maritalStatusFromOnboardingId('divorced'), 'DIVORCED');
    expect(maritalStatusFromOnboardingId('widowed'), 'WIDOWED');
    expect(maritalStatusFromOnboardingId('nope'), isNull);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/profile/domain/mapping/marital_status_mapping_test.dart`  
Expected: FAIL (functions undefined)

- [ ] **Step 3: Implement mapping + extend MyProfile**

In `marital_status_label.dart` add the two functions (reuse the same `toUpperCase().replaceAll('-', '_')` normalize as `maritalStatusLabel`).

In `my_profile.dart` add fields with defaults:

```dart
this.denomination = '',
this.whyMarriage = '',
this.maritalStatusDb,
```

Update `copyWith` and `props`.

Update `fakeMyProfile()` in `profile_test_fakes.dart` with sample values if needed.

- [ ] **Step 4: Run mapping tests**

Run: `flutter test test/features/profile/domain/mapping/marital_status_mapping_test.dart`  
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/profile/domain/entities/my_profile.dart \
  lib/features/profile/domain/mapping/marital_status_label.dart \
  test/features/profile/domain/mapping/marital_status_mapping_test.dart \
  test/helpers/profile_test_fakes.dart
git commit -m "$(cat <<'EOF'
feat(profile): champs foi essentielle et mapping marital sur MyProfile

EOF
)"
```

---

### Task 2: Datasource fetch/save des 3 colonnes

**Files:**
- Modify: `lib/features/profile/data/datasources/my_profile_remote_datasource.dart` (`MyProfileRaw`)
- Modify: `lib/features/profile/data/datasources/supabase_my_profile_datasource.dart`
- Modify: `lib/features/profile/data/repositories/my_profile_repository_impl.dart` (mapping Raw → entity)
- Test: `test/features/profile/data/repositories/my_profile_repository_impl_test.dart` (étendre si présent) ou test datasource avec fake si pattern existant

**Interfaces:**
- Consumes: `MyProfile.denomination` / `whyMarriage` / `maritalStatusDb`
- Produces: fetch select includes `church_denomination, why_marriage, marital_status` ; save patch includes the three (trim ; omit marital if null)

- [ ] **Step 1: Extend `MyProfileRaw` and select/save**

`_baseSelect` becomes:

```dart
'first_name, last_name, gender, birth_date, country, city, profession, bio, '
'photo_verification_status, church_denomination, why_marriage, marital_status';
```

In `fetchRaw` map:

```dart
denomination: json.stringOrNull('church_denomination') ?? '',
whyMarriage: json.stringOrNull('why_marriage') ?? '',
maritalStatusDb: json.stringOrNull('marital_status'),
```

In `save` patch add:

```dart
'church_denomination': profile.denomination.trim(),
'why_marriage': profile.whyMarriage.trim(),
if (profile.maritalStatusDb != null && profile.maritalStatusDb!.isNotEmpty)
  'marital_status': profile.maritalStatusDb,
```

If `marital_status` column missing causes Postgrest errors on some envs, use the same best-effort probe pattern as relocate (optional follow-up) : for v1 assume column exists (already used by public preview).

Wire Raw → `MyProfile` in repository impl / wherever mapping lives.

- [ ] **Step 2: Run existing my_profile tests**

Run: `flutter test test/features/profile/presentation/my_profile/`  
Expected: PASS (fakes updated in Task 1)

- [ ] **Step 3: Commit**

```bash
git add lib/features/profile/data/
git commit -m "$(cat <<'EOF'
feat(profile): persister confession, why_marriage et marital_status depuis C01

EOF
)"
```

---

### Task 3: Controller + UI page enrichie

**Files:**
- Modify: `lib/features/profile/presentation/my_profile/my_profile_page.dart`
- Modify: `lib/features/profile/presentation/my_profile/my_profile_controller.dart` (si helpers update denomination)
- Modify: `test/features/profile/presentation/my_profile/my_profile_page_test.dart`
- Modify: `test/features/profile/presentation/my_profile/my_profile_controller_test.dart`

**Interfaces:**
- Consumes: `onboardingMaritalItems()`, `onboardingFaithConfessions` / `churchDenominations`, `maritalStatusToOnboardingId`, `maritalStatusFromOnboardingId`
- Produces: UI sections locked + foi ; save via `updateProfile` + existing `save()`

- [ ] **Step 1: Update failing / new widget tests**

Replace assertion on single-line `Femme · 04/03/1992 · France` with locked section labels:

```dart
expect(find.text('Genre'), findsWidgets); // or findsOneWidget in locked group
expect(find.text('Non modifiables après validation'), findsOneWidget);
expect(find.text('Confession chrétienne'), findsOneWidget); // or label chosen
expect(find.text('Situation matrimoniale'), findsOneWidget);
expect(find.text('Pourquoi cherches-tu le mariage ?'), findsOneWidget);
expect(find.textContaining('Ma Foi'), findsOneWidget);
```

Add controller test: after load, `profile.denomination` / `whyMarriage` / `maritalStatusDb` from fake ; `updateProfile` then `save` calls repo once with updated faith fields.

- [ ] **Step 2: Run tests to see failures**

Run: `flutter test test/features/profile/presentation/my_profile/`  
Expected: FAIL on new expectations

- [ ] **Step 3: Implement UI**

In `my_profile_page.dart` form, after photo grid:

1. `AppSettingsGroup` with 3 `AppSettingsRow` (Genre / Âge / Pays) using `profile.genderLabel`, `profile.birthDateLabel`, `profile.country` — **no `onTap`** (or null). Caption: `Non modifiables après validation`.
2. Keep existing identity fields + relocate switch.
3. Add section Foi:
   - `AppSelectField` label Confession, `options: churchDenominations`, value `profile.denomination`, onChanged → `updateProfile((p) => p.copyWith(denomination: v))`
   - `AppOptionRows` `items: onboardingMaritalItems()`, `selectedId: maritalStatusToOnboardingId(profile.maritalStatusDb)`, onSelected → `copyWith(maritalStatusDb: maritalStatusFromOnboardingId(id))`
   - `AppTextField` pourquoi mariage, maxLines 4, maxLength from `FaithDetails.maxWhyMarriage` (1000) or 600 if product prefers shorter on this screen — **use 1000** to match domain
4. `TextButton` / text link: `Plus de détails dans Ma Foi` → `Navigator.push(FaithPage())`
5. Remove the old single-line `join(' · ')` locked text if replaced by settings rows.

Import onboarding mapping carefully (presentation → onboarding presentation is OK for shared option lists ; prefer `churchDenominations` from `core/config` + marital helpers in profile domain to avoid tight coupling if possible). Prefer:

```dart
import '../../../../core/config/church_denominations.dart';
import '../../../onboarding/presentation/profile_onboarding/onboarding_option_mapping.dart';
```

only for `onboardingMaritalItems` / labels, or duplicate thin wrapper in profile mapping — YAGNI: import onboarding mapping for items.

- [ ] **Step 4: Run my_profile tests**

Run: `flutter test test/features/profile/presentation/my_profile/`  
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/profile/presentation/my_profile/ \
  test/features/profile/presentation/my_profile/
git commit -m "$(cat <<'EOF'
feat(profile): UI Mon Profil avec foi essentielle et champs verrouillés

EOF
)"
```

---

### Task 4: Hub navigation (crayon + bannière)

**Files:**
- Modify: `lib/features/profile/presentation/hub/profile_hub_body.dart`
- Modify: `test/features/profile/presentation/hub/profile_hub_body_test.dart`
- Possibly: `lib/features/profile/domain/entities/profile_completeness.dart` / snapshot helpers for « essentials present »

**Interfaces:**
- Consumes: `profileCompletenessProvider` or `profileFieldsProvider` / essentials locked flags
- Produces: `onEdit` → `MyProfilePage` ; banner tap → onboarding iff gender/DOB/country missing, else `MyProfilePage`

- [ ] **Step 1: Change hub test**

In `profile_hub_body_test.dart`, replace:

```dart
testWidgets('Modifier opens onboarding', ...
  expect(find.byType(OnboardingFlowPage), findsOneWidget);
```

with:

```dart
testWidgets('Modifier opens Mon Profil', (tester) async {
  ...
  await tester.tap(find.byTooltip('Modifier mon profil'));
  await tester.pumpAndSettle();
  expect(find.byType(MyProfilePage), findsOneWidget);
  expect(find.byType(OnboardingFlowPage), findsNothing);
});
```

Add test for banner when incomplete but essentials present → `MyProfilePage` (use `FakeProfileFieldsRepository` with essentials filled, missing photo/confession). Add test essentials missing → `OnboardingFlowPage`.

Check how `fakeProfileFieldsSnapshot` / completeness expose essentials — reuse `essentialsLocked` or `hasGender && hasBirthDate && hasCountry` from snapshot if available.

- [ ] **Step 2: Run hub test fail**

Run: `flutter test test/features/profile/presentation/hub/profile_hub_body_test.dart`  
Expected: FAIL on Modifier opens Mon Profil

- [ ] **Step 3: Wire navigation**

```dart
onEdit: () {
  Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => const MyProfilePage()),
  );
},
```

For banner `onTap`:

```dart
onTap: () {
  final fields = /* from completeness missingKeys or profileFields */;
  final needOnboarding = /* gender/birthDate/country missing */;
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => needOnboarding
          ? const OnboardingFlowPage()
          : const MyProfilePage(),
    ),
  );
},
```

Exact predicate: use `ProfileFieldKeys.gender/birthDate/country` in `completeness.missingKeys` if that set exists; otherwise read `profileFieldsProvider`.

- [ ] **Step 4: Run hub tests**

Run: `flutter test test/features/profile/presentation/hub/profile_hub_body_test.dart`  
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/profile/presentation/hub/profile_hub_body.dart \
  test/features/profile/presentation/hub/profile_hub_body_test.dart
git commit -m "$(cat <<'EOF'
feat(profile): crayon et bannière pointent vers Mon Profil enrichi

EOF
)"
```

---

### Task 5: Docs + verify

**Files:**
- Modify: `docs/decisions.md` (append D26 or next free id)
- Modify: `docs/screens-prd.md` (C01 / hub crayon note ; §13 if outdated snippet)
- Spec already at `docs/superpowers/specs/2026-09-21-profile-edit-unified-design.md`

- [ ] **Step 1: Append decision**

```markdown
### D26 - Édition profil unifiée (C01 enrichi)
*2026-09-21 · réf. PRD §5–6 / §14, spec `2026-09-21-profile-edit-unified-design.md`*

Le crayon hub et « Mon Profil » ouvrent C01 enrichi (identité + confession /
situation / pourquoi le mariage). Genre / DOB / pays restent lecture seule.
L'onboarding ne s'ouvre plus depuis Modifier ; uniquement premier parcours
ou essentiels encore manquants (bannière complétion).
```

Update screens-prd C01 line to mention foi essentielle + entry from pencil.

- [ ] **Step 2: Analyze + full related tests**

```bash
flutter analyze lib/features/profile/presentation/my_profile \
  lib/features/profile/presentation/hub \
  lib/features/profile/domain \
  lib/features/profile/data/datasources/supabase_my_profile_datasource.dart
flutter test test/features/profile/presentation/my_profile/ \
  test/features/profile/presentation/hub/profile_hub_body_test.dart \
  test/features/profile/domain/mapping/
```

Expected: No issues ; all PASS

- [ ] **Step 3: Restart Android (or iOS) session**

```bash
bash scripts/android_dev.sh restart || bash scripts/android_dev.sh start
```

Manual smoke: Profil → crayon → sections locked + foi + Enregistrer.

- [ ] **Step 4: Commit docs**

```bash
git add docs/decisions.md docs/screens-prd.md
git commit -m "$(cat <<'EOF'
docs(profile): D26 édition profil unifiée C01 enrichi

EOF
)"
```

---

## Spec coverage check

| Spec item | Task |
|---|---|
| Crayon → MyProfilePage | 4 |
| Menu Mon Profil = même page | 4 (déjà + contenu 3) |
| Locked genre/âge/pays | 3 |
| Identité C01 + relocate | 3 (existant) |
| Confession / situation / why | 1–3 |
| Lien Ma Foi | 3 |
| Save unique patch 3 colonnes + identité | 2–3 |
| Bannière → onboarding si essentials manquants | 4 |
| Photos VERIFIED read-only | inchangé C01 |
| decisions + screens-prd | 5 |
| Tests hub / page / mapping | 1, 3, 4 |

## Placeholder scan

Aucun TBD / « similar to Task N » sans code.

## Type consistency

- DB marital : `SINGLE_NO_CHILDREN` | `SINGLE_WITH_CHILDREN` | `DIVORCED` | `WIDOWED`
- UI id : `single` | `singleWithChildren` | `divorced` | `widowed`
- Profile fields : `denomination`, `whyMarriage`, `maritalStatusDb`
