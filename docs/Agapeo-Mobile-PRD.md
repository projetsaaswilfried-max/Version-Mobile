# Agapeo — Product Requirements Document (Mobile)

**Version 1.0 — 13 septembre 2026**
Photographie de l'application web existante, à parité pour le développement mobile.

> **Comment lire ce document.** Chaque règle de blocage (vérification, abonnement, quota) est donnée avec sa condition exacte telle qu'appliquée dans le code — à reproduire à l'identique côté mobile, pas à réinterpréter. La sécurité repose sur des règles au niveau de la base de données (RLS Supabase) : un client mobile natif qui interroge directement Supabase est soumis exactement aux mêmes règles qu'aujourd'hui le navigateur — voir §18.

Ce document décrit **l'application telle qu'elle existe et fonctionne aujourd'hui** — pas une feuille de route — pour servir de base à la construction d'une application mobile à parité fonctionnelle.

## Sommaire

**Cadrage**
1. [Aperçu produit](#1-aperçu-produit)
2. [Comptes & rôles](#2-comptes--rôles)
3. [Matrice de permissions](#3-matrice-de-permissions)

**Parcours membre**
4. [Authentification](#4-authentification)
5. [Onboarding](#5-onboarding)
6. [Profil & vérification](#6-profil--vérification)
7. [Découvrir](#7-découvrir)
8. [Messagerie](#8-messagerie)
9. [Le Match (couple)](#9-le-match-couple)
10. [Fil d'actualité](#10-fil-dactualité)
11. [Premium & paiements](#11-premium--paiements)
12. [Notifications](#12-notifications)
13. [Support](#13-support)
14. [Compte & paramètres](#14-compte--paramètres)
15. [Signalement & blocage](#15-signalement--blocage)

**Plateforme**
16. [Espace admin](#16-espace-admin)
17. [Communications automatisées](#17-communications-automatisées)
18. [Modèle de sécurité](#18-modèle-de-sécurité)

**Référence technique**
19. [Modèle de données](#19-modèle-de-données)
20. [Énumérations](#20-référence-des-énumérations)
21. [Infrastructure existante](#21-infrastructure-existante)
22. [Hors périmètre & notes mobile](#22-hors-périmètre--notes-pour-le-développeur-mobile)

---

## 1. Aperçu produit

Agapeo met en relation des célibataires chrétiens partageant une démarche sérieuse vers le mariage. La plateforme combine un moteur de découverte basé sur un score de compatibilité (foi, valeurs, mode de vie), une messagerie à invitation (jamais de contact non sollicité), un fil d'actualité communautaire (enseignements, témoignages) et un système de vérification d'identité par selfie en direct pour limiter les faux profils.

Le modèle est **freemium** : l'inscription et la création de profil sont gratuites, mais l'essentiel de l'usage réel (consulter un profil en entier, écrire à quelqu'un, être visible dans Découvrir) est verrouillé derrière la vérification d'identité et/ou un abonnement Premium payant. Le mode de paiement dominant est le Mobile Money local (Orange Money, Wave, MTN…), avec la carte bancaire en option secondaire.

| | |
|---|---|
| **Langue** | Français — seule langue supportée, aucune infrastructure i18n |
| **Devise** | FCFA (XOF) — conversion locale automatique pour le Mobile Money |
| **Plateforme actuelle** | PWA — web installable, push déjà fonctionnel (voir §21) |

**Ce que l'app ne fait volontairement pas :**
- Pas de swipe façon Tinder — Découvrir est une liste triée par compatibilité, pas une pile de cartes.
- Pas de messagerie ouverte : toute conversation démarre par une invitation que l'autre doit accepter.
- Pas de géolocalisation en temps réel exploitée dans le produit (latitude/longitude existent en base mais ne pilotent aucune fonctionnalité visible aujourd'hui).
- Pas de multi-langue, pas de mode "découverte sans compte".

---

## 2. Comptes & rôles

Trois axes indépendants déterminent ce qu'un compte peut faire : son rôle, son état de vérification, son abonnement.

### Rôles (`app_role`)

| Rôle | Périmètre |
|---|---|
| `USER` | Membre ordinaire — toutes les règles de ce document s'appliquent. |
| `MODERATOR` | Accède à l'espace admin : vérifications, photos, signalements, support. |
| `ADMIN` | Tout MODERATOR + gestion des membres (suspension, Premium manuel), fil officiel, campagnes email, transactions. |
| `SUPER_ADMIN` | Tout ADMIN + attribution des rôles, journal d'audit, choix du prestataire de paiement actif. |

Le rôle réel vit uniquement dans `profile_restricted.role` (jamais exposé publiquement). Un drapeau public dérivé, `profiles.is_staff` (vrai dès que le rôle n'est pas USER), sert à afficher le badge "équipe" et à exempter le personnel des règles de genre opposé / vérification / Premium / blocage un peu partout — et, depuis une évolution récente, à **masquer entièrement les comptes staff des autres membres** (invisibles dans Découvrir, jamais likables/favoris/contactables).

### États d'un compte membre

- **`photo_verification_status`** — `UNVERIFIED` / `PENDING` / `VERIFIED` / `REJECTED` — condition d'accès à quasiment toute interaction réelle (voir §3). Source de vérité : la dernière ligne `verification_requests`.
- **`subscription_status`** — `FREE` / `ACTIVE` / `EXPIRED` / `CANCELED` — **EXPIRED ≠ FREE** : un abonnement qui a expiré verrouille plus strictement (page de blocage entière sur Découvrir/Messages/Support) qu'un compte qui n'a simplement jamais payé.
- **`is_suspended`** — compte banni côté Supabase Auth (session invalidée partout, pas seulement caché dans l'UI) — décision ADMIN+.
- **`is_matched`** — vrai dès qu'un "match" (couple) a été accepté avec quelqu'un — exclut le profil de Découvrir pour tout le monde tant qu'il reste vrai.
- **`onboarding_completed`** — contrôle uniquement si l'assistant d'inscription doit se réafficher — **n'implique ni profil complet ni vérifié**, un membre peut finir l'onboarding sans jamais soumettre sa vérification ("Terminer sans soumettre").

> Ces trois axes (rôle, vérification, abonnement) sont indépendants : un membre Premium peut être non vérifié, un membre vérifié peut être gratuit, etc. Aucune règle du produit ne suppose qu'un axe en implique un autre — chacune doit être vérifiée séparément côté mobile, exactement comme documenté en §3.

---

## 3. Matrice de permissions

La référence unique pour savoir ce qu'un compte peut faire — condition exacte, pas une approximation.

| Action | Condition exacte requise | Comportement si bloqué |
|---|---|---|
| Apparaître dans Découvrir | `VERIFIED` (indépendant de l'abonnement) | Invisible pour tout le monde |
| Voir un aperçu de carte (photo nette, nom/âge/ville masqués) | Aucune — accessible à tout membre connecté | — |
| Voir les infos réelles (nom/âge/ville en clair) sur la carte | `VERIFIED` **ou** `subscription_status = ACTIVE` | Champs masqués (2 premiers caractères + astérisques) |
| Ouvrir une fiche complète (modale Découvrir ou URL directe) | `subscription_status = ACTIVE` uniquement (vérification du visiteur non requise) | Modale "Passe Premium" |
| Liker un profil | `VERIFIED` — action gratuite, pas besoin de Premium | Modale "Valide ton profil" |
| Mettre un profil en favori | `VERIFIED` **et** `ACTIVE` | Vérification d'abord, puis Premium |
| Voir le nombre de "qui m'aime" | Aucune | — |
| Voir les identités de "qui m'aime" | `subscription_status = ACTIVE` | Cartes floutées + CTA Premium |
| Envoyer une invitation (démarrer une conversation) | `VERIFIED`, et si compte gratuit : max 3 invitations/mois civil (illimité si `ACTIVE`) | Modale vérification ou Premium selon le cas |
| Écrire dans une conversation déjà acceptée | `subscription_status = ACTIVE` — **aucune tolérance gratuite**, contrairement à l'invitation | Zone de saisie remplacée par un bandeau "Passe Premium" |
| Proposer/accepter un match (couple) | Conversation au statut `ACCEPTED` ; aucun des deux déjà `is_matched` | Bouton absent / erreur explicite |
| Utiliser les filtres avancés (ville, dénomination, profession…) | `subscription_status = ACTIVE` | Champs verrouillés avec icône cadenas |
| Nombre de photos de profil | 2 (gratuit) / 10 (Premium) / illimité (staff) | Upload bloqué au-delà |
| Délai d'examen de la vérification | 48h (gratuit) / 24h (Premium au moment de la soumission) | — |
| Publier dans le fil personnel, liker/commenter/partager un post | Aucune restriction Premium/vérification trouvée | — |
| Ouvrir un dossier support | Un seul dossier `OPEN` à la fois ; `subscription_status ≠ EXPIRED` | Page de blocage si EXPIRED |

Chaque règle ci-dessus est appliquée **à la fois côté client et côté base de données** (RLS) — un contournement de l'UI mobile ne suffirait pas à débloquer l'action, la requête Supabase serait de toute façon rejetée. Voir §18.

---

## 4. Authentification

### Méthodes disponibles

- **Email + mot de passe** — mot de passe ≥8 caractères avec au moins 1 lettre et 1 chiffre ; email de confirmation obligatoire avant connexion.
- **Google OAuth** — un compte créé via Google n'a *jamais* le genre/date de naissance/pays renseignés par Google ; ces trois champs restent à collecter dans l'onboarding (étape "essentiel", voir §5) exactement comme pour un compte email classique.
- **Réinitialisation du mot de passe** — lien email, toujours le même message de confirmation générique que l'adresse existe ou non (anti-énumération).

### Ce qui se crée automatiquement à l'inscription

Un déclencheur base de données crée, dans la même transaction que la création du compte Auth :
- `profiles` — prénom/nom depuis les métadonnées d'inscription (ou le prénom Google), genre/date de naissance/pays laissés `null` si absents.
- `profile_private` — ligne vide (téléphone à null).
- `profile_restricted` — `role = USER`, `subscription_status = FREE`.

Rien d'autre n'existe encore : ni demande de vérification, ni abonnement push, ni événement d'onboarding.

> **Note pour le mobile.** Utiliser le SDK Supabase natif (Kotlin/Swift/Flutter selon la techno choisie) pointé sur le même projet — il gère lui-même le stockage sécurisé du token et son rafraîchissement. En revanche, **aucune logique de redirection post-connexion n'existe côté serveur pour un client natif** (elle vit dans un fichier `proxy.ts` propre au web) : l'app mobile doit elle-même, juste après une connexion réussie, lire `profiles.onboarding_completed` et `profile_restricted.is_suspended`/`subscription_status` pour décider où naviguer (onboarding, suspension, ou accueil).

---

## 5. Onboarding

Un assistant en 3 à 5 étapes selon le profil — jamais bloquant, la vérification reste optionnelle à ce stade.

1. **Informations essentielles** (uniquement si genre/date de naissance/pays manquent — donc systématique après Google) — genre, date de naissance (18 ans minimum), pays de résidence. Verrouillé définitivement une fois rempli : ces trois champs ne sont ensuite plus modifiables par le membre.
2. **Photos** (obligatoire) — au moins 1 photo pour continuer, 2 gratuit / 10 Premium. La première photo devient la photo principale.
3. **Selfie** (uniquement si le profil n'est pas encore VERIFIED) — capture caméra en direct exclusivement, jamais un import de fichier ("anti-usurpation"). Stockée en attente jusqu'à la soumission finale.
4. **Foi** (obligatoire) — confession chrétienne (texte libre, requis), situation matrimoniale (liste), taille en cm (optionnel).
5. **Préférences & soumission** (obligatoire) — présentation, loisirs, "pourquoi cherches-tu le mariage ?" (requis), valeurs fondamentales, tranche d'âge recherchée, situation matrimoniale acceptée, pays acceptés. À la validation : si aucune vérification n'est nécessaire → onboarding terminé directement ; sinon la demande de vérification est soumise avec le selfie capturé à l'étape 3 (ou capturé à la volée si l'étape avait été sautée).

À tout moment, un membre peut choisir **"Terminer sans soumettre"** : l'onboarding se termine, l'app devient utilisable, mais le profil reste `UNVERIFIED` tant qu'aucune vérification n'est soumise séparément depuis "Mon Compte".

---

## 6. Profil & vérification

### Champs d'un profil

**Identité & mode de vie** — Prénom, nom, genre\*, date de naissance\*, pays\*, ville, profession, niveau d'études, langues, taille (120–230cm), situation matrimoniale, statut (Disponible / En discussion / En pause), bio (≤600 car.), citation. *(\*verrouillé après l'étape essentielle)*

**Foi** — Confession\*, années de cheminement, engagement (niveau), ministère, description de la foi, baptisé (oui/non), verset préféré (≤200), témoignage (≤600), "ce que Dieu fait dans ma vie".

**Vision du mariage** — Pourquoi le mariage\* (≤1000), vision du couple, vision familiale (≤1000), nombre d'enfants souhaités, prêt à déménager, horizon de mariage, valeurs fondamentales (≤12 tags).

**À propos** *(jamais utilisé par le moteur de compatibilité — purement présentatif)* — Passions, loisirs (≤12), qualités (≤10), j'aime / je n'aime pas.

**Préférences partenaire** — Âge min/max recherché, valeurs souhaitées, pays acceptés (≤8), situations matrimoniales acceptées (multi).

### Photos — cycle de vie de modération

`DRAFT → PENDING → APPROVED / REJECTED`

- Les photos ajoutées **avant** la première soumission de vérification restent en `DRAFT` (invisibles de l'équipe) jusqu'à la soumission, qui les fait toutes basculer en `PENDING` d'un coup.
- Une fois `VERIFIED`, ajouter une nouvelle photo exige un **nouveau selfie en direct** à chaque lot ajouté (jamais un import) — comparé manuellement par l'équipe.
- Supprimer sa photo principale alors qu'on est `VERIFIED` rétrograde automatiquement tout le profil en `UNVERIFIED` — avertissement explicite affiché avant confirmation.

### Vérification — parcours complet

1. **Soumission** — nécessite un profil "complet" (voir encadré) + un selfie. Priorité (24h vs 48h) calculée selon que l'abonnement est actif *au moment de la soumission*.
2. **Examen** — un modérateur compare le selfie aux photos postées, dans l'espace admin.
3. **Décision** — Approuvé → badge `VERIFIED` public + email + message de bienvenue automatique dans la messagerie (voir §17). Rejeté → motif obligatoire, retour à `UNVERIFIED`, les photos associées repassent en `DRAFT` ; le membre doit tout resoumettre via l'onboarding, pas via un simple nouveau selfie isolé.

> **Profil "complet"** = photo principale + confession + "pourquoi le mariage" + genre + date de naissance + pays tous renseignés. C'est une condition calculée à la volée sur les colonnes du profil, jamais un champ stocké — et c'est elle, pas la vérification, qui conditionne l'apparition dans Découvrir.

---

## 7. Découvrir

### Structure de l'écran

Deux sections : **"Recommandée pour vous"** (3 profils fixes, renouvelés une fois par jour — même tirage pour tout le monde sur la même journée grâce à un mélange déterministe basé sur la date), et **"Autres profils"** (le reste du vivier, paginé par 12).

### Algorithme de compatibilité (100 points max)

| Dimension | Points | Règle |
|---|---|---|
| Même confession | 12 | Égalité stricte du champ dénomination |
| Même niveau d'engagement spirituel | 8 | Égalité stricte |
| Valeurs communes | 0–20 | Proportionnel au taux de recouvrement des listes |
| Loisirs communs | 0–15 | Proportionnel au taux de recouvrement |
| Localisation | 15 ou 8 | 15 si même pays ; 8 si le pays de l'un figure dans les pays acceptés de l'autre |
| Tranche d'âge réciproque | 10 ou 5 | 10 si les deux sont dans la fourchette de l'autre ; 5 si un seul sens |
| Situation matrimoniale réciproque | 20 ou 10 | Facteur de score seulement — ne filtre jamais un candidat |

### Éligibilité pour apparaître à qui que ce soit

Genre opposé au visiteur, pas staff, `VERIFIED`, profil "complet" (voir §6), pas déjà en couple (`is_matched=false`).

Le masquage des infos (nom/âge/ville) et le déblocage de la fiche complète suivent exactement la matrice du §3 — pas de règle supplémentaire propre à Découvrir au-delà de ça, si ce n'est le popup de relance ci-dessous.

> **Popup de relance Premium.** Pour tout compte non-Premium/non-staff : s'affiche **une seule fois par session** sur l'accueil, et à **chaque chargement de Découvrir** (premier affichage, changement de page, changement de filtre) sans aucune limite — décision produit assumée, Découvrir étant l'endroit où la limite gratuite se ressent le plus.

---

## 8. Messagerie

### Modèle d'invitation

`conversations.status` ∈ `PENDING → ACCEPTED / DECLINED`

- "Envoyer un message" ouvre toujours une modale d'invitation, jamais un chat direct.
- Seul le destinataire peut accepter ; refuser retire la conversation définitivement des deux côtés (ne réapparaît jamais).
- Une invitation vers quelqu'un déjà en conversation réutilise la conversation existante au lieu d'en recréer une.

### Types de message

Texte, image (15 Mo max), vidéo (100 Mo), document (25 Mo, pdf/doc/xls/txt/zip), note vocale, système (une seule ligne centrée, réservé aux messages automatiques). Suppression = suppression douce (contenu vidé, jamais un vrai delete), uniquement par l'expéditeur.

### Accusés de lecture, présence, temps réel

Le statut "lu" de l'autre n'est révélé que si **le lecteur lui-même** a activé "Afficher les confirmations de lecture" dans ses réglages. Trois canaux temps réel distincts : messages de la conversation ouverte, liste globale des conversations (badges non-lus toujours à jour même sur un fil inactif), et un canal de frappe éphémère ("en train d'écrire…", expire après 3s d'inactivité).

### Fils système (Agapeo)

Un compte système "Agapeo" peut ouvrir une conversation à sens unique avec n'importe quel membre (y compris gratuit) pour les messages de bienvenue et de relance Premium — voir §17. La zone de saisie y est remplacée par un texte explicite ; répondre y est techniquement impossible.

### Masquer une conversation vs bloquer

"Supprimer la discussion" ne masque la conversation que pour soi (réapparaît dès un nouveau message). Bloquer quelqu'un (depuis la conversation, un profil, ou un post) est symétrique et définitif tant que non annulé : plus aucun message possible dans les deux sens, disparition mutuelle de Découvrir et des profils publics. Seul l'écran "Comptes bloqués" (Mon Compte & Sécurité) permet de débloquer, puisque les points d'entrée habituels ont disparu.

---

## 9. Le Match (couple)

Une fonctionnalité rare et volontairement exclusive, posée au-dessus d'une conversation déjà acceptée.

1. **Proposition** — seulement possible depuis une conversation `ACCEPTED`, et seulement si aucun des deux n'est déjà en couple ailleurs.
2. **Réponse** — seul le destinataire peut accepter ou refuser ; l'un ou l'autre peut annuler une demande en attente ou déjà acceptée, à tout moment.
3. **Effet de l'acceptation** — les deux profils passent `is_matched=true` et disparaissent de Découvrir pour tout le monde ; email + notification de félicitations envoyés aux deux.
4. **Annulation** — libère `is_matched`, les deux profils redeviennent visibles dans Découvrir.

Un seul match actif (en attente ou accepté) par paire — contrainte imposée en base, pas seulement dans l'UI.

---

## 10. Fil d'actualité

- **Posts officiels** (équipe Agapeo) — catégories Enseignement, Témoignage, Atelier/Mariage, Conseil, Annonce, Citation, Verset, Nouveauté. Formats : image, galerie, vidéo, YouTube (intégré, jamais réhébergé), carte-citation. Les posts épinglés restent toujours en tête.
- **Posts personnels** — créés uniquement depuis "Mes Publications" (réglages de compte), un seul média (image ≤15 Mo ou vidéo), contenu ≤600 caractères. **N'apparaissent jamais dans le fil principal** — visibles uniquement sur le profil public de leur auteur.

Engagement disponible sur tout post : like, commentaire (un seul niveau de réponses, pas de fil imbriqué), partage (Facebook/WhatsApp/Telegram/copie de lien), enregistrement, vues (comptées une fois la carte visible à 50%, jamais la propre vue de l'auteur, dédupliquées sur 12h). Aucune restriction Premium trouvée sur le fil : lire, liker, commenter, partager et publier sont libres pour tout compte.

---

## 11. Premium & paiements

### Formules en vente

| Formule | Durée | Prix |
|---|---|---|
| 1 semaine | 7 jours | 2 335 FCFA |
| Mi-mois | 15 jours | 4 086 FCFA |
| Mensuel | 30 jours | 7 003 FCFA |
| Trimestriel *(recommandé)* | 90 jours | 17 507 FCFA (≈5 832/mois) |

Aucun prestataire ne propose de facturation récurrente native — Agapeo simule lui-même l'expiration/le renouvellement via `subscription_current_period_end` et un cron quotidien.

### Deux prestataires, un seul actif à la fois pour le Mobile Money

**Chariow — paiement hébergé.** Toujours utilisé pour la carte bancaire. Redirection vers une page de paiement hébergée, retour via webhook signé. Un job de réconciliation compense les webhooks qui ne partent jamais (incident réel déjà rencontré).

**SasPay — Mobile Money natif.** Flux intégré à l'app (pas de redirection pour la plupart des réseaux) : prompt USSD envoyé directement au téléphone, ou OTP par SMS selon le réseau. Le webhook SasPay ne contient aucune donnée permettant de retrouver le membre — la réconciliation active, exécutée chaque minute, est donc le mécanisme principal de confirmation, pas un simple filet de sécurité.

### Popups & relances

- **Popup de bienvenue** — une fois par session, sur l'accueil.
- **Popup Découvrir** — à chaque chargement, sans limite (voir §7).
- **Séquence email** — tous les 2 jours pendant 30 jours après validation du profil, contenu dynamique selon le comportement réel (nombre de personnes intéressées, profils très compatibles disponibles).
- **Messages système "Agapeo"** — même cadence, dans la messagerie, à sens unique.

---

## 12. Notifications

Types regroupés par catégorie : **Messages** (nouveau message, invitation reçue/acceptée), **Profil** (nouveau favori, visite, like, demande/acceptation de match, photo approuvée/rejetée), **Publications** (like, commentaire), **Recommandations**, **Plateforme** (nouveau post officiel, réponse support). Les notifications de type favori/like/visite s'agrègent tant qu'elles restent non lues (une seule ligne "3 personnes ont aimé…" plutôt que 3 lignes séparées).

Le push est déjà entièrement câblé côté web (Web Push standard, clés VAPID) : chaque insertion dans la table `notifications` déclenche automatiquement l'envoi, donc les préférences de notification n'ont pas besoin d'un second système — elles agissent en amont, sur la création de la ligne elle-même.

---

## 13. Support

Un membre ne peut avoir qu'**un seul dossier "OPEN" à la fois** — le bouton "Ouvrir un dossier" disparaît tant qu'un dossier est déjà en cours. Message texte + une image en pièce jointe possible. Un compte `EXPIRED` (abonnement expiré, jamais un simple compte gratuit) est entièrement bloqué de cet écran.

---

## 14. Compte & paramètres

Huit onglets sous "Mon Compte" :

| Onglet | Contenu |
|---|---|
| **Mon Profil** | Photos, identité, ville/profession, bio |
| **Ma Foi** | Confession, engagement, témoignage, verset préféré |
| **Plus d'infos** | Qualités, vision familiale — jamais utilisé par le matching |
| **Mes Publications** | Créer/éditer/supprimer ses posts personnels |
| **Mes Favoris** | Liste des profils favoris |
| **Qui s'intéresse à moi** | Compte gratuit, identités Premium |
| **Confidentialité** | Statut en ligne, accusés de lecture, profil invisible, préférences de notification |
| **Mon Compte & Sécurité** | Statut de vérification, comptes bloqués, changement email/mot de passe, export de données (JSON téléchargé, jamais emailé), suppression de compte (irréversible) |

---

## 15. Signalement & blocage

**Signaler** (profil, message ou publication) : motif parmi une liste fixe (comportement irrespectueux, faux profil, contenu inapproprié, sollicitation commerciale, autre) + détails libres optionnels. Aucune conséquence immédiate visible pour le déclarant au-delà d'une confirmation.

**Bloquer** : symétrique, immédiat — plus aucun message possible, disparition mutuelle de Découvrir et des profils. Voir §8 pour le détail du parcours de déblocage.

---

## 16. Espace admin

Un espace web séparé (`/admin`), jamais destiné au mobile membre. MODERATOR gère les files de vérification/photos/signalements/support ; ADMIN ajoute la gestion des membres (suspension, Premium manuel), le fil officiel, les campagnes email et les transactions ; SUPER_ADMIN ajoute l'attribution des rôles, le journal d'audit et le choix du prestataire de paiement actif. Un signalement peut désormais déclencher l'ouverture d'un dossier support avec la personne visée, pour lui demander de s'expliquer avant de trancher.

---

## 17. Communications automatisées

| Séquence | Déclenchement | Objectif |
|---|---|---|
| Soumets ton profil | J1/J3/J5/J7 après inscription, si toujours UNVERIFIED | Pousser vers la vérification |
| Il ne reste qu'un selfie | Une fois, dès que le profil est complet mais pas soumis | Relance ciblée et actionnable |
| Passe Premium | Tous les 2 jours sur 30 jours après validation | Email + message in-app dynamique selon le comportement |
| Rappel d'expiration | 1 à 5 jours avant la fin de l'abonnement (selon la formule) | Éviter le désabonnement passif |
| Message non lu | 2h à 24h après réception | Ramener vers une conversation en attente |
| Digest hebdomadaire | Chaque semaine, si activé | Top recommandations de la semaine |
| Paiement échoué / abandonné | 5min, J+1, J+3 après un échec | Récupérer une transaction perdue |

---

## 18. Modèle de sécurité

Chaque table est verrouillée par défaut (Row Level Security). **Rien ne dépend d'un contrôle frontend seul** — un client mobile natif interrogeant Supabase avec la clé du membre est soumis exactement aux mêmes règles que le navigateur aujourd'hui : impossible de lire le rôle d'un autre membre, de forcer sa propre vérification, ou d'insérer un message dans une conversation à laquelle on ne participe pas, quelle que soit l'app qui émet la requête.

Les colonnes sensibles (rôle, suspension, abonnement, géolocalisation) vivent dans une table séparée (`profile_restricted`) plutôt que sur `profiles`, précisément parce que Postgres filtre les lignes, pas les colonnes — un visiteur autorisé à lire la ligne d'un autre membre (Découvrir, messagerie, fil) recevrait sinon toutes ses colonnes, y compris celles jamais destinées à être publiques.

> Toute capacité "élevée" (changer un rôle, suspendre, accorder Premium manuellement, modérer) ne passe aujourd'hui que par le serveur web avec une clé de service que le mobile ne détiendra jamais — ces actions resteraient à exposer via une API propre à Agapeo si un jour nécessaires côté mobile, jamais en appelant Supabase directement avec les identifiants d'un membre.

---

## 19. Modèle de données

Les tables qui comptent pour un client mobile, groupées par domaine.

### Identité & profil

| Table | Rôle | Colonnes clés |
|---|---|---|
| `profiles` | Le profil public — grande table plate, lisible par les autres membres selon les règles de §18 | identité, foi, vision du mariage, préférences, statuts dérivés (`is_staff`/`is_premium`/`is_matched`, tous en lecture seule pour le propriétaire) |
| `profile_private` | Téléphone — jamais lisible par un autre membre | `phone`, `phone_country_code` |
| `profile_restricted` | Rôle, abonnement, suspension — lisible par le propriétaire seul, écrit uniquement côté serveur | `role`, `subscription_status`, `subscription_current_period_end`, `is_suspended` |
| `profile_photos` | Galerie, avec cycle de modération | `moderation_status`, `is_primary`, `selfie_storage_path` |
| `verification_requests` | Historique des demandes de vérification | `status`, `is_priority`, `rejection_reason` |

### Découverte & matching

| Table | Rôle |
|---|---|
| `favorites` | Favoris (Premium) |
| `profile_likes` | Likes (gratuit) |
| `profile_views` | Vues de profil — écriture uniquement via la fonction `record_profile_view()`, jamais un insert direct |
| `blocks` | Blocages (paire blocker/blocked) |
| `matches` | Propositions/acceptations de couple, un seul actif par paire |

### Messagerie

| Table | Rôle |
|---|---|
| `conversations` | `status` (PENDING/ACCEPTED/DECLINED), `is_system_broadcast` pour les fils Agapeo à sens unique |
| `conversation_participants` | `last_read_at` (pilote le badge non-lu), `hidden_at` (masquage personnel) |
| `messages` | `type`, `content`, `status`, `read_at`, `deleted_at` |
| `message_attachments` | Fichier joint (type, taille, durée pour l'audio) |

### Fil & contenu

| Table | Rôle |
|---|---|
| `posts` | `post_type` (OFFICIAL/PERSONAL), `category`, compteurs dénormalisés (likes/commentaires/partages/vues) |
| `post_media`, `post_likes`, `post_comments` (avec `parent_comment_id`, un seul niveau), `post_bookmarks`, `post_shares`, `post_views` | Engagement — `post_views` uniquement via `record_post_view()` |

### Premium & paiement

| Table | Rôle |
|---|---|
| `transactions` | Historique de paiement, lisible par son propre propriétaire uniquement |
| `payment_settings` | Prestataire Mobile Money actif (lecture publique, écriture SUPER_ADMIN) |
| `fx_rates` | Taux de change pour la conversion FCFA → devise locale (interne) |

### Notifications & modération

| Table | Rôle |
|---|---|
| `notifications` | `type`, `is_read`, `aggregate_count` (agrégation des favoris/likes non lus) |
| `push_subscriptions` | Un abonnement Web Push par appareil/navigateur |
| `reports` | Seul le champ `status` reste modifiable après création |
| `support_tickets` / `support_messages` | Un dossier OPEN à la fois par membre |

---

## 20. Référence des énumérations

Valeurs exactes, orthographe incluse — à faire correspondre trait pour trait côté mobile.

| Énumération | Valeurs |
|---|---|
| `app_role` | `USER, MODERATOR, ADMIN, SUPER_ADMIN` |
| `gender_type` | `MALE, FEMALE` |
| `relationship_status` | `AVAILABLE, IN_DISCUSSION, ON_PAUSE` |
| `marital_status_type` | `SINGLE_NO_CHILDREN, SINGLE_WITH_CHILDREN, DIVORCED, WIDOWED` |
| `verification_status` | `UNVERIFIED, PENDING, VERIFIED, REJECTED` |
| `photo_moderation_status` | `DRAFT, PENDING, APPROVED, REJECTED` |
| `post_type` | `OFFICIAL, PERSONAL` |
| `post_category` | `TEACHING, TESTIMONY, WORKSHOP, ADVICE, ANNOUNCEMENT, QUOTE, VERSE, NEWS` |
| `post_media_type` | `IMAGE, GALLERY, VIDEO, QUOTE_CARD, TEXT_ONLY, YOUTUBE` |
| `message_type` | `TEXT, IMAGE, VIDEO, DOCUMENT, VOICE, SYSTEM` |
| `message_status` | `SENT, DELIVERED, READ` |
| `conversation_status` | `PENDING, ACCEPTED, DECLINED` |
| `match_status` | `PENDING, ACCEPTED, CANCELLED` |
| `subscription_status` | `FREE, ACTIVE, CANCELED, EXPIRED` |
| `transaction_status` | `PENDING, SUCCEEDED, FAILED, REFUNDED` |
| `report_target_type` | `PROFILE, MESSAGE, POST` |
| `report_status` | `PENDING, REVIEWED, DISMISSED, ACTION_TAKEN` |
| `support_ticket_status` | `OPEN, CLOSED` |

---

## 21. Infrastructure existante

Ce qui est déjà résolu côté PWA et qu'un client natif devrait réutiliser plutôt que réinventer.

- **Push** — Web Push (VAPID) déjà branché sur la même table `notifications` que le reste de la plateforme ; un futur client natif brancherait FCM/APNs sur ce même déclencheur plutôt que de redériver sa propre logique de notification.
- **Buckets de stockage** — `avatars`/`post-media` publics, `message-attachments`/`support-attachments`/`verification-selfies` privés (URLs signées).
- **Fonctions appelables (RPC)** — `record_profile_view`, `record_post_view`, `get_unread_message_count`, `create_conversation_with_participant` (seul chemin valide pour démarrer une conversation — un insert direct échoue), `get_my_blocked_profiles`.
- **Application déjà installable** (PWA) avec intention affichée de publication Android via TWA — le manifeste référence déjà un identifiant de package Play Store.

---

## 22. Hors périmètre & notes pour le développeur mobile

- **Espace admin** — reste un outil web pour l'équipe, aucune raison de le porter sur mobile.
- **Multi-langue** — aucune infrastructure existante ; à construire de zéro si demandé, pas à "porter".
- **Cohérence des règles de blocage** — chaque condition du §3 a été trouvée dans le code réel, pas déduite : à reproduire à l'identique, y compris les asymétries qui semblent contre-intuitives au premier abord (ex. liker est gratuit mais mettre en favori ne l'est pas ; l'invitation tolère 3 essais gratuits par mois mais répondre dans le fil accepté n'en tolère aucun).
- **Fiabilité des paiements** — les deux prestataires ont déjà eu des incidents réels de webhooks manquants ; toute intégration mobile du paiement devrait prévoir la même logique de réconciliation active plutôt que de faire confiance à un seul callback.
- **Pages légales** — CGV/CGU, mentions légales, politique de confidentialité, normes de sécurité des enfants (pertinent pour les stores d'applications de rencontre) existent déjà en contenu web à réutiliser tel quel.

---

*Document constitué à partir d'une revue directe du code source de production le 13 septembre 2026. Toute divergence constatée entre ce document et le comportement réel de l'application doit être tranchée en faveur du code — ce PRD documente l'existant, il ne le remplace pas.*
