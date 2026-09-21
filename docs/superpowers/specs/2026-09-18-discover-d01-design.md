# Design : Découvrir D01 liste (empilé sur #33)

Date : 2026-09-18  
PR : [#34](https://github.com/BespokApps/agapeo-mobile/pull/34) base `#33` (`feat/feed-f01`)  
Réfs : PRD §1 / §3 / §6 / §7 / §19, screens-prd §5, D4, Q1/V1, design-inspiration (liste, pas swipe)

## Contexte

L'onglet Découvrir est un placeholder. Le web (`/discover`) montre deux
sections de cartes profil. Le repo web n'est pas dans l'org GitHub mobile ;
l'OpenAPI PostgREST répond 401 à l'anon. Les RPC documentées (PRD §21)
couvrent les vues / messages / blocages, **pas** une liste Découvrir.

D01 reproduit le **comportement PRD §7** côté client, en s'appuyant sur
`profiles` + `profile_photos` filtrés par la RLS. Si un RPC apparaît plus
tard, on le substitue sans changer l'UI.

## Décisions produit

| Sujet | Choix |
|---|---|
| Périmètre | D01 liste seulement |
| Interaction | Liste scrollable, **jamais** de swipe (PRD §1) |
| Éligibilité (Q1) | **§7** : genre opposé, pas staff, `VERIFIED`, profil complet, `is_matched = false`. Q1 reste ouverte ; V1 (corriger §6) après confirmation SQL |
| Recommandée | 3 profils, tirage du **jour** (graine date UTC + id visiteur), déterministe |
| Autres | Le reste, pages de **12** |
| Carte | Photo nette ; nom / âge / ville masqués sauf visiteur `VERIFIED` **ou** `ACTIVE` (PRD §3) |
| Badge | Coche `Icons.verified` + `colors.verified` (rose), si `photo_verification_status == VERIFIED` |
| Tap carte | Aucune fiche (D03) : pas d'`record_profile_view` |
| CTA carte | Like / inviter / favori **non branchés** (D05 / D06) |
| Recherche / filtres | Hors slice (D02) : pas de barre sur D01 |
| Paywall D04 | Hors slice, sauf **EXPIRED** : mur plein écran, pas la liste (PRD §3 / §11) |
| Score | Calculé en domain (table PRD §7, 100 pts max). Si la RLS ne livre pas assez de champs, trier ce qui est lisible et documenter le trou |

## Périmètre

### Inclus

- Feature `discover/` Clean Architecture (comme `feed/`)
- `GetDiscoverPage` : recommandés du jour + page « Autres »
- `DiscoverTabPage` remplace le placeholder
- Cartes, skeleton, vide, erreur + Réessayer, `loadingMore` sur Autres
- Masquage nom / âge / ville
- Tests domain (score, tirage du jour, masquage) + widget liste
- Branche empilée sur #33

### Hors scope

- D02 recherche / filtres Premium
- D03 fiche (et `record_profile_view`)
- D04 sheet « Passe Premium » à chaque load (compte `FREE` / `CANCELED`)
- D05 like + « Valide ton profil »
- D06 invitation
- Favoris, qui m'aime
- Swipe, `go_router`

## Architecture

```
lib/features/discover/
  domain/
    entities/       # DiscoverProfile, DiscoverPage, DiscoverMask
    scoring/        # CompatibilityScore (100 pts, règles PRD §7)
    daily/          # choix déterministe des 3 recommandés
    repositories/
    usecases/       # GetDiscoverPage
  data/
    models/
    datasources/    # Supabase profiles + photos (select hinté si embed)
    repositories/
  di/
  presentation/
    discover_controller.dart
    discover_state.dart
    widgets/        # carte, sections, skeleton, empty, error
```

`home/` : `DiscoverTabPage` embarque le body. Chrome (nav capsule, S02) inchangé.

Lazy : comme le Fil, ne monter Découvrir qu'à la première visite de l'onglet.

### Source data (hypothèse)

1. Lire le profil visiteur (`profiles` + `profile_restricted.subscription_status`).
2. Si `EXPIRED` : état `blockedExpired`, pas de fetch liste.
3. Sinon `select` membres exposés par RLS (exclure soi, staff, matched).
4. Filtrer §7 en domain si des lignes hors critères passent encore.
5. Scorer, tirer 3 recommandés du jour, paginer le reste par 12.

Colonnes carte (minimum) : `id`, prénom/nom, `birth_date` ou âge, ville/pays,
`photo_verification_status`, `is_staff`, `is_matched`, photo primaire publique.

### UI

- Titre d'onglet : Découvrir (placeholder actuel).
- Section « Recommandée pour vous » puis « Autres profils ».
- Carte : avatar/photo 4:3, nom (masqué ou non), méta âge · ville, badge rose.
- Tokens uniquement. Bottom sheets plus tard (D04-D06), pas de dialog centré.

### États

| État | UI |
|---|---|
| Chargement | Skeleton cartes |
| Vide | « Aucun profil pour le moment » |
| Erreur | Message + Réessayer |
| EXPIRED | Mur abonnement (copy PRD), pas de cartes |
| Suite Autres | Indicateur bas de liste |

## Q1 / inspection

- Pas de RPC `get_discover*` dans PRD §21.
- Org GitHub : pas de repo web Agapeo.
- OpenAPI `/rest/v1/` : 401 anon.

Dès que le SQL est lisible : confirmer §7 vs §3, puis clore Q1 et V1.

## Tests manuels

- [ ] Onglet Découvrir : 3 recommandés + jusqu'à 12 autres
- [ ] Compte non vérifié non Premium : nom/âge/ville masqués, photo nette
- [ ] Compte vérifié ou Premium : infos en clair
- [ ] EXPIRED : mur, pas de liste
- [ ] Pas de swipe ; tap carte ne pousse pas de fiche
- [ ] Fil (#33) inchangé
- [ ] `flutter analyze` + `flutter test` au vert
