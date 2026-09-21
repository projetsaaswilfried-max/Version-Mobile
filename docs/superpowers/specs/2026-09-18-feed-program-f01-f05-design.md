# Design : programme Fil F01-F05 (issue #9)

Date : 2026-09-18  
Issue : [#9](https://github.com/BespokApps/agapeo-mobile/issues/9)  
Réfs : PRD §10 / §14 / §19, screens-prd §4 et C04, D4, D6, spec F01 `2026-09-17-feed-f01-design.md`  
Déclencheur : revue Claude sur [#33](https://github.com/BespokApps/agapeo-mobile/pull/33)

## Contexte

F01 (liste officielle lecture seule) est dans #33. La revue mélange bugs
F01, chrome home, dette data, et souhaits UX qui recoupent F02-F05.

On **ne fusionne pas** tout dans #33. On enchaîne des PRs empilées jusqu'à
fermer #9. Chaque PR reste jouable, testable, mergeable.

La spec F01 du 17/09 reste la vérité de la **liste** (chips overflow, 20
items, officiels seulement). Ce document **étend** F01 (correctifs) et
définit F02-F05 + engagement. En cas de conflit sur un point F01 déjà
tranché ici, **ce document gagne**.

## Décisions produit (verrouillées)

| Sujet | Choix |
|---|---|
| Overflow chips | Conservé (web + spec F01). Pas de rangée unique de 9 chips. |
| Chip Plus | Si Annonce / Verset / Nouveauté est actif : libellé de cette catégorie + état selected (spec F01, point Claude 9). |
| Bannière S02 | Reste **sticky** dans `HomeShell`, au-dessus de l'`IndexedStack`. Pas dans le scroll du fil. |
| Scroll Fil | Dans `FeedTabPage` seulement : un `CustomScrollView` (titre « Fil d'actualité » + chips + cartes). AppBar + cloche + S02 restent hors liste. |
| Marque | Logo `AppAssets.logoFull` en `leading` de l'AppBar Fil ; titre inchangé (« Cercle Agape »). |
| Tabs | `IndexedStack` conservé ; les onglets hors Fil **ne chargent pas** le feed au 1er frame (lazy : body Fil monté seulement si tab = Fil, ou `AutomaticKeepAlive` après première visite). |
| Auteur | Si embed `profiles` : `first_name` (+ `last_name` si présent). Sinon « Équipe Agapeo ». `isVerified` = `photo_verification_status == VERIFIED`, jamais `true` par défaut. |
| Voir plus | Affiché si le texte **dépasse 4 lignes**, pas si `length > 160`. |
| Jauge S02 | Autant de pastilles que de clés `ComputeProfileCompleteness` (6). |
| `AppButton` | Mode compact (`expanded: false`) pour S02. Interdit de restyler un `ElevatedButton` à la main. |
| Tap carte | F02 : push détail. « Voir plus » reste un dépliage **in-card** (scan). |
| Personnel | Jamais dans le fil principal (PRD §10). F04 = C04 depuis Profil / hub compte. |
| Premium popup accueil | Hors programme (#14). |
| Realtime comments | Hors F03 v1 : fetch à l'ouverture + après envoi. |

Hors programme (dette Claude, pas une slice F) : regex YouTube statique et
cache select datasource se font **dans le premier commit data de F02** ;
`Json.enumValue` pour le mapping catégorie si on touche `post_db_mapping` ;
pas de chantier perf isolé.

Point Claude 5 (`Json.list` / `nested`) : **rejeté**. Le diff F01 rend le
parse plus tolérant, ce n'est pas un cast qui plante la page.

## Lots et PRs

Ordre strict. Une branche par lot. Issue #9 se ferme seulement après F04.

| Lot | PR | Ferme | Contenu |
|---|---|---|---|
| A | suite de #33 (même branche `feat/feed-f01`) | rien | Bugs spec + S02 compact + Plus selected + `Key` cartes |
| B | `feat/home-feed-chrome` | rien | Logo AppBar, slivers Fil, lazy tab Fil |
| C | `feat/feed-f02` | rien | Détail + lecteurs média + image réseau partagée |
| D | `feat/feed-engagement` | rien | Like, bookmark, `record_post_view`, retire `IgnorePointer` sur ces actions |
| E | `feat/feed-f03` | rien | Liste commentaires 1 niveau + composer |
| F | `feat/feed-f05` | rien | Share sheet native (`share_plus`) |
| G | `feat/feed-f04` | **#9** | C04 Mes publications + créer/éditer/supprimer perso |

Engagement (D) n'est pas un écran screens-prd ; PRD §10 l'exige sur toute
carte. Il précède F03 pour que les compteurs et le bouton commentaire
soient déjà vrais.

## Lot A : correctifs F01 (#33)

Fichiers déjà là : `post_model.dart`, `feed_post_card.dart`,
`incomplete_profile_banner.dart`, `app_button.dart`, `feed_category_bar.dart`,
`format_relative_time.dart`, `feed_body.dart`.

- `_author` : nom depuis nested ; fallback Agapeo seulement si pas de nom.
- Tests parsing : `first_name: Marie` → displayName Marie (inverse du test actuel).
- `_count` : première clé **présente** (y compris 0), pas `!= 0`.
- `formatRelativeTime` : si `date` > `now`, afficher la date `jj/mm/aaaa` (pas « À l'instant »).
- `_Body` : mesurer le dépassement 4 lignes (`TextPainter` ou équivalent), pas 160 car.
- `_progressSlots` : `ProfileFieldKeys` requis (6), ou `missingKeys` + filled dérivé du total 6.
- `AppButton.expanded` (défaut `true` pour ne pas casser auth). S02 utilise `false`.
- `FeedCategoryBar` : chip Plus remplacée visuellement par le libellé overflow si `selected.isOverflow` (la flèche peut rester, teintée selected).
- `ListView` / slivers plus tard : `key: ValueKey(post.id)` sur `FeedPostCard`.

Pas de `CustomScrollView` dans A (lot B). Pas de player. Pas de like.

## Lot B : chrome Fil

- AppBar Fil : `leading` logo (hauteur bornée par tokens / toolbar), titre « Cercle Agape », cloche inchangée.
- `FeedBody` : `CustomScrollView` + `RefreshIndicator` + slivers (header section, chips, liste, footer loadingMore). Listener pagination sur le même controller.
- Home : ne pas construire `FeedBody` tant que l'onglet Fil n'a pas été sélectionné au moins une fois ; après visite, `AutomaticKeepAliveClientMixin` pour ne pas relancer page 0 à chaque tab.

## Lot C : F02 détail

Nouvel écran `PostDetailPage` (feature `feed/presentation/pages/`).

- Push root `Navigator` depuis tap carte (hors « Voir plus », hors actions).
- Reprend auteur, catégorie, texte **complet** (pas de troncature), média.
- Média :
  - `IMAGE` : plein largeur, pinch optionnel v1 non requis (scroll + image suffit).
  - `GALLERY` : `PageView` + indicateur d'index.
  - `VIDEO` : `video_player` (package nouveau, justifié).
  - `YOUTUBE` : player officiel (package type `youtube_player_flutter` / iframe) ; jamais réhéberger le fichier (PRD).
  - `QUOTE_CARD` / `TEXT_ONLY` : typo comme la carte, sans maxLines.
- Widget partagé `AppNetworkImage` (core) : `Image.network` + placeholder token + fallback cassé. Sert liste + détail. Lot C est le moment d'unifier (Claude 19).
- Datasource : garder le select auteur qui marche ; cacher le select **après le premier succès** même si un fetch ultérieur échoue réseau (Claude 23, borné). Normaliser URL avatar / bucket dans un helper unique feed+onboarding si le code F02 y touche.
- Hors F02 : commentaires, like, share (UI actions visibles, encore no-op ou déléguées si D n'est pas mergé : D vient juste après, F02 peut laisser les actions en lecture).

**F02 v1** : actions bas de détail identiques à la carte, `IgnorePointer` si D pas encore là. Si D est mergé avant, brancher les mêmes notifiers.

## Lot D : engagement

Use cases : `TogglePostLike`, `TogglePostBookmark`, `RecordPostView`.

- Tables PRD : `post_likes`, `post_bookmarks`, `post_views` via `record_post_view()` uniquement pour les vues.
- Vue : une fois la carte visible ≥ 50% (`VisibilityDetector` ou `NotificationListener` + métriques), pas sa propre vue, dédup 12h = **côté RPC** (on appelle, le serveur ignore).
- Carte + détail : like / bookmark cliquables, compteurs optimistes, rollback snackbar.
- Commentaire / share restent visuels jusqu'à E / F.
- `Post` : `likedByMe`, `bookmarkedByMe` si le select le fournit ; sinon fetch dédié des ids de la page.

## Lot E : F03 commentaires

- Un niveau (PRD). `parent_comment_id` ignoré en écriture v1 (pas de reply UI).
- Surface : bas de `PostDetailPage` (liste + champ). Bouton bulle carte → même page, scroll ancres commentaires.
- Insert `post_comments` authentifié. Auteur = profil courant.
- Pas de Realtime v1. Pull à l'ouverture + après post.
- Compteur carte mis à jour (optimiste).

## Lot F : F05 partage

- `share_plus` : texte + lien web du post si URL connue, sinon texte seul.
- Cibles système (WhatsApp etc.) : le share sheet OS, pas 4 boutons custom.
- Incrément `post_shares` si RPC / table l'expose ; sinon partage local sans compteur (à vérifier en implémentation, ne pas inventer une colonne).
- Facebook / Telegram : via le sheet OS, pas SDK dédiés.

## Lot G : F04 + C04 (ferme #9)

Le hub Mon compte (C00-C16) n'existe pas. F04 n'attend pas le hub complet.

- Depuis l'onglet Profil : entrée « Mes publications » → `MyPostsPage` (C04).
- Empty + CTA « Créer une publication ».
- Composer : texte ≤ 600 car., **un** média (image ≤ 15 Mo **ou** vidéo), `image_picker` déjà en deps.
- `post_type = PERSONAL`. N'apparaît **jamais** dans `GetFeed` (filtre query + filet mapping déjà là).
- Éditer / supprimer ses posts. Pas de catégories officielles sur un perso.
- Visible plus tard sur profil public (hors #9 si l'écran public n'existe pas : liste C04 suffit pour fermer le slice création).

## Architecture

Toujours feature `feed/` 3 couches. `home/` = chrome (shell, S02, AppBar Fil).
C04 pages vivent sous `feed/` (même agrégat posts) avec une route depuis
`profile_tab_page` (stub). Pas de `go_router` dans ce programme.

```
feed/
  domain/     Post, PostComment, usecases GetFeed / GetPost / comments / like / bookmark / view / share / my posts
  data/       models Json, supabase datasources
  presentation/
    feed_body.dart, widgets cartes
    pages/post_detail_page.dart
    pages/my_posts_page.dart
    pages/post_composer_page.dart
```

`core/widgets` : `AppButton.expanded`, `AppNetworkImage` (lot C).

## Data flow (cible)

1. Fil : `GetFeed` inchangé (officiels, filtre, page 20).
2. Détail : `GetPost(id)` ou item déjà en mémoire + refresh.
3. Like / bookmark : write + patch item dans `FeedState` et détail.
4. Vue : fire-and-forget RPC quand seuil 50% atteint.
5. Commentaires : `ListComments(postId)` sur détail.
6. Share : OS sheet puis éventuellement insert share.
7. Perso : `ListMyPosts` / `CreatePersonalPost` / `Update` / `Delete` ; jamais mélangé à `GetFeed`.

## Erreurs

Même matrice F01 pour le fil. Détail : erreur + Réessayer. Composer : validation
600 car. + taille média avant upload. Engagement : snackbar, état local rollback.

## Tests (par lot)

- A : parsing auteur Marie ; count 0 ; relative future ; banner 6 slots ; chip Plus « Annonce » ; AppButton compact.
- B : widget Fil a un seul scrollable interne ; FeedTab non monté si index ≠ Fil (test shell).
- C : parse galerie n images ; page détail affiche body complet ; image cassée → placeholder.
- D : like tap incrémente fake repo ; vue non appelée sous 50%.
- E : un niveau ; envoi append la liste.
- F : share appelé (fake).
- G : PERSONAL absent du mapping GetFeed ; composer refuse 601 car.

## Acceptation programme (#9)

- [ ] F01 : liste officielle, filtres + overflow, cartes, pagination, états, correctifs A
- [ ] Chrome B : logo, scroll interne Fil, lazy tab
- [ ] F02 : détail + lecture formats PRD
- [ ] Engagement : like, bookmark, vues RPC
- [ ] F03 : commentaires 1 niveau
- [ ] F05 : share sheet OS
- [ ] F04 : C04 + composer perso, jamais dans le fil
- [ ] Tokens ; analyze + tests verts
- [ ] `Closes #9` seulement sur la PR G

## Suite hors #9

- Hub Mon compte C00-C16
- Profil public (où les perso apparaissent aux autres)
- Realtime comments
- Popup Premium accueil
- `go_router`
