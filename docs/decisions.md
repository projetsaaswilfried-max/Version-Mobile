# Agapeo Mobile — Journal des décisions

Trace des choix de construction, avec leur *pourquoi* et un lien vers la section
du [PRD](./PRD.md) concernée. Append-only : on ne réécrit pas l'histoire, on
ajoute une nouvelle entrée qui remplace une ancienne si besoin.

Trois états : **DÉCIDÉE**, **EN ATTENTE** (dépend d'une réponse externe),
**À VÉRIFIER** (dépend d'une inspection technique qu'on n'a pas encore faite).

---

## DÉCIDÉES

### D1 — Confirmation d'inscription mobile par OTP
*2026-09-13 · réf. PRD §4 · détail : addendum §1.1*

Code OTP à 6 chiffres saisi dans l'app (`verifyOtp`), plutôt que le lien
email. Raison : le lien s'ouvre dans un navigateur, souvent sur un autre
appareil, et la session n'atterrit jamais dans l'app. L'OTP établit la session
in-app directement, robuste au cross-device, et cohérent avec l'usage OTP déjà
connu (Mobile Money).

- Template email projet-wide → doit contenir **lien + code** pour préserver le
  web (`{{ .ConfirmationURL }}` et `{{ .Token }}`).
- **Longueur du code — verrou cross-système.** Supabase génère `{{ .Token }}`
  selon le réglage Dashboard *Authentication → Emails → Email OTP Length*
  (défaut : 8 chiffres — vérifié sur un email réel). **Fixé à 6** côté
  produit (plus court à saisir, cohérent avec l'attente OTP standard) :
  le réglage Dashboard doit être mis à **6**, et `AuthValidators.otpLength`
  (mobile) doit toujours matcher exactement cette valeur Dashboard. Si l'un
  change, changer l'autre dans le même commit/ticket.
- *Révisé 2026-09-16 :* le fallback « vérifie tes mails » (écran séparé avec
  bouton « J'ai confirmé ») a été retiré — redondant avec le renvoi déjà
  disponible sur l'écran OTP. Nouveau comportement : si une connexion échoue
  avec `email_not_confirmed` (code d'origine forcément périmé à ce stade),
  l'app renvoie l'email elle-même et redirige directement vers l'écran OTP,
  sans action de l'utilisateur.

### D2 — Le PRD reste la source de vérité du comportement ; addendum pour le delta
*2026-09-13*

On ne réécrit pas le PRD pour le mobile. `PRD.md` = comportement (partagé
web/mobile). `mobile-addendum.md` = réalisation mobile uniquement. Raison :
éviter la divergence de deux documents décrivant la même chose. Les corrections
au PRD (voir V1) se font dans le PRD une fois tranchées contre le code, pas dans
l'addendum.

### D3 — Dépôt mobile autonome
*2026-09-13*

`github.com/BespokApps/agapeo-mobile`, séparé du web. Le lien entre les deux se
fait par la base Supabase partagée et le PRD, pas par un monorepo.

### D4 — Bottom nav : 4 onglets (Fil, Découvrir, Messages, Profil)
*2026-09-14 · réf. screens-prd.md §1 (PR #2)*

Le PRD ne spécifie **aucune** structure de navigation principale (le web est
une PWA sans bottom nav ; son seul "onglets" documenté est celui de "Mon
Compte", §14, sans rapport). La proposition initiale de `screens-prd.md`
(5 onglets, Notifications inclus) était une inférence non tranchée — corrigée
ici.

**Cible : 4 onglets** — Fil, Découvrir, Messages, Profil. **Notifications**
vit dans le header de l'accueil (icône + badge), pas en 5ᵉ onglet — évite de
diluer la barre pour un écran de consultation, pas une destination
fréquente. Premium reste hors bottom nav (page dédiée + popups, PRD §11), pas
un tag Trending.

- `home_shell` (voir arborescence, `CLAUDE.md`) se construit sur ces 4 tabs.
- Si Notifications a besoin d'un accès plus visible plus tard, revoir cette
  entrée plutôt que d'ajouter un 5ᵉ onglet sans repasser par ce journal.

### D5 - Onboarding profil mobile : 3 steps, photo skippable
*2026-09-17 · réf. PRD §5 · spec : `docs/superpowers/specs/2026-09-17-onboarding-3steps-heroes-design.md`*

Delta mobile assumé vs le PRD web (5 étapes, photos obligatoires, selfie live
dans l'assistant) :

1. **3 steps** : Essentiels (genre / DOB / pays) → Foi (confession, situation,
   pourquoi mariage) → Photo de profil.
2. **Steps 1-2 non skippables** : pas de « Revenir plus tard » tant que l'utilisateur
   n'a pas atteint la Photo (on peut toujours revenir en arrière dans le flow).
3. **Photo skippable** avec avertissement explicite : sans photo, le profil ne
   sera pas vérifié ni visible ; ajout possible plus tard.
4. **Photo de profil** : capture caméra **ou** import galerie. Le **selfie live**
   anti-usurpation reste requis pour la soumission de vérification, mais **hors**
   cet onboarding (Mon compte / parcours vérif).
5. **Heroes** : illustration soft en haut de chaque step (placeholders acceptés).

Raison : raccourcir le time-to-home, réduire l'abandon, garder la confiance
(vérif) sans bloquer l'entrée. Le PRD web n'est pas réécrit ici (D2) : ce delta
vit dans le journal + la spec mobile.

### D6 — Fil : programme F01-F05, revue Claude #33
*2026-09-18 · réf. PRD §10, screens-prd §4 / C04, issue #9, spec `docs/superpowers/specs/2026-09-18-feed-program-f01-f05-design.md`*

Le fil se livre en **PRs empilées** (A correctifs F01 → B chrome home → C F02 →
D engagement → E F03 → F F05 → G F04). #9 se ferme sur G, pas avant.

Réconciliation revue Claude vs spec F01 :

- Bugs d'écart à la spec (auteur, jauge 6 champs, Voir plus 4 lignes, dates
  futures, compteur `0`, chip Plus qui montre l'overflow) : lot A, même PR #33.
- Overflow chips **conservé** (aligné web). On n'aligne pas 9 chips en scroll
  horizontal.
- Bannière S02 **sticky** dans le shell (tous les onglets). Le scroll « un
  bloc » de Claude s'applique **dans** l'onglet Fil (titre + chips + cartes),
  pas à S02 / AppBar.
- Logo Agapeo en `leading` de l'AppBar Fil. Titre « Agapeo » (voir D10).
- Point « Json.list casse tout » : **rejeté** (parse plus tolérant, pas l'inverse).
- F04 n'attend pas le hub Mon compte : entrée C04 depuis l'onglet Profil.

### D7 — Profil C02–C16 : un lot sur le hub, colonnes best-effort
*2026-09-19 · réf. PRD §§3, 6, 14–15 · spec `docs/superpowers/specs/2026-09-19-profile-account-pages-design.md`*

Le hub C00 ne snackbar plus les sections restantes. Un repo `ProfileAccountRepository` couvre Foi, Plus d'infos, Favoris, Qui s'intéresse, Confidentialité, Compte & Sécurité (C09–C16) et l'aperçu public de soi. Les colonnes absentes sont masquées (même pattern que le switch déménagement C01). C05/C06 ouvrent la fiche Découvrir existante ; C06 masque les identités tant que l'abonnement n'est pas `ACTIVE` (sauf staff). Hors lot : checkout Premium.

### D8 — Surfaces store sans checkout ni push natif
*2026-09-19 · réf. PRD §§11–15, 22 · spec `docs/superpowers/specs/2026-09-19-store-ready-surfaces-design.md`*

Tant que Q2 / Q3 restent ouverts, on livre quand même N01 in-app, signalement, blocage depuis fiche/fil/post, support, pages légales (dont L10), P01 lecture seule, quota photos 2/10, favori Découvrir aligné sur `profile_id`, et realtime du fil messages. Pas d’initiation SasPay, pas d’APNs.

### D9 - Pas de bandeau S02 sticky dans le shell
*2026-09-19 · réf. PRD §6, screens-prd S02, remplace le point S02 de D6*

Le bandeau « Profil incomplet » n’est plus collé en haut de tous les onglets. Un profil incomplet est déjà invisible dans Découvrir (PRD §6) et Découvrir a son propre rappel contextuel + CTA Compléter. Un bandeau global mangeait de l’espace (surtout sur Profil) sans débloquer l’accès.

Le calcul `profileCompletenessProvider` reste : il alimente Découvrir. L’onboarding se relance depuis Profil (Modifier) ou depuis la bannière Découvrir.

### D10 - Surfaces blanches, confession liste fermée, récap non-retour
*2026-09-19 · réf. PRD §5, §7 · remplace le titre « Cercle Agape » de D6*

Retour design (finitions dating pro) :

1. **Surfaces** : fond de page = `surface` blanc partout (Fil, Profil, formulaires). Plus de wash gris/rosé. Cartes fil blanches avec bordure + ombre légère (hors clip).
2. **Inputs DS** : `InputDecorationTheme` outlined (fond blanc, bordure, radius `md`, focus primary) - plus de fill gris sans contour ni pilule.
3. **Confession** : liste fermée (`AppSelectField` + bottom sheet), valeurs canoniques partagées (`onboardingFaithConfessions`) pour alimenter les filtres Découvrir. Delta vs PRD §5 « texte libre ».
4. **Fil AppBar** : titre « Agapeo » (logo leading). Plus de « Cercle Agape ». Cloche = icône custom `ic_bell`, pas Material.
5. **Récap onboarding** : point de non-retour - uniquement « Terminer ». « Passer » (skip photo) vit sur l’étape Photo. Plus de « Revenir plus tard » sur le récap.
6. **Locale** : app forcée `fr` (`flutter_localizations`) pour date picker et dates affichées.

### D11 - Bucket photos profil : alignement sur `avatars`
*2026-09-20 · réf. PRD §21 · résout V4*

Le mobile uploadait les photos profil/onboarding vers un bucket
`profile-photos`, inexistant côté Supabase (`StorageException 404 Bucket not
found` reproduit en test onboarding). Le PRD §21 ne liste que `avatars` /
`post-media` comme buckets publics. **Décision : tout le mobile s'aligne sur
`avatars`** - plus de bucket `profile-photos` séparé. `AppStorageBuckets`
n'expose plus que `avatars`/`postMedia` ; les datasources onboarding, profil,
discover, messages et feed pointent toutes vers `avatars`.

### D12 - Gris neutre `muted` pour chrome inactif et skeletons
*2026-09-20 · réf. D4 (bottom nav)*

Les icônes non actives de la bottom nav utilisaient `textSecondary` (#6B6570),
trop foncé / teinté. Les skeletons réutilisaient `border` (rose-gris). Nouveau
token `AppColors.muted` (#B0B0B0 light / #7A7A7A dark) : gris simple façon apps
courantes. Usages : onglets inactifs, skeletons, placeholders image / média.
`textSecondary` reste pour le texte secondaire lisible ; `border` pour les
contours uniquement.

### D13 - Skeletons : token `skeleton` dédié + pulsation, chips Fil sur une seule ligne
*2026-09-20 · réf. D12, D6 (remplace le point overflow chips de D6)*

Trois retours produit après test manuel :

1. **Skeletons trop foncés.** `muted` (#B0B0B0) posé en aplat plein sur une
   grande carte lit plus lourd qu'sur une petite icône. Nouveau token
   `AppColors.skeleton` (#E7E7E7 light / #3D3A3C dark), dédié aux blocs de
   chargement, + léger effet de pulsation d'opacité (widget
   `AppSkeletonBox`, `core/widgets/`). `muted` reste pour icônes inactives et
   placeholders d'image statiques.
2. **Chips de catégorie du Fil : plus de chevron/bottom sheet.** Toutes les
   catégories (`FeedChip.allVisible`) restent sur une seule ligne
   horizontale scrollable (mobile-first, cohérent avec des refs comme
   Tinder/Bumble). **Remplace** le point D6 « overflow chips conservé,
   pas de scroll horizontal pour 9 chips ». Chip non sélectionnée : fond
   gris neutre (`AppColors.chipBackground`, même teinte que `skeleton`
   aujourd'hui mais token distinct).
3. **Anneau `primary` autour de l'avatar auteur (Fil).** Effet « story »
   (liseré coloré + léger espace blanc entre l'anneau et la photo), inspiré
   d'une référence dating app. `feed_post_card.dart` uniquement pour
   l'instant — pas encore étendu aux avatars des commentaires ni du hub
   Profil.

### D14 - Découvrir : pagination serveur reelle, bandeau aperçu retiré, header Profil
*2026-09-20 · réf. PRD §7, revue #34*

Trois retours produit après test manuel :

1. **Pagination serveur.** `fetchCandidateRows` ramenait toute la table
   `profiles` en un seul appel (pas de `.range()`), et `loadMore` ne faisait
   que révéler des éléments déjà téléchargés. Désormais `.order('id')` +
   `.range()` côté Supabase (`GetDiscoverPage.serverBatchSize = 60`) ;
   `DiscoverController.loadMore()` ne requête le serveur que quand le stock
   local déjà scoré/trié est épuisé. Le "recommandé du jour" reste calculé
   une seule fois, sur la toute première page — les pages suivantes
   n'alimentent que "autres profils" (limitation assumée : voir
   `GetMorePage`/`GetDiscoverPage.more()`).
2. **Bandeau "Ceci est un aperçu" retiré de Découvrir.** Remplace le point 2
   de D13 (qui l'avait seulement condensé) — supprimé entièrement à la
   demande produit, `discover_status_banners.dart` supprimé.
3. **Header Profil.** Boutons "Voir mon profil public" / "Modifier"
   remplacés par un badge crayon superposé sur l'avatar (`onEdit`) + un
   lien texte simple pour le profil public, inspiré d'une référence dating
   app envoyée par le produit.

### D15 - Découvrir : cartes liste en layout split (photo + bandeau)
*2026-09-20 · réf. PRD §7, design-inspiration (Datify cartes)*

Retour produit : la liste Découvrir (photo full-bleed + overlay texte +
actions en pastilles haut-droite) ne lisait pas « dating pro ».

**Décision :** carte en deux plans - photo 4:5 (pill score si `score > 0`,
léger gradient bas, menu `…` haut-droite → `ProfileSafetySheet` blanc
(Signaler / Bloquer, même chrome que ReportSheet) puis ReportSheet ou
confirmAndBlock) + bandeau blanc identité (nom, âge, vérifié, ville ·
confession) avec like / favori espacés à droite. Bordure fine + ombre `md`.
Skeleton aligné. Pas de swipe (PRD §1).

### D16 - Cache disque des images réseau (`cached_network_image`)

`AppNetworkImage` (widget partagé, quasi toutes les photos de l'app)
utilisait `Image.network` — aucun cache disque, seulement le cache mémoire
volatile de Flutter. Chaque redémarrage ou éviction mémoire retéléchargeait
tout depuis Supabase Storage. Remplacé par `cached_network_image` (cache
disque + mémoire, dédup des requêtes). Les 4 usages qui contournaient
`AppNetworkImage` avec un `NetworkImage(...)` brut (avatars circulaires —
messages, compte, Fil) migrés vers `CachedNetworkImageProvider`.

Placeholder de chargement remplacé par `AppSkeletonBox` (pulsation, D13) au
lieu d'un aplat gris statique.

---

## EN ATTENTE (réponse du porteur produit)


### D17 - Fiche Découvrir style Datify (champs PRD §6)
*2026-09-20 · réf. PRD §6 / §7, design-inspiration Datify `42_Light_profile details page`*

La fiche bottom sheet (D03) était trop plate. **Décision :** layout Datify
adapté Agapeo - header `X` / Profil / `…`, carrousel photo avec indicateurs,
méta en lignes icône (genre, taille, profession, situation, ville, pays),
sections Foi / À propos / Pourquoi le mariage / Verset / Témoignage /
Valeurs / Loisirs / Qualités / Galerie (vides omises), chips outlined,
actions bas en pastilles circulaires (Like / Favori étoile / Inviter).
Select profil enrichi (`profession`, `bio`, `height_cm`, `favorite_verse`,
`testimony`, `qualities`) avec fallback colonnes. Pas de swipe liste (PRD §1).

### D18 - Hub Profil (bottom nav) : header + sections groupées
*2026-09-20 · réf. PRD §14, screens-prd C00*

Retour design : le hub Profil était une liste plate de 8 lignes + déconnexion
collée hors scroll. **Décision :** avatar plus grand avec anneau primary,
nom en `headline`, CTA pill « Voir mon profil public », bandeau complétude
en wash rose (plus de bloc primary plein), menus groupés Mon compte /
Activité / Réglages, Déconnexion dans le scroll. Même chrome AppBar que
Découvrir / Messages.

### D19 - Schéma réel confirmé (export SQL) : like/favoris/messages/blocks

*2026-09-20 · réf. D05, D06 — remplace les hypothèses de colonnes probées*

Export `information_schema.columns` obtenu du porteur produit — colonnes
réelles figées en dur, plus de sondage réseau à chaque appel :

- `profile_likes(user_id, liked_profile_id)` — pas `liker_id`/`liked_id`.
- `favorites(user_id, favorite_profile_id)` — pas `profile_id`/`favorited_id`.
- `blocks(blocker_id, blocked_id)` — hypothèse initiale confirmée.
- `conversation_participants(user_id, ...)` — pas `profile_id`.
- `conversations(initiated_by, last_message_at, ...)` — pas `created_by`/
  `updated_at`.
- `messages(sender_id, content, ...)` — hypothèses initiales confirmées.
- `matches(requester_id, recipient_id, ...)` — pas `proposer_id`.

`reports` reste non confirmé (table hors de l'export reçu, tronqué avant).
Le mécanisme de sondage (`_looksLikeMissingColumn` + liste de candidats)
reste en place uniquement là où le schéma n'est pas encore vérifié.

### D20 - Placeholder avatar + Mon profil public = fiche Découvrir
*2026-09-20 · réf. D17, design-inspiration Datify*

Deux retours UI :

1. **Photo manquante.** Le gris + `Icons.person_outline` faisait cheap.
   **Décision :** `AppAvatarPlaceholder` - gradient brand soft + initiales
   (ou cœur si nom vide), tailles adaptées via `LayoutBuilder`. Même
   composant liste Découvrir, fiche détail, hub Profil, grille photos,
   comptes liés, récap onboarding.

2. **Mon profil public.** L'écran réutilisait l'ancien `AppProfileHero` /
   sections plates, pas le layout Datify de D17. **Décision :** même
   `DiscoverProfileContent` que la fiche Découvrir ; `PublicProfilePreview`
   enrichi (âge, genre, taille, pays, foi, qualités…) ; score masqué
   (preview soi-même, pas de compatibilité).

### D21 - Empty states harmonisés (`AppEmptyState`)
*2026-09-20 · réf. D13, illustrations `assets/images/empty/`*

Beaucoup d'écrans montraient juste un texte (parfois + bouton) : notifications,
Mes publications, Support, commentaires, etc. **Décision :** un seul pattern
`AppEmptyState` - illustration clay (ou disque gradient brand + icône), titre
en `title`, détail secondaire, CTA optionnel. Mode `compact` pour les
contextes inline (commentaires). Copy enrichie sur Découvrir / Fil /
Messages / Favoris / Bloqués / Support.

### D22 - Centre de notifications N01 (liste datée)
*2026-09-21 · réf. PRD §12, screens-prd N01*

La V1 était une grille de cartes bordées, peu « dating ». **Décision :** liste
plate style inbox (Messages) - sections Aujourd'hui / Hier / Plus tôt, icône
catégorie en pastille gradient, horodatage à droite, wash primary + pastille
« Non lue » pour les non lues, chips filtres inchangés (Toutes… Plateforme).
Realtime / pull-to-refresh en soft (pas de spinner plein écran).

### D23 - Mes publications C04 + composer perso
*2026-09-21 · réf. PRD §10 / §14, screens-prd C04*

Liste + création trop plates (bouton pleine largeur, composer formulaire
basique). **Décision :** liste avec skeleton, FAB / `+` AppBar, cartes
tapables (détail), stats et preview média. Composer type inbox : zone texte
sans bordure, bandeau « visible sur profil public pas dans le Fil », preview
média locale avec retrait, Publier dans l'AppBar, compteur 600, sheet média
avec poignée. Édition = texte seulement (média existant en lecture seule).

### D24 - Publications personnelles sur profil public
*2026-09-21 · réf. PRD §10, screens-prd F04 / C04*

Les posts `PERSONAL` ne sont pas dans le Fil communautaire ; le composer
promettait déjà « visible sur ton profil public ». **Décision :** section
« Publications » sur la fiche Découvrir / Mon profil public (grille
horizontale, tap → détail). Fetch par `author_id` (pas seulement moi).
Section absente si vide / erreur soft.

### D25 - Comptes bloqués : RPC + placeholders RLS
*2026-09-21 · réf. PRD §10 / §21, screens-prd C13*

Bloquer réussissait (insert `blocks`) mais la liste restait vide : après
blocage, la RLS masque souvent le `profiles` cible, donc
`_peopleByIds` renvoyait `[]`. **Décision :** tenter d'abord
`get_my_blocked_profiles` (PRD §21) ; sinon lire `blocks` et fusionner
avec des placeholders « Profil bloqué » pour chaque id sans profil
lisible, afin de garder le déblocage.

### D26 - Édition profil unifiée (C01 enrichi)
*2026-09-21 · réf. PRD §5-6 / §14, spec `2026-09-21-profile-edit-unified-design.md`*

Le crayon hub et « Mon Profil » ouvrent C01 enrichi (identité + confession /
situation / pourquoi le mariage). Genre / DOB / pays restent lecture seule.
L'onboarding ne s'ouvre plus depuis Modifier ; uniquement premier parcours
ou essentiels encore manquants (bannière complétion).

Complément : section Photos explicite + crop JPEG (comme onboarding) ;
bannière avec photo manquante ouvre `MyProfilePage(focusPhotos: true)`
(cadre d'ajout mis en avant + sheet source).

### D27 - Feedback transient AppToast + confirmation déconnexion
*2026-09-21 · réf. spec `2026-09-21-feedback-toast-signout-design.md`*

Succès et erreurs transientes passent par `AppToast` (plus de SnackBar Material
pour ce feedback). Messages techniques adoucis via `userFacingMessage`.
Toute déconnexion (hub, suspendu, abo expiré) passe par `AppConfirmDialog`.

### D28 - Champs "complétude §7" étendus : situation matrimoniale + passions
*2026-09-21 · réf. note vocale porteur projet*

Le porteur du projet a confirmé la liste des infos nécessaires pour
apparaître dans Découvrir : onboarding rempli (identité, pourquoi le
mariage, situation matrimoniale, passions), photo + **vérification admin**.
Deux champs manquaient jusqu'ici à cette notion de « profil complet » :
situation matrimoniale (`marital_status`) et passions (`hobbies`).

**Où le verrou doit vivre (précision 2026-09-22) :** pas un filtre
client-side parallèle à `VERIFIED` sur la liste Découvrir — ça masquait
tous les profils existants faute de `hobbies` renseignées, y compris ceux
déjà VERIFIED (régression constatée). Le PRD dit « Découvrir = utilisateurs
vérifiés » : le bon endroit est la **soumission de vérification
elle-même**, avant que l'admin ne valide. `isDiscoverEligible.isComplete`
(`discover_profile_model.dart`) reste donc inchangé (6 champs d'origine,
inconnu de `marital_status`/`hobbies`).

- **Onboarding :** nouvelle étape « Centres d'intérêt », **skippable**
  (même pattern que la photo : bouton « Passer » + `AppConfirmDialog`
  d'avertissement). Situation matrimoniale déjà collectée (étape Foi),
  inchangée.
- **Soumission de vérification** (`fetchVerification`/`canSubmit` dans
  `supabase_profile_account_datasource.dart`) : requiert désormais
  `marital_status` et `hobbies` non vides en plus des champs existants
  (photo, genre, date de naissance, pays, confession, pourquoi le
  mariage). Liste statique de `_RequirementsCard`
  (`verification_page.dart`) mise à jour en conséquence. Un profil ne peut
  donc plus jamais devenir `VERIFIED` sans ces deux infos.
- **Complétion de profil** (`ProfileFieldKeys`/`ProfileCompleteness`,
  Hub + nouveau bandeau sur Découvrir) : ajoutés aussi ici, pour que le %
  affiché à l'utilisateur (avant qu'il ne soumette sa vérification)
  reflète bien tout ce qui sera exigé. `ProfileFieldKeys.total` passe de 6
  à 8. Navigation du bandeau via `missingProfileFieldDestination` (nouveau
  fichier partagé Hub/Découvrir) : essentiels manquants → onboarding,
  sinon passions seules manquantes → « Plus d'infos », sinon → Mon Profil
  (focus photo si besoin).

### D29 - Premium sans tolérance gratuite pour invitation/message + sheet ciblé
*2026-09-22 · réf. correction porteur projet, contredit PRD §7 (tableau gating)*

Le porteur du projet a corrigé le PRD : **envoyer une invitation** et
**écrire dans une conversation déjà acceptée** exigent désormais un
abonnement Premium actif, **sans aucune tolérance gratuite**. L'ancienne
règle "FREE : 3 invitations gratuites/mois" (PRD §7) n'existe plus — elle
s'alignait déjà sur "conversation acceptée : 0 tolérance", les deux sont
maintenant identiques.

- **Quota supprimé** : `canSendFreeInvitation` remplacé par
  `isPremiumActive({subscriptionStatus, isStaff})`
  (`discover_premium_gate.dart`). Toute la chaîne de comptage mensuel
  supprimée (usecase `CountMonthlyDiscoverInvitations`, provider, méthodes
  repository/datasource, colonnes `discoverCalendarMonthStartIso` /
  `discoverMonthlyInvitationStatuses` — sans autre usage, confirmé par
  grep).
- **Conversation acceptée** : `ThreadComposerMode` gagne un cas
  `premiumRequired` (`thread_composer_mode.dart`, nouveau paramètre
  `isPremiumActive`) — le composer est remplacé par un bandeau "Passe
  Premium pour écrire ici" (tappable) quand le FREE tente d'écrire dans une
  conversation `ACCEPTED`. Abonnement chargé dans
  `ConversationThreadController.load()` via `profileGateRepositoryProvider`
  (même pattern que `open_account_person_sheet.dart`) ; `send()` refuse
  aussi en défense en profondeur.
- **Nouveau composant `PremiumFeatureSheet`** (`lib/features/premium/presentation/widgets/`) :
  sheet léger (icône + titre + message + un seul CTA vers les offres),
  distinct du sheet complet `DiscoverPremiumSheet` ("Découvre tout
  Agapeo", liste des plans). Le sheet complet reste réservé à l'offre
  spontanée périodique (`_maybeOfferPremiumSheet`) ; le nouveau sheet
  ciblé s'affiche sur une action précise bloquée : recherche, filtres
  avancés (`DiscoverToolbar.onSearchLocked`/`onFiltersLocked`,
  remplace l'ancien callback unique `onLockedTap`), invitation, écrire
  dans une conversation acceptée.
- Hors scope (confirmé par le porteur) : "qui s'intéresse à moi" (Interested
  page + fiche compte) reste sur le sheet complet, pas de changement.

### D30 - Filtres Découvrir : âge, pays, situation, confession
*2026-09-22 · réf. retours visuels (sheets dating apps) + liste inscription*

Le sheet Filtres de Découvrir n'est plus un formulaire texte (ville /
dénomination / profession). V1 utile :

- **Âge** : `RangeSlider` 18-80 (bornes par défaut = pas de filtre).
- **Pays** : même liste fermée que l'inscription (`kOnboardingCountries`),
  via `AppCountryPicker` (recherche + sheet, pas de dropdown natif).
- **Situation matrimoniale** : chips multi-sélection, mêmes 4 valeurs DB
  que l'onboarding (`SINGLE_NO_CHILDREN`, `SINGLE_WITH_CHILDREN`,
  `DIVORCED`, `WIDOWED`).
- **Confession** : chips multi-sélection, liste fermée `churchDenominations`
  (D10). Plus de saisie libre.

Le filtrage est appliqué **côté serveur** (PostgREST `eq` / `inFilter` /
`birth_date` min-max) pour ne pas se limiter aux ~60 candidats déjà
chargés, avec le même matching en défense côté client.

Ville et profession sortent du sheet (la recherche nom/ville reste sur
la page Recherche). Hors scope : distance / géoloc (pas de swipe, pas
de geo dans le PRD mobile actuel).

### D31 - Liste des confessions corrigée sur celle du web (constat capture)
*2026-09-22 · réf. capture d'écran web, corrige D10*

La liste `churchDenominations` (D10) avait été inventée sans vérifier le
web réel — 8 valeurs (Catholique, Protestante, Évangélique, Pentecôtiste,
Baptiste, Orthodoxe, Adventiste, Autre). Une capture du filtre confession
du web (liste confirmée complète par le porteur, pas de scroll caché)
montre 14 valeurs différentes, orthographe différente sur plusieurs
(« Protestant(e) » pas « Protestante », etc.) : Évangélique, Catholique,
Pentecôtiste, Chrétien(ne), Protestant(e), Baptiste, Église de réveil,
Assemblée de Dieu, Méthodiste, Christianisme Céleste, Apostolique,
Adventiste, Charismatique, Kimbanguiste. « Orthodoxe » et « Autre »
n'existent pas côté web.

Liste mobile remplacée à l'identique (mêmes valeurs, même orthographe,
même ordre) dans `church_denominations.dart` — critique pour le score de
compatibilité PRD §7 qui compare la confession par **égalité stricte de
chaîne** : toute valeur absente d'un des deux clients est un profil que
l'autre ne peut jamais matcher correctement dessus, ni même sélectionner.

### D32 - Ville et profession réintégrées au sheet Filtres, corrige D30
*2026-09-22 · réf. retour porteur projet*

D30 avait sorti ville et profession du sheet Filtres Découvrir (repliées
sur la recherche texte nom/ville de la page Recherche). Le porteur du
projet veut les deux comme filtres à part entière dans le sheet, comme
avant.

- `DiscoverQuery` gagne `city`/`profession` (texte libre, `ilike` côté
  serveur via `_sanitizeSearch` — même garde-fou anti-injection que la
  recherche nom/ville existante).
- `DiscoverProfile` gagne `profession` (absent du domaine jusqu'ici — la
  colonne `profession` était déjà sélectionnée côté datasource mais
  jamais mappée). Utilisé pour le matching de défense côté client
  (`filter_discover_profiles.dart`), même pattern que `city`.
- Sheet : deux `AppTextField` (Ville, Profession) entre le sélecteur pays
  et les chips Situation matrimoniale.

### D33 - Filtre situation matrimoniale : `marital_status` absent des tiers de fallback SELECT
*2026-09-22 · réf. bug remonté par le porteur (filtre "Célibataire sans enfant" → toujours vide)*

Fausse piste initiale : `marital_status` est un vrai ENUM Postgres
(`marital_status_type`, confirmé via `information_schema.columns`) alors que
`church_denomination` est du `text` simple, ce qui a fait suspecter
`.inFilter()` (→ `in.(...)`) comme non fiable sur les ENUM côté PostgREST.
Remplacé par `.eq()`/`.or()` — **n'a pas corrigé le bug** (confirmé par
retest du porteur), la piste ENUM était donc incorrecte ou insuffisante ;
`.inFilter()` restauré.

Vraie cause : `_selects` (`supabase_discover_datasource.dart`), la liste des
6 tiers de fallback SELECT utilisés quand une colonne manque en base,
n'incluait `marital_status` que dans les tiers 0 à 3 — absent des tiers 4 et
5. `church_denomination`, lui, est présent dans les 6 tiers. Le fallback est
mis en cache (`DiscoverSelectCache`) dès qu'un tier réussit : si l'app était
tombée sur le tier 4 ou 5 (colonne manquante ailleurs, ex. `qualities`,
`testimony`, `accepted_marital`), toutes les lignes renvoyées avaient
`marital_status = null`. Le filtre de défense côté client
(`filter_discover_profiles.dart`) exclut explicitement tout profil dont la
valeur normalisée est vide — ce qui éliminait 100 % des résultats malgré un
filtre serveur fonctionnel, alors que la confession (toujours présente)
n'était jamais affectée. Corrigé en ajoutant `marital_status` aux tiers 4 et
5.

À garder en tête : toute colonne utilisée en filtre client (défense) doit
être présente dans **tous** les tiers de `_selects`, pas seulement les
premiers — sinon le fallback SELECT peut silencieusement casser un filtre
sans jamais renvoyer d'erreur.

### Q1 — Découvrir : vérifié, complet, ou les deux ?
*réf. PRD §3, §6, §7 — contradiction interne*

Le PRD se contredit : §3 dit `VERIFIED`, §6 dit « la complétude, PAS la
vérification », §7 dit les deux. Bloquant pour l'écran Découvrir. À trancher
contre le code (le PRD dit lui-même « en cas de divergence, le code tranche »).
Tant que non tranché, le PRD n'est pas corrigé (voir V1).

*Hypothèse de travail 2026-09-18 (spec D01) :* la liste Découvrir suit
**§7** (genre opposé, pas staff, `VERIFIED`, profil complet, `is_matched=false`).
Le §3 « apparaître = VERIFIED seul » et le §6 « complétude, pas la vérif »
restent en contradiction ; pas de RPC Découvrir dans la liste PRD §21, OpenAPI
REST inaccessible à l'anon. À confirmer dès que le SQL web est lisible.

*Réponse partielle du porteur produit (2026-09-20) :* la **visibilité des
infos de profil** (nom/âge/photos non floutés/non masqués) est conditionnée à
la **vérification d'identité uniquement**, jamais au Premium seul — contredit
donc PRD §3 L.99 (« `VERIFIED` **ou** `ACTIVE` ») et surtout §3 L.100 (« ouvrir
une fiche complète → `ACTIVE` uniquement, vérif non requise »). Le Premium ne
gate que : contacter/envoyer un message, filtres avancés, et les
fonctionnalités listées à part (« qui s'intéresse à moi » reste confirmé
Premium — pas de la simple visibilité de profil).

Confirmé par le porteur :
- « Qui s'intéresse à moi » (voir qui m'a liké/favorisé) → **reste Premium**
  (`ACTIVE`), inchangé.
- Aperçu de soi côté Mon Compte (C06) → **laissé tel quel pour l'instant**,
  hors périmètre de cette clarification.

*Réponse finale du porteur produit (note vocale, 2026-09-20) :* confirmé sans
ambiguïté — voir/ouvrir un profil (identité + fiche complète) est débloqué dès
que le profil est **soumis et validé** (vérification d'identité), point.
Le Premium ne bloque que l'**envoi de messages** et l'**envoi d'invitations**
(« les sept points », c-à-d les avantages payants du PRD §3/§7) — rien
d'autre côté visibilité. **Q1 est tranchée** :

- `revealCardIdentity` (`discover_mask.dart`) → `visitorVerified` seul, plus
  d'OR avec `visitorPremiumActive`.
- `canOpenDiscoverProfile` (`discover_premium_gate.dart`) → `visitorVerified`
  seul, découplé de `canUseDiscoverSearchFilters` (qui reste `ACTIVE` pour les
  filtres avancés, eux bien confirmés Premium).
- `canFavoriteDiscoverProfile` → repassé à `visitorVerified` seul. Vérifié
  contre PRD §7/§19/§22 : le favori n'a aucun effet collatéral (pas de quota,
  pas de droit de contact, pas de critère de score) — donc rien à bypasser
  derrière Premium ; PRD §3 (« `VERIFIED` et `ACTIVE` ») et §19 (« Favoris
  (Premium) ») sont désormais **obsolètes** sur ce point, à corriger (voir V1).
- Invitation (`canInviteDiscoverProfile` + `canSendFreeInvitation`) : déjà
  conforme — vérifié pour inviter, quota 3/mois en FREE/CANCELED vs illimité
  en `ACTIVE`, ce qui *est* la restriction Premium attendue sur l'envoi.
- Inchangé (confirmé précédemment) : « qui s'intéresse à moi » reste
  `ACTIVE`-only ; aperçu de soi (C06/Mon Compte) laissé tel quel pour l'instant.

PRD §3 (lignes ~99-100, 108 partiellement) et §19 restent à corriger pour
refléter cette règle (voir V1) — le code fait foi entretemps.

### Q2 — Initiation du paiement mobile
*réf. PRD §11 · addendum §3.2*

Test web suggère une intégration directe client → SasPay. À confirmer, puis :
- La clé SasPay dans le client est-elle **publiable** (sans risque à embarquer)
  ou **secrète** (faille déjà présente côté web) ?
- SasPay fournit-il un **SDK natif** ou une **API HTTP** ?
- Comment la ligne `transactions` est-elle rattachée au membre pour la
  réconciliation (le webhook SasPay ne contient pas l'identité) ?

### Q3 — Émetteur push natif
*réf. PRD §12, §21 · addendum §4*

Existe-t-il déjà un émetteur FCM/APNs, ou seulement le Web Push VAPID actuel ?
Détermine si le pont push natif est à construire de zéro.

### Q4 — Deep links & accès dev
*réf. PRD §4, §21 · addendum §1.2*

URL de redirection (App Links / Universal Links) déjà configurées côté Supabase ?
Identifiant de package déjà réservé ? Existe-t-il un projet Supabase de
**staging**, ou tout est en prod ? Comptes de test disponibles ?

### Q5 — Format d'enregistrement des notes vocales : illisibles sur iOS
*2026-09-22 · réf. bug remonté par le porteur (lecture d'une note vocale échoue)*

Repro confirmée : une note vocale existante (`message_attachments`, fichier
`....webm`) se télécharge correctement (URL signée valide, téléchargement
Dio OK) mais `just_audio` échoue à l'ouvrir sur iOS avec l'erreur native
AVFoundation `-11828 Cannot Open`. **AVFoundation n'a pas de décodeur
WebM/Opus** — limitation native de la plateforme, pas un bug de l'app.
Android (ExoPlayer) lirait probablement ce même fichier sans problème,
d'où l'illusion d'un souci d'URL alors que le téléchargement fonctionne.

Le mobile n'enregistre pas encore de note vocale lui-même (« Note vocale »
dans le sheet Joindre affiche toujours « Média : bientôt ») — tous les
vocaux existants viennent donc probablement d'un enregistrement web
(`MediaRecorder`, WebM/Opus par défaut dans la plupart des navigateurs).

À trancher avec le porteur avant de corriger :
- **Transcodage backend/web** (recommandé) : convertir les vocaux en
  AAC/m4a à l'upload (ou à la volée), format lisible partout. Nécessite un
  changement hors du repo mobile.
- **Transcodage côté mobile** (FFmpeg, ex. `ffmpeg_kit_flutter`) :
  possible mais alourdit l'app (~20-50 Mo) et ce paquet a des soucis de
  licence/disponibilité récents sur pub.dev.

---

## À VÉRIFIER (inspection technique — avant de coder les écrans concernés)

### V1 — Contradiction Découvrir dans le PRD
*réf. Q1*

Une fois Q1 tranchée contre le code, **corriger la phrase du PRD §6** (« pas la
vérification ») pour la mettre en accord avec §3/§7. Correction dans le PRD, pas
dans l'addendum : c'est une erreur sur le comportement existant.

### V2 — RLS REST des tables sensibles
*réf. PRD §18*

Le §18 **affirme** que la RLS interdit de lire le rôle d'autrui, de forcer sa
vérification, ou d'écrire dans une conversation où l'on ne participe pas. Affirmé,
pas prouvé. Audit anon déjà fait : écriture anonyme bloquée (`42501`), lecture
anonyme = 0 ligne — cohérent mais insuffisant (c'est le niveau *authentifié* qui
compte). À vérifier au niveau connecté / par lecture directe des policies :
- `profile_restricted` — propriétaire seul (rôle, abonnement, suspension, géoloc)
- `profile_private` — jamais lisible par autrui (téléphone)
- `messages` / `conversations` — participants seuls
- `profiles` — quelles colonnes un autre membre voit-il réellement ?

### V3 — Autorisation Realtime sur `messages` (surface séparée du RLS REST)
*réf. PRD §8 · addendum §2*

Le Realtime a sa propre autorisation, distincte du RLS REST. Si `messages` est
dans la publication Realtime sans canal privé/authorized, un client peut
s'abonner au flux de **tous** les messages, même si le RLS REST est parfait.
Footgun Supabase classique. À vérifier en même temps que V2. Idem, moindre
gravité, pour le broadcast « typing ».

---

## Contexte projet (constaté)

- **Projet Supabase :** `cfmrykzqxcjhpktuxopu` (région à confirmer).
- **Auth activée :** email + Google. Confirmation email requise
  (`mailer_autoconfirm: false`). Twilio branché (OTP SasPay / SMS).
- **Tables confirmées présentes** (sonde anon) : profiles, matches, messages,
  conversations, reports, blocks, notifications — cohérent avec PRD §19.
- **Inscription ouverte** (`disable_signup: false`).
