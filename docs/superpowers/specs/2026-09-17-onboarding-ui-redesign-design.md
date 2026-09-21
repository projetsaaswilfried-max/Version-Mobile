# Design : redesign UI onboarding O01-O05 (dette #27)

Date : 2026-09-17  
Dette : [#27](https://github.com/BespokApps/agapeo-mobile/issues/27) (flag design-inspiration)  
Prépare : [#8](https://github.com/BespokApps/agapeo-mobile/issues/8) (API empilée ensuite)  
Réfs : `docs/design-inspiration.md`, Nestle (chrome / progress), Datify (sélecteurs / photos), PRD §5

## Contexte

O01-O05 existent en draft local (PageView + Riverpod) mais s’appuient sur des
composants Material bruts (`ChoiceChip`, `showDatePicker`, `DropdownButton`,
slot photo vide). La direction produit exige un niveau dating « pro »
(Nestle structure + Datify composants), tokens only. Cette PR ne touche
pas Supabase : l’API et S02 viennent en PR empilée.

## Décisions produit

| Sujet | Choix |
|---|---|
| Ordre pile | Redesign local d’abord, API ensuite |
| Profondeur UI | Flow entier O01-O05 + widgets custom (pas un restyle tokens) |
| Direction visuelle | Nestle (progress, headers) + Datify (cards / pickers / grille photos) |
| Architecture widgets | Extraire dans `core/widgets` (réutilisable Mon compte) |
| Persistance | Toujours locale (`OnboardingDraft`) ; snackbars « hors ligne » inchangées |
| Navigation sortie | HomeShell (déjà en place via #7 / #28) |

## Périmètre

### Inclus

- Widgets design-system :
  - `AppGenderCards`
  - `AppBirthDateField` (champ + bottom sheet roue jour/mois/année)
  - `AppCountryPicker` (champ + sheet search + `kOnboardingCountries`)
  - `AppPhotoGrid` (slots, thumbs, add / remove)
- Refonte visuelle des 5 steps + chrome Nestle (progress segments, titres)
- Selfie O03 : polish UI, caméra front live only (pas d’import)
- O04 / O05 : mêmes patterns (cards / list tiles custom, `AppTextField`)
- Export barrel `core/widgets/widgets.dart`
- Retirer / adoucir le flag « pas au niveau » dans `design-inspiration.md`
- Tests widget mis à jour (plus de `ChoiceChip` sur le flow)

### Hors scope

- Écriture Supabase / Storage / `onboarding_completed`
- Verrouillage serveur genre / DOB / pays
- Bandeau S02
- Premium (10 photos), `go_router`

## Architecture

```
lib/core/widgets/
  app_gender_cards.dart
  app_birth_date_field.dart
  app_country_picker.dart
  app_photo_grid.dart
  widgets.dart                 # barrel

lib/features/onboarding/presentation/profile_onboarding/
  onboarding_flow_page.dart    # progress Nestle (existant, polish)
  steps/*.dart                 # branchés sur les widgets core
  onboarding_draft.dart        # inchangé fonctionnellement
  onboarding_flow_controller.dart
```

**État :** `onboardingFlowProvider` inchangé (draft + step + fieldErrors).  
Les widgets core sont présentationnels : callbacks `onChanged` / `ValueChanged`,
pas de Riverpod interne.

## UI

### Chrome commun (Nestle)

- Progress : 5 segments sous le back ; actif = `primary`, inactif = `border`
- Header step : grand titre + sous-titre `textSecondary`
- Footer : Suivant / Soumettre + Revenir plus tard + (O05) Terminer sans soumettre

### O01 Essentials

- Genre : cards (icône + label), bordure `primary` si sélectionné
- Naissance : champ read-only style `AppTextField` → sheet roue ; ≥18
- Pays : champ → sheet search + liste

### O02 Photos

- Grille 2 slots (gratuit) : thumb `Image.file`, `+` vide, `×` retirer
- Pas de rectangle « appareil photo » seul

### O03 Selfie

- Grande preview + CTA « Prendre le selfie » (front) ; état vide illustré
- Aucun chemin galerie

### O04 / O05

- Selects type cards ou tiles custom ; multi-ligne pour pourquoi mariage
- Espacement généreux, pas de densification Material

## Tests

### Automatisés

- Smoke O01-O05 : widgets custom présents ; absence de `ChoiceChip` sur le flow
- Draft : genre / date / pays / photos mettent à jour l’état ; Suivant gated
- Progress : step N allume N segments
- Âge < 18 : erreur, pas d’avance

### Manuel

- [ ] Parcours O01→O05 fluide, look Nestle+Datify, tokens only
- [ ] Photo pick / preview / remove ; selfie caméra front
- [ ] Revenir plus tard + Terminer sans soumettre → HomeShell
- [ ] `flutter analyze` + `flutter test` verts

## Acceptation

- [ ] Aucun sélecteur Material brut listé dans `design-inspiration.md` sur O01-O05
- [ ] Widgets réutilisables exportés via `widgets.dart`
- [ ] Comportement draft / validation / sortie inchangé (local)
- [ ] Flag dette #27 résorbé côté docs (ou reformulé « livré PR redesign »)

## Stack Git

1. Branche : `feat/onboarding-ui-redesign` depuis `main`
2. PR vers `main`
3. Body : référence #27 ; prépare #8
4. PR2 (`feat/onboarding-api`) empilée ensuite sur cette branche

## Suite

Spec API + S02 : `2026-09-17-onboarding-api-s02-design.md`  
Puis plans d’implémentation séparés (PR1 puis PR2).
