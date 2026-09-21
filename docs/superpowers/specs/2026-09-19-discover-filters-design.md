# Design : Découvrir filtres + recherche (D02+)

Date : 2026-09-19  
PR : [#34](https://github.com/BespokApps/agapeo-mobile/pull/34)  
Réfs : PRD §3 / §7, D02 chrome, D04 sheet

## Décisions

| Sujet | Choix |
|---|---|
| Qui filtre | ACTIVE ou staff (`canUseDiscoverSearchFilters`) |
| FREE | Chrome D02 inchangé → Premium sheet |
| Filtres V1 | Ville (texte), dénomination (texte), profession (texte) ; champs vides = ignore |
| Recherche | Query texte sur displayName / city (client après fetch candidats ou filtre local sur listes chargées) |
| Appliquer | Reset pagination + reload `loadInitial` avec `DiscoverQuery` ; après load OK, sheet Premium D04 si FREE (déjà) / aussi si changement filtre pour non-premium N/A |
| Sheet filtres | Bottom sheet + Appliquer / Réinitialiser / Fermer |
| Hors scope | Tous les champs §6, géoloc, score-only filters |

## Modèle

```dart
class DiscoverQuery {
  const DiscoverQuery({this.search, this.city, this.denomination, this.profession});
  final String? search;
  final String? city;
  final String? denomination;
  final String? profession;
  bool get isEmpty => ...;
}
```

Filtrage : de préférence **client** sur les candidats déjà éligibles (vivier D01) pour V1, afin d’éviter une query PostgREST fragile. Si search/filters actifs, sections reco + autres = sous-ensemble filtré (reco peut être vide).

## Wire

- `DiscoverSearchBar` unlocked : submit → set search + reload
- Filtres unlocked → `DiscoverFiltersSheet` → Appliquer → state + reload
- Chips actifs optionnels sous la barre (ville / etc.) avec clear

## Tests

Query matching ; unlocked apply reloads ; locked still Premium.
