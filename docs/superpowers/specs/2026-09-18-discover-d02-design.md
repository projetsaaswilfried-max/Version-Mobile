# Design : Découvrir D02 recherche / filtres (chrome)

Date : 2026-09-18  
PR : [#34](https://github.com/BespokApps/agapeo-mobile/pull/34) (même branche que D01 / D04)  
Réfs : PRD §3 / §7, screens-prd D02, design-inspiration (bottom sheet), D04

## Contexte

D01 livre la liste. D04 livre sheet Premium + bannières. Sur le web, Découvrir
affiche une barre recherche verrouillée (« Passe Premium pour rechercher ») et
un bouton Filtres pour les comptes non Premium.

D02 porte ce **chrome** sur mobile. Aucune vraie recherche ni filtrage data
dans cette slice.

## Décisions produit

| Sujet | Choix |
|---|---|
| Approche | **A** : chrome seul (pas de requête / filtre domaine) |
| Compte !ACTIVE (FREE / CANCELED) | Champ readonly + Filtres ; tap → `DiscoverPremiumSheet` (réutilise D04) |
| Compte ACTIVE ou staff | Champ / Filtres déverrouillés visuellement ; tap → snackbar « bientôt » |
| Tap Filtres (!ACTIVE) | Sheet Premium **direct** (pas de sheet filtres avec cadenas) |
| Mur EXPIRED | Pas de barre (écran mur D01 inchangé) |
| Placement | Sous bannières D04 (si présentes), au-dessus des sections reco / autres |
| Visible aussi si | Liste empty (après load OK) ; pas sur loading initial skeleton pur, erreur, EXPIRED |

## Helper domain

```dart
bool canUseDiscoverSearchFilters({
  required String subscriptionStatus,
  bool isStaff = false,
}) {
  if (isStaff) return true;
  return subscriptionStatus == 'ACTIVE';
}
```

Distinct de `shouldShowDiscoverPremiumSheet` : EXPIRED ne voit ni sheet ni barre.

## UI

### Champ recherche

| État | Comportement |
|---|---|
| !canUse | `readOnly` / non focusable ; hint `Passe Premium pour rechercher` ; tap → sheet Premium |
| canUse | Hint `Rechercher un profil` ; focus OK ; submit / action → snackbar `Recherche : bientôt` |

Pas de debounce, pas d’appel repository.

### Bouton Filtres

Toujours à droite du champ (icône + libellé ou icône seule, tokens design system).

| État | Comportement |
|---|---|
| !canUse | Tap → `DiscoverPremiumSheet.show` |
| canUse | Tap → snackbar `Filtres : bientôt` |

## Architecture

```
lib/features/discover/
  domain/premium/discover_premium_gate.dart   # + canUseDiscoverSearchFilters
  presentation/widgets/discover_search_bar.dart
  presentation/discover_body.dart             # injecte la barre
  presentation/discover_state.dart            # getter canUseSearchFilters (optionnel)
```

Pas de nouveau state filtre / query. Pas de changement datasource / usecase D01.

## États

| Condition | Barre | Tap |
|---|---|---|
| FREE / CANCELED | oui (locked) | sheet Premium |
| ACTIVE / staff | oui (unlocked) | snackbar |
| EXPIRED | non | - |
| Loading initial | non (skeleton) | - |
| Erreur | non | - |
| Empty (load OK) | oui | selon abo |

## Tests

- Domain : ACTIVE → true ; FREE → false ; CANCELED → false ; EXPIRED → false ; staff → true
- Widget : locked → sheet au tap champ / Filtres
- Widget : ACTIVE → pas de sheet, snackbar
- Widget : barre absente si `expired`
- `flutter analyze` + `flutter test` ; `ios_dev.sh restart` si session QA

## Hors scope

- Filtrage réel (ville, dénomination, profession…)
- Sheet filtres avec champs + cadenas
- Re-trigger sheet D04 sur « changement de filtre » (PRD §7) : uniquement quand le vrai filtre existera
- D03 fiche / D05 like / D06 invitation
