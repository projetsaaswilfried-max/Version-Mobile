# Design : capsule flottante S01 (bottom nav)

Date : 2026-09-18  
Réfs : D4, `docs/superpowers/specs/2026-09-17-home-shell-design.md`, `docs/design-inspiration.md`

## Contexte

Le shell a 4 onglets (D4). Le chrome actuel est un `NavigationBar` Material collé, fond `surface` opaque. On aligne le chrome sur la tendance 2025-26 (capsule inset, contenu qui passe derrière) sans changer les destinations.

## Décisions

| Sujet | Choix |
|---|---|
| Destinations | Inchangées : Fil, Découvrir, Messages, Profil (D4) |
| Labels | Toujours visibles (pas d’icônes seules) |
| Forme | Capsule stadium, inset horizontal `AppSpacing.lg`, au-dessus du home indicator |
| Fond | `surface` à ~82 % d’opacité + `BackdropFilter` (sigma ~16). Pas de Liquid Glass iOS. |
| Item actif | Icône + label `primary` ; pastille stadium discrète (`primary` ~12 % d’alpha) derrière l’item. Pas d’indicateur Material pleine largeur. |
| Item inactif | `textSecondary` |
| Corps | `Scaffold.extendBody: true` : le fil / listes passent derrière la capsule |
| S02 | Inchangé : sticky en haut du shell, au-dessus de l’`IndexedStack` |
| État | `homeShellIndexProvider` inchangé |

## Hors scope

- 5e onglet, FAB central, cacher les labels
- Refonte AppBar / cloche
- Padding de chaque écran hors listes scrollables du shell (Découvrir / Messages restent des placeholders : même inset bas pour ne pas coincer le contenu)

## Architecture

```
lib/features/home/presentation/
  home_shell_page.dart          # extendBody + plus de NavigationBar
  widgets/home_floating_nav_bar.dart
```

Le widget `HomeFloatingNavBar` :

- 4 `Semantics(button: true, selected: …)` avec les labels existants
- Cibles ≥ 44 pt
- Ombre `AppShadows.sm`, bordure `colors.border`
- `onSelect(int)` → `homeShellIndexProvider.notifier.select`

Placement : pas `bottomNavigationBar` du Scaffold (ça recréerait une barre collée). Overlay en bas du `body` (Stack : IndexedStack + nav) **ou** `bottomNavigationBar` transparent de hauteur 0 plus overlay. Choix d’implémentation : **Stack dans le body** (Column actuelle : S02, Expanded Stack[tabs, nav alignée en bas]).

Inset bas des listes : `MediaQuery.padding.bottom` + hauteur visuelle de la capsule (`AppSpacing.xxxl` + padding interne), via un padding en bas du `CustomScrollView` / listes d’onglet (Fil en premier : `FeedBody`). Constante unique (ex. getter sur `HomeFloatingNavBar`) pour ne pas dupliquer un nombre magique.

## Tests

- Les 4 labels restent trouvables ; pas de 5e destination
- Tap Fil / Découvrir continue de changer le contenu (tests shell existants)
- `find.byType(NavigationBar)` disparaît ; `HomeFloatingNavBar` présent
- Cible sémantique `selected` sur l’onglet actif

## Acceptation

- [ ] Capsule inset, pas barre collée pleine largeur
- [ ] Contenu Fil visible derrière / au-dessus du bas d’écran, dernière carte scrollable au-dessus de la capsule
- [ ] 4 onglets, labels, tokens uniquement
- [ ] `flutter analyze` + tests home / feed verts
