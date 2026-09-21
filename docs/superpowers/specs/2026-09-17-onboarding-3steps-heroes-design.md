# Design : onboarding profil 3 steps + heroes (suite redesign #27)

Date : 2026-09-17  
Branche : `feat/onboarding-ui-redesign`  
Réfs : PRD §5 (delta mobile D5), design-inspiration, ref visuelle fitness (hero + 1 focus / écran)  
Prépare : API #8 (hors scope ici)

## Contexte

Le redesign widgets (Nestle/Datify) est en place sur 5 steps Material-remplacés.
Le porteur produit recentre le flow : **3 étapes max**, illustrations
rassurantes en haut, photo **skippable** avec warning, vérif selfie live
reportée hors onboarding.

## Décisions produit

| Sujet | Choix |
|---|---|
| Nombre d'étapes | 3 : Essentiels → Foi → Photo |
| Essentiels | Genre, date naissance, pays (widgets custom existants) |
| Foi | Confession + situation matrimoniale + pourquoi mariage (taille hors V1) |
| Photo | 1 photo profil : caméra **ou** galerie ; skippable |
| Selfie live anti-usurpation | Hors onboarding (Mon compte / soumission vérif) |
| Skip Essentiels / Foi | Interdit : pas de « Revenir plus tard » sur steps 1-2 |
| Skip Photo | « Passer » + dialog warning (pas vérifié / pas visible sans photo) |
| Heroes | Illustrations soft / flat-3D légères, une par step (placeholders OK) |
| API | Toujours local only dans cette itération |

Voir **D5** dans `docs/decisions.md`.

## Périmètre

### Inclus

- Réduire `OnboardingFlowState.stepCount` à 3
- Fusionner foi + pourquoi mariage en un step
- Nouveau step photo (caméra / galerie) + skip warning
- Retirer du flow : multi-photos O02, selfie live O03, prefs isolées O05
- `OnboardingStepHero` + 3 assets (`AppAssets`)
- Footer conditionnel (« Revenir plus tard » seulement step 3 si conservé)
- Renommer chemin photo : `profilePhotoPath` (remplace usage onboarding de `selfiePath`)
- Tests + maj smokes
- Décision D5

### Hors scope

- Persistance Supabase / Storage / S02 / `onboarding_completed`
- Illustrations marketing finales (placeholders brand acceptés)
- Prefs avancées (âge recherché, pays acceptés, bio longue)
- Taille (cm)

## Architecture

```
lib/features/onboarding/presentation/profile_onboarding/
  onboarding_flow_page.dart       # 3 segments, footer conditionnel
  onboarding_draft.dart           # profilePhotoPath, skippedPhoto
  onboarding_flow_controller.dart # skipPhoto(), validators 3 steps
  widgets/onboarding_step_hero.dart
  steps/essentials_step.dart      # + hero
  steps/faith_why_step.dart       # nouveau (ou faith_step enrichi)
  steps/profile_photo_step.dart   # nouveau
```

Assets : `assets/images/onboarding/hero_essentials.*` (idem faith / photo)  
via `AppAssets.onboardingHeroEssentials` etc.

Anciens steps (`photos_step`, `selfie_step`, `preferences_step`) : retirés du
PageView ; fichiers supprimés ou laissés non référencés (préférer supprimer
si plus d'imports).

## UI

### Chrome

- Progress 3 segments (`primary` / `border`)
- Fond `surface` ; tint léger `primaryLight` optionnel (tokens only)
- CTA : Continuer (1-2) / Terminer (3 si photo) / Passer (3)

### Hero

- Hauteur bornée (~140-180 dp), illustration centrée, pas de badges flottants
- Titre + 1 ligne secondary sous le hero

### Step 1

Hero identité + `AppGenderCards` + `AppBirthDateField` + `AppCountryPicker`

### Step 2

Hero foi + confession + `AppOptionCards` situation + `AppTextField` pourquoi mariage

### Step 3

Hero photo + preview slot + « Prendre une photo » / « Choisir dans la galerie »  
Passer → dialog :

> Sans photo, ton profil ne sera pas vérifié ni visible. Tu pourras en ajouter plus tard.

Actions : Annuler / Continuer sans photo

## Tests

### Automatisés

- `stepCount == 3`
- Steps 1-2 : absence « Revenir plus tard » ; Suivant gated
- Step 2 : champs confession / situation / pourquoi
- Step 3 : Passer → dialog ; confirmer → `completedLocally` + `skippedPhoto`
- Heroes / assets référencés (smoke find ou type `OnboardingStepHero`)
- Plus de smoke 5-steps / SelfieStep live dans le flow

### Manuel

- [ ] Parcours 3 steps + heroes
- [ ] Skip photo : warning puis shell
- [ ] Caméra et galerie → preview → Terminer
- [ ] Analyze + tests verts

## Acceptation

- [ ] 3 steps max, non skippable avant Photo
- [ ] Photo import OK ; selfie live vérif hors flow
- [ ] Warning skip photo explicite
- [ ] D5 documentée
- [ ] Local only (pas d'API)

## Suite

1. Plan d'implémentation
2. Puis PR2 API (#8) adaptée au draft 3 steps
