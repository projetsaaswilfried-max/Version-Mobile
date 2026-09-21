# Design : Découvrir Favori

Date : 2026-09-19  
PR : [#34](https://github.com/BespokApps/agapeo-mobile/pull/34)  
Réfs : PRD §3 / §18, D03 fiche, D05 like / vérif, D04 Premium

## Décisions

| Sujet | Choix |
|---|---|
| Entry | Bouton Favori de `DiscoverProfileSheet` |
| Toggle | Insert / delete `favorites` |
| Gates | !VERIFIED (pas staff) → `DiscoverVerifySheet` ; VERIFIED + !ACTIVE → `DiscoverPremiumSheet` ; ACTIVE ou staff → toggle |
| Après succès | Icône plein / vide |
| Hors scope | Écran Mes Favoris (C05), notifications |

## Helper

```dart
bool canFavoriteDiscoverProfile({
  required bool visitorVerified,
  required String subscriptionStatus,
  bool isStaff = false,
}) {
  if (isStaff) return true;
  return visitorVerified && subscriptionStatus == 'ACTIVE';
}
```

Ordre des sheets si !canFavorite : d’abord vérif si !verified ; sinon Premium.

## Data

- `isFavorited`, `favoriteProfile`, `unfavoriteProfile` sur repo
- Colonnes typiques `user_id` / `favorited_id` (confirmer à l’impl)

## Tests

Gate, usecases, widget gates + toggle.
