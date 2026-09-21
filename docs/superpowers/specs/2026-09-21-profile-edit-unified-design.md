# Design : Édition profil unifiée (C01 enrichi)

Date : 2026-09-21  
Branche cible : `feat/feed-discover-messages` (ou branche dédiée `feat/profile-edit-unified`)  
Réfs : PRD §5–6 / §14, screens-prd C00 / C01 / C02, D5, D10, spec C01 `2026-09-19-profile-c01-my-profile-design.md`

## Problème

Le crayon du hub (« Modifier mon profil ») ouvre encore `OnboardingFlowPage`.
Après validation des essentiels, genre / date de naissance / pays sont
**verrouillés** (PRD §5–6) : l’onboarding n’est plus le bon outil d’édition.
C01 existe déjà (photos + identité) mais n’inclut pas confession / situation /
pourquoi le mariage, et n’est pas branché sur le crayon.

## Décisions produit (validées)

| Sujet | Choix |
|---|---|
| Forme | **Écran d’édition unifié** (approche B) : C01 enrichi, pas de wizard multi-steps ni 3ᵉ route parallèle |
| Contenu | Delta onboarding éditable **+** identité C01 (photos, prénom, nom, ville, profession, bio) |
| Menu hub | **Fusion** : « Mon Profil » et le crayon ouvrent **la même page** |
| Approche code | **Étendre C01** (`MyProfilePage` / controller) plutôt qu’un 3ᵉ écran parallèle |
| Champs verrouillés | Genre, âge/DOB, pays : lecture seule + mention explicite |
| Hors page | Verset, témoignage, « ce que Dieu fait », Plus d’infos → restent **Ma Foi** / **Plus d’infos** |
| Onboarding | Réservé au **premier parcours** / essentiels encore manquants. Plus depuis « Modifier » |

## Périmètre

| Inclus | Hors scope |
|---|---|
| Grille photos C01 (quota 2 gratuit / 10 Premium) | Selfie live vérification (C09 / C16) |
| Photos read-only si `VERIFIED` (comportement C01 actuel) | Changer genre / DOB / pays |
| Prénom, nom, ville, profession, bio ≤600 | Tags C03, statut relationnel, taille, langues… |
| Switch déménagement (C01 actuel, best-effort colonne) | |
| Confession (liste fermée onboarding) | Rouvrir onboarding depuis le crayon |
| Situation matrimoniale (`marital_status`) | Checkout Premium |
| Pourquoi le mariage | `go_router` |
| Lien « Plus de détails dans Ma Foi » | |
| CTA Enregistrer unique + feedback | |
| Entrées : crayon, menu Mon Profil, bannière complétion (si essentials OK) | Bannière → onboarding **seulement** si essentials manquants |

## UI

- AppBar « Mon Profil », fond `surface` (D10), pas de chrome sombre onboarding.
- Body scrollable, composants DS existants uniquement.
- Ordre :
  1. Grille photos (`MyProfilePhotoGrid` + sheet caméra/galerie)
  2. Bloc lecture seule « Identité verrouillée » : 3 `AppSettingsRow` sans chevron (Genre / Âge / Pays) + texte secondaire *« Non modifiables après validation »*
  3. Identité : prénom, nom, ville, profession, bio + compteur, switch déménagement si colonne dispo
  4. Foi essentielle : confession (`AppSelectField` + `onboardingFaithConfessions`), situation (`AppOptionRows` / mapping marital onboarding), pourquoi le mariage
  5. Lien texte → `FaithPage`
- CTA sticky bas : **Enregistrer** (`AppButton`), loading, snackbar succès/erreur (`account_save_feedback`).
- États : skeleton load, erreur + Réessayer, empty soft si besoin.

## Technique

### État / controller

Étendre `MyProfileController` (ou renommer conceptuellement en « edit profile ») :

1. Load parallèle : `fetchMyProfile` + sous-ensemble foi (`denomination`, `whyMarriage` via `fetchFaith`) + `marital_status` (best-effort colonnes `profiles`).
2. État local unifié : identité C01 + `denomination` + `maritalStatus` + `whyMarriage`.
3. Save unique au tap :
   - `saveMyProfile` (identité + photos déjà gérées)
   - patch foi partielle (`church_denomination`, `why_marriage`) **sans** écraser verset / témoignage / autres champs Ma Foi
   - patch `marital_status` si colonne disponible
4. Échec partiel → message d’erreur clair, pas de snackbar succès trompeur.
5. Succès → snackbar, invalidation hub / `profileFieldsProvider` / complétude (comme C01 aujourd’hui).

### Navigation

| Entrée | Cible |
|---|---|
| Crayon hub | `MyProfilePage` (plus `OnboardingFlowPage`) |
| `ProfileHubSection.profile` | `MyProfilePage` (inchangé, contenu enrichi) |
| Bannière complétion | `MyProfilePage` si essentiels présents ; sinon `OnboardingFlowPage` |
| Photos management / C16 liens vers C01 | Restent sur `MyProfilePage` |

### Réemploi

`MyProfilePhotoGrid`, `AppTextField`, `AppSelectField`, `AppOptionRows`,
`AppSettingsRow` / `AppSettingsGroup`, mappings onboarding
(`onboardingFaithConfessions`, marital labels/ids), `SaveMyProfile`,
`SaveFaithDetails` (ou patch dédié partiel), feedback save existant.

### Docs

- Entrée `decisions.md` : crayon → édition unifiée C01 enrichi ; onboarding
  réservé au premier passage / essentials manquants.
- Mettre à jour `screens-prd.md` C01 / note hub crayon si besoin.

## Tests

| Zone | Cas |
|---|---|
| Widget page | Sections présentes ; locked rows non éditables ; CTA Enregistrer |
| Controller | Load merge identité + foi + marital ; save double/triple patch ; erreur partielle |
| Hub | Crayon n’ouvre plus `OnboardingFlowPage` ; ouvre `MyProfilePage` |
| Régression C01 | Photos VERIFIED read-only ; bio 600 ; save identité seul toujours OK |
| Ma Foi | Champs avancés inchangés après save depuis Mon Profil |

## Hors décisions (inchangé)

- Q2 / Q3 / Q4 (paiement, push, deep links ops)
- Flag `kBypassPremiumGatesForTesting` (Découvrir)
- Selfie anti-usurpation hors onboarding (D5)
