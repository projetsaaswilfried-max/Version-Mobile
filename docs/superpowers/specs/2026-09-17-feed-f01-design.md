# Design : Fil d'actualité F01 lecture seule (issue #9, slice 1)

Date : 2026-09-17  
Issue : [#9](https://github.com/BespokApps/agapeo-mobile/issues/9) (slice F01 seulement, issue **non fermée**)  
Stack : PR empilée sur [#31](https://github.com/BespokApps/agapeo-mobile/pull/31) (`feat/onboarding-api`)  
Réfs : PRD §10 / §19-§20, screens-prd §4, D4, shell #7

## Contexte

Le shell (#7) expose l'onglet Fil (`FeedTabPage`) avec AppBar, cloche et placeholder.
L'accueil connecté web est `/feed` : posts **officiels** uniquement, filtres
catégories, cartes. Cette PR remplace le placeholder par une liste réelle
Supabase, en lecture.

#9 couvre F01-F05. Trop large pour une PR : F02 (détail), F03 (commentaires),
F04 (posts perso, depuis Mon compte) et F05 (partage) restent hors slice.
L'engagement carte (like, commenter, partager, enregistrer) est **dessiné**
mais **non branché**.

## Décisions produit

| Sujet | Choix |
|---|---|
| Périmètre | F01 lecture seule (liste + filtres + cartes + états) |
| Source | Supabase réel, `post_type = OFFICIAL` uniquement |
| Formats carte | Tous les `post_media_type` en aperçu statique, sans lecteur |
| Pagination | Scroll infini + pull-to-refresh, pages de 20 |
| Actions carte | Visibles, non cliquables (`IgnorePointer`) |
| Filtres | Chips web + overflow Annonce / Verset / Nouveauté |
| Tap carte | Aucune navigation (F02 plus tard) |
| #9 | Non fermée ; cette PR avance F01 seulement |

## Périmètre

### Inclus

- Feature `feed/` Clean Architecture (domain / data / presentation)
- `GetFeed` : officiels, filtre catégorie, pagination, épinglés en tête
- `FeedTabPage` : body = fil ; AppBar + cloche inchangés
- Chips + bottom sheet overflow
- Cartes image / galerie (1re + badge) / vidéo-YouTube (miniature + play) / citation / texte
- **Voir plus** : déplie le texte dans la carte
- États : skeleton, vide, erreur + Réessayer, `loadingMore`
- Tests domain / parsing / widget
- Branche empilée sur #31

### Hors scope

- F02 détail, F03 commentaires, F04 création perso, F05 share sheet
- Like / bookmark / share / commentaires branchés
- `record_post_view`, Realtime
- Popup Premium (1 fois / session, PRD §11) : issue Premium
- Posts `PERSONAL` dans ce fil (interdit PRD §10)
- Swipe, `go_router`, lecteur vidéo / embed YouTube

## Architecture

Feature `feed/`, flèches vers l'intérieur. `home/` reste le chrome
(tabs, S02, AppBar Fil + cloche).

```
lib/features/feed/
  domain/
    entities/          # Post, PostCategory, PostMediaType, FeedPage
    repositories/      # FeedRepository
    usecases/          # GetFeed
  data/
    models/            # DTO fromJson (classe Json)
    datasources/       # FeedRemoteDataSource + Supabase
    repositories/      # impl + map errors
  di/                  # providers (+ _Unconfigured si pas de dart-defines)
  presentation/
    feed_controller.dart
    feed_state.dart
    widgets/           # chips, carte, skeleton, empty, error
```

`FeedTabPage` embarque le body feed. Pas de Navigator imbriqué par tab.

### Domain (Dart pur)

- `Post` : id, auteur (nom + avatar optionnels), catégorie, texte, mediaType,
  urls / thumbnail, `galleryCount`, `isPinned`, compteurs (likes, commentaires,
  partages), `createdAt`
- `PostCategory` : aligné PRD `post_category`
  (`TEACHING`, `TESTIMONY`, `WORKSHOP`, `ADVICE`, `ANNOUNCEMENT`, `QUOTE`,
  `VERSE`, `NEWS`)
- `PostMediaType` : aligné PRD (`IMAGE`, `GALLERY`, `VIDEO`, `QUOTE_CARD`,
  `TEXT_ONLY`, `YOUTUBE`)
- `FeedPage` : `items` + `hasMore`
- `FeedFilter` : `all` ou une `PostCategory`
- `FeedRepository.fetchPage({required FeedFilter filter, required int offset, required int limit})`
  → `Future<Result<FeedPage>>`
- `GetFeed` : délègue au repo (limite 20). Aucune inclusion `PERSONAL`.

Mapping chips UI → filtre :

| Chip | Filtre |
|---|---|
| Tout le fil | `all` |
| Enseignements | `TEACHING` |
| Témoignages | `TESTIMONY` |
| Atelier/Mariage | `WORKSHOP` |
| Conseils & Préparation | `ADVICE` |
| Pensées & Citations | `QUOTE` |
| Annonce (overflow) | `ANNOUNCEMENT` |
| Verset (overflow) | `VERSE` |
| Nouveauté (overflow) | `NEWS` |

### Data

- Select authentifié `posts` où `post_type = OFFICIAL`
- Embed `post_media`
- `category` si filtre ≠ `all`
- Tri : épinglé desc, date desc. Nom exact de la colonne d'épinglage lu sur
  `posts` au premier select (ex. `is_pinned`) ; si absente, tri date seul.
  Le nom de colonne reste dans le datasource, pas dans le domain (`Post.isPinned`).
- Pagination PostgREST `range(offset, offset + limit - 1)`
- `hasMore` si `items.length == limit`
- Join auteur (`profiles`) si FK disponible ; sinon libellé « Agapeo »
- Parsing défensif via `Json` ; média / catégorie inconnus : fallback texte,
  pas de crash
- Erreurs → `Failure` (`NetworkFailure`, `ServerFailure`, …)
- Sans Supabase configuré : `_UnconfiguredFeedRepository` → `Err` clair

### Presentation

- `FeedState` (`Equatable` + `copyWith`) : `filter`, `items`, `isInitialLoading`,
  `isRefreshing`, `isLoadingMore`, `hasMore`, `errorMessage`
- `FeedController` (`Notifier`) :
  - premier build → page 0
  - `selectFilter` → reset + page 0
  - `refresh` → page 0, remplace les items
  - `loadMore` si `hasMore` et pas déjà en cours, `offset = items.length`
- Providers dans `feed/di/`

## Data flow

1. Premier affichage onglet Fil : `GetFeed(all, 0, 20)`
2. Changement de chip : reset liste, offset 0, nouvel appel. Un épinglé hors
   catégorie disparaît du filtre.
3. Pull-to-refresh : recharge page 0, remplace (pas d'append)
4. Proche du bas : append si `hasMore`
5. Pas de `record_post_view`. Pas de Realtime. Pas d'écriture engagement.

## UI

Tokens uniquement (`context.colors`, `context.typography`, `AppSpacing`,
`AppRadius`). Pas de couleur / taille en dur.

**Chrome.** AppBar « Fil » + cloche existants. S02 reste dans `HomeShell`,
au-dessus de l'`IndexedStack`.

**Filtres.** Rangée chips horizontale scrollable sous l'AppBar, style
`AppOptionChips` (pilule, `primary` si selected). Ordre : Tout le fil,
Enseignements, Témoignages, Atelier/Mariage, Conseils & Préparation,
Pensées & Citations, **Plus**. Cible ≥ 44 pt.

Chip **Plus** : bottom sheet (Annonce, Verset, Nouveauté). Une seule
catégorie à la fois. Si une catégorie overflow est active, la chip Plus
affiche ce libellé et l'état selected.

**Liste.** `ListView.builder` + `RefreshIndicator`. Pas de swipe.
Images : `Image.network` + placeholder (pas de nouveau package).

**Carte (haut → bas).**

1. Auteur (avatar + nom / « Agapeo ») + indicateur épinglé
2. Label catégorie
3. Texte ; au-delà de 4 lignes, lien **Voir plus** déplie dans la carte
   (**Voir moins** une fois déplié). Pas de push F02.
4. Média :
   - `IMAGE` : un visuel
   - `GALLERY` : première image + badge « n photos »
   - `VIDEO` / `YOUTUBE` : miniature + icône play **non cliquable**
   - `QUOTE_CARD` : carte typographique
   - `TEXT_ONLY` : pas de bloc média
5. Compteurs (likes, commentaires, partages) + barre d'actions
   (like, commentaires, partager, enregistrer) sous `IgnorePointer`

**États.**

| État | UI |
|---|---|
| Premier chargement | 3 skeletons de cartes |
| Vide (Tout) | « Aucun post pour le moment » |
| Vide (filtre) | « Aucun post dans cette catégorie » |
| Erreur initiale | Message + **Réessayer** |
| `loadingMore` | Indicateur en bas de liste |
| Image cassée | Placeholder, carte conservée |

Pas de CTA de création (F04 hors fil).

## Erreurs

| Cas | Comportement |
|---|---|
| Réseau / serveur / RLS / non configuré | État erreur + Réessayer (chargement initial) |
| Échec `loadMore` | Liste conservée + snackbar ; nouvel essai au prochain scroll |
| Échec refresh | Items conservés + snackbar |
| Catégorie / mediaType inconnus | Fallback texte, pas de crash |
| `PERSONAL` renvoyé par erreur | Ignoré côté mapping (filtre query + filet parsing) |

## Tests

### Automatisés

- `GetFeed` / mapping chips → enums ; `hasMore` (20 vs < 20)
- Parsing JSON : officiels, épinglé, chaque `post_media_type` ; ignore `PERSONAL`
- Widget : 6 chips + Plus ouvre le sheet ; skeleton ; vide ; erreur + Réessayer
- Cartes image / texte / citation ; barre d'actions non cliquable
- Fake repo : refresh remplace, `loadMore` append

### Manuel

- [ ] Compte connecté : fil officiel réel, pas de posts perso
- [ ] Chips + overflow refiltrent ; épinglés en tête du sous-ensemble
- [ ] Scroll infini + pull-to-refresh
- [ ] Hors ligne : erreur puis Réessayer
- [ ] Actions carte : aucun like / bookmark / navigation
- [ ] `flutter analyze` + `flutter test` verts

## Acceptation (slice F01)

- [ ] Liste officielle Supabase dans l'onglet Fil
- [ ] Filtres web + overflow Annonce / Verset / Nouveauté
- [ ] Cartes statiques pour tous les formats (play = overlay seulement)
- [ ] Scroll infini + pull-to-refresh
- [ ] 4 états (skeleton, contenu, vide, erreur)
- [ ] Actions visibles, non cliquables
- [ ] Tokens uniquement
- [ ] Analyze + tests verts
- [ ] Issue #9 **reste ouverte**

## Stack Git

1. Branche : `feat/feed-f01` depuis `feat/onboarding-api`
2. PR vers `feat/onboarding-api` (base #31), pas `main`
3. Body : `Stacked on #31` · `Partial #9 (F01)` (pas de `Closes #9`)
4. Après merge de #31 : retarget / rebase sur `main` si besoin

## Suite (hors cette PR)

Programme F01-F05 : `docs/superpowers/specs/2026-09-18-feed-program-f01-f05-design.md` (D6).
Popup Premium accueil : hors #9 (issue Premium / #14).
