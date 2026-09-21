# Design : Découvrir D03 fiche profil

Date : 2026-09-18  
PR : [#34](https://github.com/BespokApps/agapeo-mobile/pull/34) (même branche que D01 / D02 / D04)  
Réfs : PRD §3 / §6 / §7 / §18, screens-prd D03, design-inspiration (bottom sheet), D02 gate

## Contexte

D01 livre la liste. D02 / D04 le chrome paywall. Sur le web, le tap d’une carte
ouvre une fiche (modale) si Premium ; sinon la modale « Passe Premium ».
L’ouverture d’une fiche enregistre une vue via `record_profile_view` (RPC).

D03 porte cette fiche sur mobile en bottom sheet, sans brancher like / favori /
invitation (D05 / D06).

## Décisions produit

| Sujet | Choix |
|---|---|
| Approche | **B** contenu : fiche réelle si Premium ; gate FREE |
| Data | **A** : fetch détail + `record_profile_view` après succès |
| Qui ouvre la fiche | `subscription_status == ACTIVE` **ou** staff (même règle que `canUseDiscoverSearchFilters`) |
| Qui voit le sheet Premium | Tap carte si !canOpen (FREE / CANCELED) ; EXPIRED reste le mur liste |
| UI fiche | Bottom sheet ~90 % hauteur, scrollable, handle + fermer |
| Contenu V1 | Photos (carrousel), nom · âge · ville, badge vérifié, score, confession / engagement / pourquoi mariage / valeurs / loisirs (sections vides omises) |
| Actions | Like / Favori / Inviter : stubs snackbar « bientôt » |
| `record_profile_view` | Une fois après fetch détail OK ; jamais si gate Premium / erreur |

## Helper

Réutiliser `canUseDiscoverSearchFilters` (alias optionnel `canOpenDiscoverProfile`
qui délègue). Pas de troisième matrice d’abo.

## Architecture

```
lib/features/discover/
  domain/
    entities/discover_profile_detail.dart   # NEW (id, photos[], champs texte…)
    repositories/discover_repository.dart   # + fetchDetail + recordView
    usecases/get_discover_profile_detail.dart
    usecases/record_discover_profile_view.dart
  data/
    datasources/…                           # select profiles + photos ; rpc
    repositories/discover_repository_impl.dart
  presentation/
    widgets/discover_card.dart              # + onTap
    widgets/discover_profile_sheet.dart     # NEW
    discover_body.dart                      # wire tap
```

Pas de nouvelle feature folder : reste dans `discover/`.

### Entity détail (V1)

Champs minimaux : `id`, `displayName`, `age`, `city`, `photoUrls` (liste HTTP),
`isVerified`, `score` (passé depuis la carte ou recalculé si dispo),
`confession`, `spiritualEngagement`, `whyMarriage`, `values`, `hobbies`.
Null / listes vides → section non affichée.

### RPC / data

- `record_profile_view` : unique chemin d’écriture (PRD §18) ; jamais insert direct
  sur `profile_views`.
- Fetch : ligne `profiles` (+ embed / query `profile_photos` APPROVED ou URLs
  hydratées comme D01). Réutiliser le pattern d’hydratation photos par lots si besoin.

## Flux tap carte

```
tap DiscoverCard
  if !canOpen → DiscoverPremiumSheet.show ; stop
  else → DiscoverProfileSheet.show(profileId, scoreHint?)
           → loading
           → GetDiscoverProfileDetail
           → on success: RecordDiscoverProfileView puis UI
           → on failure: erreur + Réessayer (pas de record)
```

## États sheet

| État | UI |
|---|---|
| Loading | Skeleton / indicateur |
| Erreur | Message + Réessayer |
| Succès | Contenu + barre actions stub |

## Tests

- Gate : ACTIVE/staff → true ; FREE/CANCELED/EXPIRED → false (déjà D02 ; alias si ajouté)
- Usecase / repo : fetch OK ; record appelle RPC ; échec fetch → pas de record
- Widget sheet : loading / erreur / succès ; stubs snackbar
- Body : FREE tap → sheet Premium ; (si possible) ACTIVE tap → sheet fiche
- `flutter analyze` + `flutter test` ; `ios_dev.sh restart` si QA

## Hors scope

- Like / favori / invitation réels (D05 / D06)
- Posts personnels sur la fiche
- Deep link `/profile/:id`
- Bloquer / signaler
- Fiche PRD §6 exhaustive (tous les champs)
