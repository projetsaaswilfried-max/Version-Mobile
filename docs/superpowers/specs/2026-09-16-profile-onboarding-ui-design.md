# Design : Onboarding profil O01–O05 (draft local, hors API)

**Date** : 2026-09-16  
**Issue** : suite #5 / préparation #8  
**Branche prévue** : `feat/profile-onboarding-ui`  
**Statut** : validé en brainstorming

## Contexte

Après auth, le PRD §5 impose un assistant 3–5 étapes. Le routage post-login
(#6) et la persistance Supabase (#8) ne sont pas prêts. On prépare l’UI +
state local pour pouvoir compléter le parcours sur le simu.

## Décisions

| Sujet | Choix |
|---|---|
| Profondeur | UI + Riverpod local, **pas** d’écriture API/Supabase |
| Entrée | CTA temporaire sur stub « Connecté » |
| Selfie O03 | Caméra live réelle (capture locale) |
| Architecture | PageView + `OnboardingDraft` unique (approche 1) |
| Fin | Soumettre / Terminer sans soumettre → snackbar + retour stub |

## Architecture

```
lib/features/onboarding/presentation/profile_onboarding/
  onboarding_draft.dart
  onboarding_flow_controller.dart
  onboarding_flow_page.dart
  steps/
    essentials_step.dart
    photos_step.dart
    selfie_step.dart
    faith_step.dart
    preferences_step.dart
```

`NotifierProvider.autoDispose` : `draft` + `currentStep` + `fieldErrors`.

Validation pure : `canGoNext(step)` / messages FR.

## Étapes (champs)

| Step | Contenu | Continuer si |
|---|---|---|
| O01 | Genre, date naissance (≥18), pays | 3 OK |
| O02 | Photos (`image_picker`), min 1, max 2 free | ≥1 |
| O03 | Selfie caméra live, pas d’import | 1 capture |
| O04 | Confession (req), situation matrimoniale, taille opt. | confession + situation |
| O05 | Pourquoi mariage (req) + prefs basiques ; « Terminer sans soumettre » | pourquoi OK ou skip |

## Complétion locale

- **Soumettre** (O05 valide) → `completedLocally` + snackbar → stub  
- **Terminer sans soumettre** → `skippedVerification` + snackbar → stub  
- Draft jeté à la sortie (`autoDispose`)

## Tests

- Unit validation âge / photos / pourquoi  
- Smoke : stub → flow → progress ; Suivant bloqué puis OK  
- Manuel simu 5 étapes  

## Hors scope

Supabase / Storage, routage #6, shell, age gate, sync Dio.
