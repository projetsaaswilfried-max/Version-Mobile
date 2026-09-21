# Design : Profil C01 Mon Profil

Date : 2026-09-19  
Branche : `feat/profile-c01` empilée sur `feat/profile-c00`  
Réfs : PRD §6 / §14, screens-prd C01 / C16, D5

## Périmètre

Remplacer le snackbar hub **Mon Profil** par l'écran d'édition C01.

| Inclus | Hors slice |
|---|---|
| Photos max 2 (gratuit) | Quota Premium 10, C16 selfie live |
| Si `VERIFIED` : galerie lecture seule | Ajout/retrait photo vérifié |
| Sinon : ajouter / retirer, 1re = primaire, `DRAFT` | Foi, Plus d'infos, C03 tags |
| Prénom, nom, ville, profession | Études, langues, taille, matrimonial, statut, citation |
| Bio ≤600 + compteur | Profil public réel |
| Switch déménagement | Mur EXPIRED, P01 |
| Genre / date / pays lecture seule | `go_router` |
| Enregistrer + refresh hub | |

## Décisions

| Sujet | Choix |
|---|---|
| Approche | **B** : `GetMyProfile` / `SaveMyProfile` dans `profile/`, pas d'import Découvrir, pas de gonflement S02 |
| Champs | **A** : sous-ensemble « vu » / §14 |
| Photos `VERIFIED` | **B** : lecture seule |
| Colonne déménagement | Best-effort live (`willing_to_relocate` ou équivalent). Si absente : switch masqué, save ignore le champ |
| Photo locale vs URL | Grille C01 accepte `http(s)` **et** path fichier (AppPhotoGrid actuel = File only) |
| Après save | Snackbar courte, `pop`, recharger hub + `profileFieldsProvider` |

## UI

- AppBar « Mon Profil » + retour
- Body scrollable
- Grille photos (2 slots). `VERIFIED` : pas de bouton Ajouter / Retirer. Sinon : Ajouter (sheet caméra/galerie existant) / Retirer
- Champs : prénom, nom, ville, profession (`AppTextField`)
- Genre, date de naissance, pays : texte secondaire, non éditables
- Bio multiligne, compteur `n/600`, bloquer au-delà
- Switch « Prêt à déménager » (libellé court, si colonne connue)
- `Enregistrer` bas d'écran, `isLoading` pendant save
- Skeleton load ; erreur + Réessayer

## Architecture

```
lib/features/profile/
  domain/entities/my_profile.dart           # locked + éditables + photos + isVerified
  domain/entities/my_profile_photo.dart     # id?, url?, localPath?
  domain/usecases/get_my_profile.dart
  domain/usecases/save_my_profile.dart
  data/…                                    # datasource dédié (pas ProfileFieldsSnapshot)
  presentation/my_profile/
    my_profile_page.dart
    my_profile_controller.dart
    my_profile_state.dart
    widgets/…
```

Hub : `ProfileHubSection.profile` → `Navigator.push` `MyProfilePage` (plus de snackbar).

## Flux

```
hub Mon Profil → GetMyProfile
  Ok  → formulaire
  Err → erreur + Réessayer

VERIFIED : photos affichées, pas d'add/remove
sinon : add jusqu'à 2, remove, slot 0 = primaire

Enregistrer → SaveMyProfile
  Ok  → snackbar, pop, refresh hub + fields
  Err → message sous le bouton / snackbar, rester sur la page
```

## Tests

- Domain : bio >600 rejetée ; `VERIFIED` ignore les mutations photo côté save
- Widget : hub pousse `MyProfilePage` ; champs visibles ; compteur bio ; save pop
- `flutter analyze` + `flutter test`
