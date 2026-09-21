# Design : Découvrir D05 like + « Valide ton profil »

Date : 2026-09-19  
PR : [#34](https://github.com/BespokApps/agapeo-mobile/pull/34) (même branche)  
Réfs : PRD §3 / §18, screens-prd D05, D03 fiche, D04 stub vérif

## Contexte

D03 livre la fiche avec Like / Favori / Inviter en stub. PRD §3 : liker un
profil exige `VERIFIED` (gratuit, pas Premium) ; sinon modale « Valide ton
profil ». Les likes vivent dans `profile_likes`.

D05 branche le **like** (toggle) et la sheet de validation. Favori et
invitation restent hors slice (stubs D03 / D06).

## Décisions produit

| Sujet | Choix |
|---|---|
| Approche | **A** : sheet validation + toggle like réel |
| Qui peut liker | `visitorVerified` **ou** staff (`visitorIsStaff`) |
| Sinon | Bottom sheet « Valide ton profil » (pas de like écrit) |
| Toggle | Like / unlike sur `profile_likes` ; bouton plein / vide |
| Entry point | Bouton Like de `DiscoverProfileSheet` uniquement (pas la carte liste) |
| Favori / Invitation | Stubs inchangés |
| CTA vérif | « Vérifier mon profil » → même comportement D04 (`_onVerifyProfile` / snackbar « bientôt » ou écran s’il existe) |

## Architecture

```
lib/features/discover/
  domain/
    premium/ ou gating/          # canLikeDiscoverProfile (ou dans discover_premium_gate)
    usecases/like_discover_profile.dart
    usecases/unlike_discover_profile.dart
    repositories/…               # + isLikedByMe, like, unlike
  data/…                         # profile_likes select / insert / delete
  presentation/
    widgets/discover_verify_sheet.dart   # NEW
    widgets/discover_profile_sheet.dart  # wire Like + likedByMe state
```

### Helper

```dart
bool canLikeDiscoverProfile({
  required bool visitorVerified,
  bool isStaff = false,
}) => isStaff || visitorVerified;
```

### Flux Like

```
tap Like
  if !canLike → DiscoverVerifySheet.show ; stop
  else if likedByMe → Unlike ; UI vide
  else → Like ; UI plein
  on error → snackbar ; rollback UI si optimistic (optionnel : sync simple OK)
```

### Data

- Au succès de `GetDiscoverProfileDetail` (ou en parallèle) : `likedByMe` pour
  `(viewerId, viewedId)`.
- Table `profile_likes` : colonnes typiques `liker_id` / `liked_id` (ou
  `viewer` / `profile`) — **confirmer noms exacts** à l’implémentation
  (comme RPC D03). Insert unique ; delete sur unlike.
- Étendre `DiscoverProfileDetail` avec `likedByMe` **ou** state local dans
  le sheet après fetch séparé.

## UI sheet « Valide ton profil »

- Bottom sheet (pas dialog)
- Titre + court texte : pour liker / interagir, valide ton profil
- Primaire : « Vérifier mon profil »
- Secondaire : Fermer / Quitter

## Tests

- Gate : verified/staff → true ; unverified → false
- Usecase like/unlike délègue ; erreurs propagées
- Widget : !verified → sheet Valide ; verified → toggle UI ; erreur snackbar
- `flutter analyze` + `flutter test`

## Hors scope

- Favori réel (VERIFIED + ACTIVE)
- Invitation (D06)
- Parcours vérification selfie complet
- Liste « qui m’aime » / notifications
- Like depuis la carte liste
