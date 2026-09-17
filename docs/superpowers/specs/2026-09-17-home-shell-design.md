# Design : shell 4 onglets + cloche (S01 / S04) - issue #7

Date : 2026-09-17  
Issue : [#7](https://github.com/BespokApps/agapeo-mobile/issues/7)  
Stack : PR empilée sur [#28](https://github.com/BespokApps/agapeo-mobile/pull/28) (`feat/post-login-routing`)  
Réfs : D4, screens-prd §1, addendum / routage X07

## Contexte

Après le routage post-login (#6 / #28), la destination « membre OK » est encore `SessionStubPage`. Le shell est le cadre permanent iOS (4 onglets + cloche sur Fil). Cette PR remplace le stub partout où l'app « entre à la maison ».

## Décisions produit

| Sujet | Choix |
|---|---|
| Périmètre | Issue #7 complète (shell + placeholders + cloche + stub N01 + swap routeur) |
| SessionStub | Supprimé ; `home` / Revenir plus tard / Err gate → `HomeShellPage` |
| Accès onboarding / logout | Onglet Profil : « Continuer l'onboarding » + « Déconnexion » |
| Navigation tabs | `IndexedStack` + `NavigationBar` (pas `go_router`, pas Navigator imbriqués) |
| Badge cloche | Affiché seulement si non-lus > 0 ; count = 0 pour l'instant → pas de badge |

## Périmètre

### Inclus

- Feature `home/` presentation : `HomeShellPage`, 4 tab placeholders, stub notifications
- Icônes SVG `AppAssets` (icFeed, icDiscover, icChat, icProfile)
- Fil : AppBar + cloche → `NotificationsStubPage`
- Profil : CTA onboarding + déconnexion → Welcome
- Routeur profile : `PostLoginDestination.homeStub` renommé `home` → `HomeShellPage`
- « Revenir plus tard » → `HomeShellPage`
- Suppression `SessionStubPage` + maj tests

### Hors scope

- Bandeau S02 profil incomplet
- Contenu réel Fil / Découvrir / Messages / N01 data
- Premium, `go_router`, Navigator par tab

## Architecture

```
lib/features/home/presentation/
  home_shell_page.dart
  home_tab.dart                 # enum
  home_shell_controller.dart    # Notifier selectedIndex
  tabs/feed_tab_page.dart
  tabs/discover_tab_page.dart
  tabs/messages_tab_page.dart
  tabs/profile_tab_page.dart
  notifications/notifications_stub_page.dart
```

**État :** `homeShellIndexProvider` (`NotifierProvider<int>`).

**Intégration #28 :**
- `pageForDestination` / `pageForGate` : `home` → `HomeShellPage()`
- Onboarding « Revenir plus tard » : même destination
- Enum domain : `homeStub` → `home` (tests domain mis à jour)

## UI

- `NavigationBar` tokens (`colors.surface`, labels Fil / Découvrir / Messages / Profil)
- Placeholders : titre + courte copy centrée
- Cloche : `IconButton` ; badge masqué si 0
- Stub notifications : AppBar + empty state court
- Profil : email optionnel, boutons tokens only

## Tests

- 4 destinations nav, pas de 5e onglet
- Changement d'onglet met à jour le contenu
- Cloche → stub notifications ; pas de badge à 0
- Profil : onboarding push ; déconnexion → Welcome
- Fakes / widgets qui attendaient `SessionStubPage` → `HomeShellPage`
- `ResolvePostLoginRoute` / `pageForDestination` : cas `home`

## Acceptation (#7)

- [ ] 4 tabs visibles, aucun 5e
- [ ] Cloche sur Fil ; badge seulement si > 0
- [ ] Tap cloche → stub notifications
- [ ] Placeholder par tab
- [ ] Tokens uniquement
- [ ] Routeur + Revenir plus tard atterrissent sur le shell
- [ ] `flutter analyze` + `flutter test` verts

## Stack Git

1. Branche : `feat/home-shell` depuis `feat/post-login-routing`
2. PR vers `feat/post-login-routing` (base #28), pas `main`
3. Body : `Stacked on #28` · `Closes #7`
4. Après merge de #28 dans `main` : retarget / rebase de cette PR sur `main`

## Suite pile

- Bandeau S02 (optionnel, petite PR)
- #8 onboarding API
- #9 Fil, etc.
