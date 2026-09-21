# Design : Profil C00 hub

Date : 2026-09-19  
PR : empilée sur [#43](https://github.com/BespokApps/agapeo-mobile/pull/43)  
Réfs : PRD §6 / §14, screens-prd C00–C08 / C14, D4, D5

## Périmètre

Remplacer le stub de l'onglet Profil par le **hub Mon compte** (identité + 8 sections).

| Inclus | Hors slice |
|---|---|
| En-tête photo / prénom / badge VERIFIED | Aperçu profil public réel |
| CTA Voir mon profil public (snackbar) | C01–C03, C05–C08 écrans réels |
| CTA Modifier → onboarding existant | C09–C16, P01 Premium |
| 8 lignes PRD §14 ; C04 → `MyPostsPage` | Mur EXPIRED |
| Stubs snackbar « bientôt » | Second bandeau S02 (reste sur le shell) |
| Déconnexion (comportement actuel) | `go_router` |

## Décisions

| Sujet | Choix |
|---|---|
| Approche | **B** : `GetProfileHub` dans `profile/`, pas d'import Découvrir |
| Layout | Identité d'abord, puis les 8 lignes, déconnexion en bas |
| Profil public | Stub snackbar |
| Data | Repo **fields** existant + select nom / vérif / photo primaire |
| Nom vide | Email de session |
| Nom affiché | `first_name` + `last_name` trim, sinon email |
| Photo absente | Placeholder |
| Badge | Uniquement si `photo_verification_status == VERIFIED` |
| Premium / EXPIRED | Hors hub |

## UI

- AppBar « Profil » (même chrome que Découvrir / Messages)
- Body scrollable + `HomeFloatingNavBar.scrollClearance`
- En-tête : avatar, nom affiché (prénom + nom), badge vérifié
- Actions texte : Voir mon profil public · Modifier
- Liste : Mon Profil, Ma Foi, Plus d'infos, Mes Publications, Mes Favoris, Qui s'intéresse à moi, Confidentialité, Compte & Sécurité
- Skeleton load ; erreur + Réessayer (déconnexion reste visible) ; pull-to-refresh

## Architecture

```
lib/features/profile/
  domain/entities/profile_hub.dart          # displayName, photoUrl, isVerified
  domain/entities/profile_hub_section.dart  # enum 8 sections + labels
  domain/usecases/get_profile_hub.dart
  data/…                                    # étendre fields datasource/repo
  presentation/hub/
    profile_hub_controller.dart
    profile_hub_state.dart
    profile_hub_body.dart
    widgets/…                               # header, row
```

`ProfileTabPage` : AppBar + `ProfileHubBody`.

## Flux

```
load hub → GetProfileHub
  Ok  → header + 8 rows
  Err → erreur + Réessayer ; Déconnexion visible

tap Voir mon profil public / C01–C03 / C05–C08 → snackbar bientôt
tap Modifier → OnboardingFlowPage
tap Mes Publications → MyPostsPage
tap Déconnexion → signOut + WelcomePage (inchangé)
```

## Tests

- Domain : nom (prénom+nom / fallback email), badge, photo nulle
- Widget : 8 lignes, C04 pousse `MyPostsPage`, stubs + profil public snackbar, Modifier → onboarding, Déconnexion
- `flutter analyze` + `flutter test`
