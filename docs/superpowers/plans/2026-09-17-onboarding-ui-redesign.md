# Onboarding UI redesign O01-O05 (dette #27) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remplacer les sélecteurs Material bruts d'O01-O05 par des widgets design-system (Nestle chrome + Datify selects), toujours en draft local.

**Architecture:** Widgets présentationnels dans `core/widgets` (callbacks, zéro Riverpod, zéro dépendance feature). Les steps `profile_onboarding/` les branchent sur `onboardingFlowProvider`. Pas d'écriture Supabase.

**Tech Stack:** Flutter, Riverpod, Equatable, tokens `core/theme`, `flutter_test`, `image_picker` (déjà en place pour photos/selfie).

## Global Constraints

- Pas de tiret cadratin / demi-cadratin dans code, docs, commits.
- Tokens only : `context.colors`, `context.typography`, `AppSpacing`, `AppRadius`, `AppButton`, `AppTextField`.
- `core/` ne doit pas importer `features/` (pas d'`OnboardingGender` dans core).
- Pas d'API / Storage / S02 (PR2).
- Spec : `docs/superpowers/specs/2026-09-17-onboarding-ui-redesign-design.md`.
- Branche : `feat/onboarding-ui-redesign` depuis `main` à jour.
- Conventional Commits ; `flutter analyze` + `flutter test` verts avant MR.

---

## File map

| File | Role |
|---|---|
| `lib/core/widgets/app_option_cards.dart` | Cards sélection génériques (genre, situation, …) |
| `lib/core/widgets/app_gender_cards.dart` | 3 options Femme/Homme/Autre (ids string) |
| `lib/core/widgets/app_birth_date_field.dart` | Champ + sheet roue date |
| `lib/core/widgets/app_country_picker.dart` | Champ + sheet search liste pays |
| `lib/core/widgets/app_photo_grid.dart` | Grille slots thumbs + add/remove |
| `lib/core/widgets/widgets.dart` | Barrel exports |
| `lib/features/onboarding/.../steps/essentials_step.dart` | Wire O01 |
| `lib/features/onboarding/.../steps/photos_step.dart` | Wire O02 |
| `lib/features/onboarding/.../steps/selfie_step.dart` | Polish O03 |
| `lib/features/onboarding/.../steps/faith_step.dart` | Cards situation (plus ChoiceChip) |
| `lib/features/onboarding/.../steps/preferences_step.dart` | Spacing / CTA polish |
| `docs/design-inspiration.md` | Retirer flag « pas au niveau » |
| Tests sous `test/core/widgets/` + maj `test/features/onboarding/...` |

---

### Task 1: AppOptionCards + AppGenderCards

**Files:**
- Create: `lib/core/widgets/app_option_cards.dart`
- Create: `lib/core/widgets/app_gender_cards.dart`
- Modify: `lib/core/widgets/widgets.dart`
- Test: `test/core/widgets/app_gender_cards_test.dart`

**Interfaces:**
- Produces: `AppOptionItem({required String id, required String label, IconData? icon})`
- Produces: `AppOptionCards({required List<AppOptionItem> items, String? selectedId, required ValueChanged<String> onSelected, String? errorText})`
- Produces: `AppGenderCards({String? selectedId, required ValueChanged<String> onSelected, String? errorText})` avec ids `woman` / `man` / `other`

- [ ] **Step 1: Create branch**

```bash
git checkout main && git pull --ff-only origin main
git checkout -b feat/onboarding-ui-redesign
```

- [ ] **Step 2: Write failing test**

```dart
import 'package:agapeo/core/theme/app_theme.dart';
import 'package:agapeo/core/widgets/app_gender_cards.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('tapping Homme selects man id', (tester) async {
    String? selected;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: AppGenderCards(
            selectedId: selected,
            onSelected: (id) => selected = id,
          ),
        ),
      ),
    );

    expect(find.byType(ChoiceChip), findsNothing);
    await tester.tap(find.text('Homme'));
    await tester.pump();
    expect(selected, 'man');
  });
}
```

- [ ] **Step 3: Run test - expect FAIL (library not found)**

Run: `flutter test test/core/widgets/app_gender_cards_test.dart`  
Expected: FAIL (file / library missing)

- [ ] **Step 4: Implement widgets**

`lib/core/widgets/app_option_cards.dart`:

```dart
import 'package:flutter/material.dart';

import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';

class AppOptionItem {
  const AppOptionItem({
    required this.id,
    required this.label,
    this.icon,
  });

  final String id;
  final String label;
  final IconData? icon;
}

class AppOptionCards extends StatelessWidget {
  const AppOptionCards({
    super.key,
    required this.items,
    required this.onSelected,
    this.selectedId,
    this.errorText,
  });

  final List<AppOptionItem> items;
  final String? selectedId;
  final ValueChanged<String> onSelected;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final item in items) ...[
          Material(
            color: colors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.lgRadius,
              side: BorderSide(
                color: selectedId == item.id ? colors.primary : colors.border,
                width: selectedId == item.id ? 2 : 1,
              ),
            ),
            child: InkWell(
              borderRadius: AppRadius.lgRadius,
              onTap: () => onSelected(item.id),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                child: Row(
                  children: [
                    if (item.icon != null) ...[
                      Icon(
                        item.icon,
                        color: selectedId == item.id
                            ? colors.primary
                            : colors.textSecondary,
                      ),
                      const SizedBox(width: AppSpacing.md),
                    ],
                    Expanded(
                      child: Text(item.label, style: typography.bodyLarge),
                    ),
                    if (selectedId == item.id)
                      Icon(Icons.check_circle, color: colors.primary),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (errorText != null)
          Text(
            errorText!,
            style: typography.bodySmall.copyWith(color: colors.error),
          ),
      ],
    );
  }
}
```

`lib/core/widgets/app_gender_cards.dart`:

```dart
import 'package:flutter/material.dart';

import 'app_option_cards.dart';

class AppGenderCards extends StatelessWidget {
  const AppGenderCards({
    super.key,
    required this.onSelected,
    this.selectedId,
    this.errorText,
  });

  final String? selectedId;
  final ValueChanged<String> onSelected;
  final String? errorText;

  static const items = <AppOptionItem>[
    AppOptionItem(id: 'woman', label: 'Femme', icon: Icons.woman),
    AppOptionItem(id: 'man', label: 'Homme', icon: Icons.man),
    AppOptionItem(id: 'other', label: 'Autre', icon: Icons.transgender),
  ];

  @override
  Widget build(BuildContext context) {
    return AppOptionCards(
      items: items,
      selectedId: selectedId,
      onSelected: onSelected,
      errorText: errorText,
    );
  }
}
```

Update `widgets.dart`:

```dart
export 'app_button.dart';
export 'app_svg.dart';
export 'app_text_field.dart';
export 'app_option_cards.dart';
export 'app_gender_cards.dart';
```

- [ ] **Step 5: Run test - expect PASS**

Run: `flutter test test/core/widgets/app_gender_cards_test.dart`  
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add lib/core/widgets/app_option_cards.dart \
  lib/core/widgets/app_gender_cards.dart \
  lib/core/widgets/widgets.dart \
  test/core/widgets/app_gender_cards_test.dart
git commit -m "$(cat <<'EOF'
feat(design-system): AppGenderCards et AppOptionCards

EOF
)"
```

---

### Task 2: AppBirthDateField

**Files:**
- Create: `lib/core/widgets/app_birth_date_field.dart`
- Modify: `lib/core/widgets/widgets.dart`
- Test: `test/core/widgets/app_birth_date_field_test.dart`

**Interfaces:**
- Produces: `AppBirthDateField({DateTime? value, required ValueChanged<DateTime> onChanged, String? label, String? errorText, DateTime? now})`
- Sheet: `CupertinoDatePicker` mode date dans un `showModalBottomSheet` themé tokens (pas `showDatePicker` Material)

- [ ] **Step 1: Write failing test**

```dart
import 'package:agapeo/core/theme/app_theme.dart';
import 'package:agapeo/core/widgets/app_birth_date_field.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('opens sheet with CupertinoDatePicker on tap', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: AppBirthDateField(
            value: null,
            onChanged: (_) {},
          ),
        ),
      ),
    );

    await tester.tap(find.text('Choisir'));
    await tester.pumpAndSettle();

    expect(find.byType(CupertinoDatePicker), findsOneWidget);
    expect(find.text('Valider'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test - expect FAIL**

Run: `flutter test test/core/widgets/app_birth_date_field_test.dart`  
Expected: FAIL (missing library)

- [ ] **Step 3: Implement**

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import 'app_button.dart';

class AppBirthDateField extends StatelessWidget {
  const AppBirthDateField({
    super.key,
    required this.onChanged,
    this.value,
    this.label = 'Date de naissance',
    this.errorText,
    this.now,
  });

  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final String label;
  final String? errorText;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final display = value == null
        ? 'Choisir'
        : MaterialLocalizations.of(context).formatMediumDate(value!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: typography.label),
        const SizedBox(height: AppSpacing.xs),
        Material(
          color: colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.mdRadius,
            side: BorderSide(
              color: errorText != null ? colors.error : colors.border,
            ),
          ),
          child: InkWell(
            borderRadius: AppRadius.mdRadius,
            onTap: () => _openSheet(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      display,
                      style: typography.bodyLarge.copyWith(
                        color: value == null
                            ? colors.textSecondary
                            : colors.textPrimary,
                      ),
                    ),
                  ),
                  Icon(Icons.calendar_today_outlined, color: colors.primary),
                ],
              ),
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            errorText!,
            style: typography.bodySmall.copyWith(color: colors.error),
          ),
        ],
      ],
    );
  }

  Future<void> _openSheet(BuildContext context) async {
    final clock = now ?? DateTime.now();
    var draft = value ?? DateTime(clock.year - 25, clock.month, clock.day);

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Date de naissance', style: ctx.typography.headline),
                SizedBox(
                  height: 200,
                  child: CupertinoTheme(
                    data: CupertinoThemeData(
                      primaryColor: ctx.colors.primary,
                      textTheme: CupertinoTextThemeData(
                        dateTimePickerTextStyle: ctx.typography.bodyLarge,
                      ),
                    ),
                    child: CupertinoDatePicker(
                      mode: CupertinoDatePickerMode.date,
                      initialDateTime: draft,
                      maximumDate: clock,
                      minimumDate: DateTime(clock.year - 100),
                      onDateTimeChanged: (d) => draft = d,
                    ),
                  ),
                ),
                AppButton(
                  label: 'Valider',
                  onPressed: () {
                    onChanged(draft);
                    Navigator.of(ctx).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
```

Export in `widgets.dart`.

- [ ] **Step 4: Run test - expect PASS**

Run: `flutter test test/core/widgets/app_birth_date_field_test.dart`  
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/core/widgets/app_birth_date_field.dart \
  lib/core/widgets/widgets.dart \
  test/core/widgets/app_birth_date_field_test.dart
git commit -m "$(cat <<'EOF'
feat(design-system): AppBirthDateField sheet roue

EOF
)"
```

---

### Task 3: AppCountryPicker

**Files:**
- Create: `lib/core/widgets/app_country_picker.dart`
- Modify: `lib/core/widgets/widgets.dart`
- Test: `test/core/widgets/app_country_picker_test.dart`

**Interfaces:**
- Produces: `AppCountryPicker({required List<String> countries, String? value, required ValueChanged<String> onChanged, String? label, String? errorText})`
- Sheet: `TextField` search filtre + `ListTile`s ; pas de `DropdownButton`

- [ ] **Step 1: Write failing test**

```dart
import 'package:agapeo/core/theme/app_theme.dart';
import 'package:agapeo/core/widgets/app_country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('selects country from searchable sheet', (tester) async {
    String? value;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: AppCountryPicker(
            countries: const ['France', 'Belgique', 'Canada'],
            value: value,
            onChanged: (v) => value = v,
          ),
        ),
      ),
    );

    expect(find.byType(DropdownButtonFormField<String>), findsNothing);
    await tester.tap(find.text('Choisir'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Bel');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Belgique'));
    await tester.pumpAndSettle();
    expect(value, 'Belgique');
  });
}
```

- [ ] **Step 2: Run - expect FAIL**

Run: `flutter test test/core/widgets/app_country_picker_test.dart`

- [ ] **Step 3: Implement**

```dart
import 'package:flutter/material.dart';

import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';

class AppCountryPicker extends StatelessWidget {
  const AppCountryPicker({
    super.key,
    required this.countries,
    required this.onChanged,
    this.value,
    this.label = 'Pays',
    this.errorText,
  });

  final List<String> countries;
  final String? value;
  final ValueChanged<String> onChanged;
  final String label;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: typography.label),
        const SizedBox(height: AppSpacing.xs),
        Material(
          color: colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.mdRadius,
            side: BorderSide(
              color: errorText != null ? colors.error : colors.border,
            ),
          ),
          child: InkWell(
            borderRadius: AppRadius.mdRadius,
            onTap: () => _openSheet(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      value ?? 'Choisir',
                      style: typography.bodyLarge.copyWith(
                        color: value == null
                            ? colors.textSecondary
                            : colors.textPrimary,
                      ),
                    ),
                  ),
                  Icon(Icons.expand_more, color: colors.textSecondary),
                ],
              ),
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            errorText!,
            style: typography.bodySmall.copyWith(color: colors.error),
          ),
        ],
      ],
    );
  }

  Future<void> _openSheet(BuildContext context) async {
    var query = '';
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            final filtered = countries
                .where(
                  (c) => c.toLowerCase().contains(query.toLowerCase()),
                )
                .toList();
            return SafeArea(
              child: SizedBox(
                height: MediaQuery.sizeOf(ctx).height * 0.7,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: 'Rechercher',
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: (v) => setState(() => query = v),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (_, i) {
                          final c = filtered[i];
                          return ListTile(
                            title: Text(c),
                            trailing: value == c
                                ? Icon(
                                    Icons.check,
                                    color: ctx.colors.primary,
                                  )
                                : null,
                            onTap: () {
                              onChanged(c);
                              Navigator.of(ctx).pop();
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
```

Export in barrel.

- [ ] **Step 4: Run - expect PASS**

Run: `flutter test test/core/widgets/app_country_picker_test.dart`

- [ ] **Step 5: Commit**

```bash
git add lib/core/widgets/app_country_picker.dart \
  lib/core/widgets/widgets.dart \
  test/core/widgets/app_country_picker_test.dart
git commit -m "$(cat <<'EOF'
feat(design-system): AppCountryPicker searchable

EOF
)"
```

---

### Task 4: AppPhotoGrid

**Files:**
- Create: `lib/core/widgets/app_photo_grid.dart`
- Modify: `lib/core/widgets/widgets.dart`
- Test: `test/core/widgets/app_photo_grid_test.dart`

**Interfaces:**
- Produces: `AppPhotoGrid({required List<String> paths, required int maxSlots, required VoidCallback onAdd, required ValueChanged<int> onRemoveAt, String? errorText})`
- Slot vide : `+` centré (pas icône appareil photo seule sur grand rectangle)
- Thumbs : `Image.file` ; bouton `×` pour retirer

- [ ] **Step 1: Write failing test**

```dart
import 'package:agapeo/core/theme/app_theme.dart';
import 'package:agapeo/core/widgets/app_photo_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('empty slot shows add affordance and calls onAdd', (tester) async {
    var added = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: AppPhotoGrid(
            paths: const [],
            maxSlots: 2,
            onAdd: () => added = true,
            onRemoveAt: (_) {},
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.add), findsOneWidget);
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    expect(added, isTrue);
  });
}
```

- [ ] **Step 2: Run - expect FAIL**

Run: `flutter test test/core/widgets/app_photo_grid_test.dart`

- [ ] **Step 3: Implement**

```dart
import 'dart:io';

import 'package:flutter/material.dart';

import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';

class AppPhotoGrid extends StatelessWidget {
  const AppPhotoGrid({
    super.key,
    required this.paths,
    required this.maxSlots,
    required this.onAdd,
    required this.onRemoveAt,
    this.errorText,
    this.slotWidth = 110,
    this.slotHeight = 140,
  });

  final List<String> paths;
  final int maxSlots;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemoveAt;
  final String? errorText;
  final double slotWidth;
  final double slotHeight;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final canAdd = paths.length < maxSlots;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Text(
              errorText!,
              style: typography.bodySmall.copyWith(color: colors.error),
            ),
          ),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            for (var i = 0; i < paths.length; i++)
              SizedBox(
                width: slotWidth,
                height: slotHeight,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: AppRadius.lgRadius,
                      child: Image.file(
                        File(paths[i]),
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: AppSpacing.xs,
                      right: AppSpacing.xs,
                      child: Material(
                        color: colors.surface.withValues(alpha: 0.92),
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => onRemoveAt(i),
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.xs),
                            child: Icon(
                              Icons.close,
                              size: 18,
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (canAdd)
              SizedBox(
                width: slotWidth,
                height: slotHeight,
                child: Material(
                  color: colors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.lgRadius,
                    side: BorderSide(color: colors.border),
                  ),
                  child: InkWell(
                    borderRadius: AppRadius.lgRadius,
                    onTap: onAdd,
                    child: Icon(Icons.add, size: 36, color: colors.primary),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
```

Export in barrel.

- [ ] **Step 4: Run - expect PASS**

Run: `flutter test test/core/widgets/app_photo_grid_test.dart`

- [ ] **Step 5: Commit**

```bash
git add lib/core/widgets/app_photo_grid.dart \
  lib/core/widgets/widgets.dart \
  test/core/widgets/app_photo_grid_test.dart
git commit -m "$(cat <<'EOF'
feat(design-system): AppPhotoGrid slots thumbs

EOF
)"
```

---

### Task 5: Wire EssentialsStep (O01)

**Files:**
- Modify: `lib/features/onboarding/presentation/profile_onboarding/steps/essentials_step.dart`
- Test: `test/features/onboarding/presentation/profile_onboarding/essentials_step_test.dart`

**Interfaces:**
- Consumes: `AppGenderCards`, `AppBirthDateField`, `AppCountryPicker`
- Map ids ↔ `OnboardingGender` via `.name` (`woman`/`man`/`other`)
- Garde `kOnboardingCountries` dans ce fichier (ou constante locale)

- [ ] **Step 1: Write failing test**

```dart
import 'package:agapeo/core/theme/app_theme.dart';
import 'package:agapeo/core/widgets/app_gender_cards.dart';
import 'package:agapeo/features/onboarding/presentation/profile_onboarding/onboarding_flow_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('O01 uses AppGenderCards not ChoiceChip', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: const OnboardingFlowPage(),
        ),
      ),
    );

    expect(find.byType(AppGenderCards), findsOneWidget);
    expect(find.byType(ChoiceChip), findsNothing);
    expect(find.byType(DropdownButtonFormField<String>), findsNothing);
  });
}
```

- [ ] **Step 2: Run - expect FAIL (still ChoiceChip)**

Run: `flutter test test/features/onboarding/presentation/profile_onboarding/essentials_step_test.dart`

- [ ] **Step 3: Rewrite essentials_step body**

Remplacer genre / date / pays par :

```dart
import '../../../../../core/widgets/widgets.dart';
// ...
Text('Genre', style: typography.label),
const SizedBox(height: AppSpacing.sm),
AppGenderCards(
  selectedId: draft.gender?.name,
  errorText: errors['gender'],
  onSelected: (id) {
    final g = OnboardingGender.values.firstWhere((e) => e.name == id);
    controller.updateDraft((d) => d.copyWith(gender: g));
  },
),
const SizedBox(height: AppSpacing.xl),
AppBirthDateField(
  value: draft.birthDate,
  errorText: errors['birthDate'],
  onChanged: (d) =>
      controller.updateDraft((draft) => draft.copyWith(birthDate: d)),
),
const SizedBox(height: AppSpacing.xl),
AppCountryPicker(
  countries: kOnboardingCountries,
  value: draft.country,
  errorText: errors['country'],
  onChanged: (c) =>
      controller.updateDraft((d) => d.copyWith(country: c)),
),
```

Supprimer `ChoiceChip`, `ListTile`+`showDatePicker`, `DropdownButtonFormField`.

- [ ] **Step 4: Run - expect PASS**

Run: `flutter test test/features/onboarding/presentation/profile_onboarding/essentials_step_test.dart test/features/onboarding/presentation/profile_onboarding/onboarding_validators_test.dart`

- [ ] **Step 5: Commit**

```bash
git add lib/features/onboarding/presentation/profile_onboarding/steps/essentials_step.dart \
  test/features/onboarding/presentation/profile_onboarding/essentials_step_test.dart
git commit -m "$(cat <<'EOF'
feat(onboarding): O01 essentials widgets custom

EOF
)"
```

---

### Task 6: Wire PhotosStep (O02)

**Files:**
- Modify: `lib/features/onboarding/presentation/profile_onboarding/steps/photos_step.dart`
- Test: étendre `essentials_step_test.dart` ou créer `photos_step_test.dart`

**Interfaces:**
- Consumes: `AppPhotoGrid(paths, maxSlots: OnboardingDraft.maxFreePhotos, onAdd: controller.addPhoto, onRemoveAt: controller.removePhoto)`

- [ ] **Step 1: Write failing test**

```dart
import 'package:agapeo/core/theme/app_theme.dart';
import 'package:agapeo/core/widgets/app_photo_grid.dart';
import 'package:agapeo/features/onboarding/presentation/profile_onboarding/onboarding_draft.dart';
import 'package:agapeo/features/onboarding/presentation/profile_onboarding/onboarding_flow_controller.dart';
import 'package:agapeo/features/onboarding/presentation/profile_onboarding/onboarding_flow_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('O02 shows AppPhotoGrid after essentials', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const OnboardingFlowPage(),
        ),
      ),
    );

    container.read(onboardingFlowProvider.notifier).updateDraft(
      (d) => d.copyWith(
        gender: OnboardingGender.woman,
        birthDate: DateTime(1995, 1, 1),
        country: 'France',
      ),
    );
    container.read(onboardingFlowProvider.notifier).next();
    await tester.pumpAndSettle();

    expect(find.text('Tes photos'), findsOneWidget);
    expect(find.byType(AppPhotoGrid), findsOneWidget);
    expect(find.byIcon(Icons.add_a_photo_outlined), findsNothing);
  });
}
```

- [ ] **Step 2: Run - expect FAIL**

- [ ] **Step 3: Replace Wrap/OutlinedButton by AppPhotoGrid**

Garder titre + sous-titre ; retirer le `AppButton` « Ajouter une photo » redondant (le slot `+` suffit).

- [ ] **Step 4: Run PASS + commit**

```bash
git commit -m "$(cat <<'EOF'
feat(onboarding): O02 AppPhotoGrid

EOF
)"
```

---

### Task 7: Polish SelfieStep (O03)

**Files:**
- Modify: `lib/features/onboarding/presentation/profile_onboarding/steps/selfie_step.dart`
- Test: `test/features/onboarding/presentation/profile_onboarding/selfie_step_test.dart` (smoke labels)

**Interfaces:**
- CTA label exact : `Prendre le selfie` si vide, `Reprendre le selfie` si capture
- Preview plus large (ex. largeur `double.infinity`, hauteur 320), bordure `AppRadius.xl`, fond `border` léger + icône si vide
- Toujours `controller.captureSelfie` / `clearSelfie` (pas de galerie)

- [ ] **Step 1: Write failing test**

```dart
testWidgets('selfie empty shows Prendre le selfie', (tester) async {
  // navigate to step 2 via notifier next() twice after filling drafts
  expect(find.text('Prendre le selfie'), findsOneWidget);
});
```

- [ ] **Step 2: Implement polish** (labels + layout), keep camera-only

- [ ] **Step 3: Run PASS + commit**

```bash
git commit -m "$(cat <<'EOF'
style(onboarding): polish O03 selfie preview CTA

EOF
)"
```

---

### Task 8: FaithStep + PreferencesStep (O04/O05)

**Files:**
- Modify: `faith_step.dart`, `preferences_step.dart`
- Test: assert no `ChoiceChip` anywhere in flow after reaching faith

**Interfaces:**
- Consumes: `AppOptionCards` pour `OnboardingMaritalStatus` (ids = `.name`)
- Preferences : garder `AppTextField` ; CTA « Terminer sans soumettre » via `AppButton` variant text ou `TextButton` tokens (déjà OK)

- [ ] **Step 1: Write failing test**

```dart
testWidgets('flow has zero ChoiceChip through O04', (tester) async {
  // fill steps 0-2 via notifier, advance to faith
  expect(find.byType(ChoiceChip), findsNothing);
  expect(find.text('Célibataire'), findsOneWidget);
});
```

- [ ] **Step 2: Replace marital Wrap/ChoiceChip**

```dart
AppOptionCards(
  items: const [
    AppOptionItem(id: 'single', label: 'Célibataire'),
    AppOptionItem(id: 'divorced', label: 'Divorcé(e)'),
    AppOptionItem(id: 'widowed', label: 'Veuf / veuve'),
  ],
  selectedId: draft.maritalStatus?.name,
  errorText: errors['maritalStatus'],
  onSelected: (id) {
    final s = OnboardingMaritalStatus.values.firstWhere((e) => e.name == id);
    controller.updateDraft((d) => d.copyWith(maritalStatus: s));
  },
),
```

- [ ] **Step 3: Preferences - spacing `xxl` between fields ; optional use `AppButton(variant: text)` for Terminer sans soumettre**

- [ ] **Step 4: Run PASS + commit**

```bash
git commit -m "$(cat <<'EOF'
feat(onboarding): O04 O05 cards et spacing Datify

EOF
)"
```

---

### Task 9: Smoke flow + docs + analyze

**Files:**
- Modify: `test/features/onboarding/presentation/profile_onboarding/onboarding_flow_page_test.dart`
- Modify: `docs/design-inspiration.md` (section « État actuel »)
- Run full suite

- [ ] **Step 1: Extend smoke test**

Ajouter dans `onboarding_flow_page_test.dart` :

```dart
testWidgets('progress and custom widgets on O01', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: AppTheme.light,
        home: const OnboardingFlowPage(),
      ),
    ),
  );

  expect(find.byType(AppGenderCards), findsOneWidget);
  expect(find.byType(AppBirthDateField), findsOneWidget);
  expect(find.byType(AppCountryPicker), findsOneWidget);
  expect(find.byType(ChoiceChip), findsNothing);
  expect(find.text('Revenir plus tard'), findsOneWidget);
});
```

- [ ] **Step 2: Update design-inspiration.md**

Remplacer la section `## État actuel - l'onboarding profil n'est pas au niveau (2026-09-17)` par :

```markdown
## Onboarding profil O01-O05 - direction visuelle (2026-09-17)

Refonte livrée : widgets custom (`AppGenderCards`, `AppBirthDateField`,
`AppCountryPicker`, `AppPhotoGrid`) + chrome Nestle (progress segments).
Persistance Supabase / bandeau S02 : voir issue #8 / PR API.
```

Corriger tout tiret cadratin/demi-cadratin introduit dans ce bloc.

- [ ] **Step 3: Verify**

```bash
flutter analyze
flutter test
```

Expected: no issues / all tests pass

- [ ] **Step 4: Commit**

```bash
git add test/features/onboarding docs/design-inspiration.md
git commit -m "$(cat <<'EOF'
docs(onboarding): smoke redesign + lever flag #27

EOF
)"
```

---

## Spec coverage (self-review)

| Spec item | Task |
|---|---|
| AppGenderCards | 1, 5 |
| AppBirthDateField | 2, 5 |
| AppCountryPicker | 3, 5 |
| AppPhotoGrid | 4, 6 |
| Nestle progress (déjà en place) | 9 smoke ; polish si besoin dans flow page |
| Selfie polish live-only | 7 |
| O04/O05 patterns | 8 |
| Barrel exports | 1-4 |
| design-inspiration flag | 9 |
| Local only / pas API | Global Constraints |
| Tests no ChoiceChip / age validators | 5, 8, 9 + validators existants |

## Hors plan (PR2)

- SubmitOnboarding, FinishWithoutVerification, ProfileCompleteness, S02
- Spec : `2026-09-17-onboarding-api-s02-design.md`
