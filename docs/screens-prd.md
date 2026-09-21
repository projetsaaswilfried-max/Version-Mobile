# Agapeo Mobile — Inventaire des écrans

**Version 1.1 — 14 septembre 2026**

Catalogue des écrans à construire côté iOS (Flutter), à parité avec l’app membre
web existante.

> **Comment lire ce document.** Ce n’est **pas** une réécriture du comportement :
> la source de vérité reste [`Agapeo-Mobile-PRD.md`](./Agapeo-Mobile-PRD.md).
> Ici : **quels écrans existent**, leur rôle, et le lien vers la section
> comportementale. Le delta mobile (OTP, deep links, push, stores) vit dans
> [`mobile-addendum.md`](./mobile-addendum.md).

**Méthode.** Inventaire croisé :
- tour public + session connectée sur [agapeo.love](https://www.agapeo.love/)
  (14/09/2026, lecture seule) ;
- PRD comportemental §§4–15, 22 ;
- addendum mobile.

**Hors périmètre.** Landing marketing (`/`), espace admin (`/admin`),
multi-langue.

---

## Sommaire

1. [Shell & navigation](#1-shell--navigation)
2. [Lancement & authentification](#2-lancement--authentification)
3. [Onboarding & gates](#3-onboarding--gates)
4. [Fil d’actualité](#4-fil-dactualité)
5. [Découvrir](#5-découvrir)
6. [Messagerie & Match](#6-messagerie--match)
7. [Notifications](#7-notifications)
8. [Mon compte](#8-mon-compte)
9. [Premium & paiements](#9-premium--paiements)
10. [Support, signalement, légal](#10-support-signalement-légal)
11. [Spécifique mobile](#11-spécifique-mobile)
12. [Hors périmètre](#12-hors-périmètre)
13. [État du repo](#13-état-du-repo)

Légende **Statut** :
| Tag | Signification |
|---|---|
| **Vu** | Observé en prod (public ou connecté) |
| **PRD** | Décrit dans le PRD, non ouvert en session (évite action réelle) |
| **Mobile** | N’existe pas tel quel sur le web ; à construire pour iOS |

---

## 1. Shell & navigation

Sur le web connecté, la barre basse a **4** destinations (Fil, Découvrir,
Messages, Notifications) ; Profil et Premium sont en menu / header.

**Cible iOS : 4 onglets** — Fil, Découvrir, Messages, Profil. Le PRD ne
spécifie aucune bottom nav (le web est une PWA). La proposition initiale
(5 onglets, Notifications inclus) était une inférence ; elle est tranchée
en **D4** (`docs/decisions.md`).

**Notifications** n’est pas un onglet : icône + badge dans le header de
l’accueil, qui ouvre N01 (écran de consultation, pas une destination
fréquente). **Premium** reste hors barre (page dédiée + popups, PRD §11).

| # | Écran | Route web | Statut | Comportement |
|---|---|---|---|---|
| S01 | Shell (bottom nav, 4 tabs) | — | Vu | Fil · Découvrir · Messages · Profil |
| S02 | Bandeau « Profil incomplet » | — | Retiré | Plus de bandeau sticky global (D9). Rappel contextuel dans Découvrir. |
| S03 | Menu latéral / avatar | — | Vu | Accueil, Découvrir, Messages, Premium, Mon Profil (web) |
| S04 | Header accueil (cloche + badge) | — | Mobile | Accès à N01 ; pas un 5ᵉ onglet |

Réf. comportement : PRD §§7, 8, 10, 12, 14 · décision D4.

---

## 2. Lancement & authentification

| # | Écran | Route web | Statut | Notes |
|---|---|---|---|---|
| A01 | Splash | — | Vu (app) | Déjà dans le repo Flutter |
| A02 | Bienvenue | `/bienvenue` | Vu | `start_url` PWA ; CTA → login |
| A03 | Connexion | `/login` | Vu | Email, mot de passe, Google, lien mdp oublié, CGU / confidentialité |
| A04 | Inscription | `/register` | Vu | Prénom, nom optionnel, email, MDP×2, case CGU **+ charte**, Google |
| A05 | Confirmation OTP | — | Mobile | Décision D1 — code 6 chiffres in-app |
| A06 | Vérifie tes mails (fallback) | — | Mobile | Si le porteur impose le lien plutôt que l’OTP |
| A07 | Mot de passe oublié | `/forgot-password` | Vu | Email + « Envoyer le lien » |
| A08 | Nouveau mot de passe | `/reset-password` | Vu | Deep link iOS obligatoire (addendum §1.2) |
| A09 | Barrière d’âge 18+ | — | Mobile | Exigence stores (addendum §5) |

Réf. : PRD §4 · addendum §1 · decisions D1.

---

## 3. Onboarding & gates

Assistant en **5 étapes** (vu connecté). Chaque étape obligatoire pour
continuer ; « Revenir plus tard » possible. Genre / date de naissance / pays
**verrouillés** après validation.

| # | Écran | Route web | Statut | Contenu |
|---|---|---|---|---|
| O01 | Onboarding — Informations | `/onboarding` étape 1 | Vu | Genre, date de naissance, pays |
| O02 | Onboarding — Photos | étape 2 | Vu (nav) | Min. 1 ; 2 gratuit / 10 Premium |
| O03 | Onboarding — Selfie | étape 3 | Vu (nav) | Caméra live uniquement, pas d’import |
| O04 | Onboarding — Ma foi | étape 4 | Vu (nav) | Confession, situation matrimoniale, taille… |
| O05 | Onboarding — Ce que je recherche | étape 5 | Vu (nav) | Préférences + soumission ; « Terminer sans soumettre » (PRD) |
| O06 | Compte suspendu | `/suspended` | PRD | Gate post-login (addendum §1.3) |

Réf. : PRD §5 · addendum §1.3.

---

## 4. Fil d’actualité

Accueil connecté = `/feed` (pas la landing marketing).

| # | Écran | Route web | Statut | Contenu |
|---|---|---|---|---|
| F01 | Fil principal | `/feed` | Vu | Filtres catégories ; cartes posts officiels |
| F02 | Détail d’un post | — | PRD | Image, galerie, vidéo, YouTube, citation |
| F03 | Commentaires | — | PRD | Un seul niveau de réponses |
| F04 | Créer / éditer un post personnel | depuis compte | Vu (CTA) | Un média, ≤600 car. ; **pas** dans le fil principal |
| F05 | Feuille de partage | — | PRD | WhatsApp / etc. / copie de lien |

Catégories vues : Tout le fil · Enseignements · Témoignages · Atelier/Mariage ·
Conseils & Préparation · Pensées & Citations (+ overflow).

Engagement carte (vu) : Options · Voir plus · like · commentaires · partages ·
Enregistrer.

Réf. : PRD §10. Popup Premium d’accueil : une fois / session (PRD §11).

---

## 5. Découvrir

| # | Écran | Route web | Statut | Contenu |
|---|---|---|---|---|
| D01 | Liste Découvrir | `/discover` | Vu | « Recommandée pour vous » (3/jour) + « Autres profils » (×12) — PRD |
| D02 | Recherche / filtres | — | Vu (verrouillé) | Champ « Passe Premium pour rechercher » + bouton Filtres |
| D03 | Fiche profil (autre membre) | modale / URL | PRD | Non ouverte en session (évite `record_profile_view`) |
| D04 | Paywall « Passe Premium » | popup | Vu | À **chaque** chargement Découvrir |
| D05 | Modale « Valide ton profil » | — | PRD | Like / invitation si non `VERIFIED` |
| D06 | Modale d’invitation | — | PRD | Jamais un chat direct |

Réf. : PRD §§3, 7. CTA vu : « Vérifier mon profil ».

---

## 6. Messagerie & Match

| # | Écran | Route web | Statut | Contenu |
|---|---|---|---|---|
| M01 | Liste des discussions | `/messages` | Vu | Recherche ; empty states (0 conversation sur le compte test) |
| M02 | Fil de conversation | — | PRD | Texte, image, vidéo, doc, vocal |
| M03 | Invitation reçue | — | PRD | Accepter / refuser (`PENDING`) |
| M04 | Fil système Agapeo | — | PRD | Lecture seule, pas de saisie |
| M05 | Visionneuse média | — | PRD | |
| M06 | Match (proposer / répondre / annuler) | — | PRD | Au-dessus d’une conversation `ACCEPTED` |
| M07 | Confirmer masquer la discussion | — | PRD | Masquage perso, pas delete |

Empty states vus :
- « Aucune conversation » → démarrer depuis Découvrir ;
- « Pas encore de messages » → compléter le profil pour être visible.

Réf. : PRD §§8–9.

---

## 7. Notifications

Écran de consultation, ouvert depuis **S04** (header), pas depuis la bottom
nav.

| # | Écran | Route web | Statut | Contenu |
|---|---|---|---|---|
| N01 | Centre de notifications | `/notifications` | Vu | Retour · Tout marquer comme lu · filtres catégories |

Filtres vus : Toutes · Non lues · Messages · Profil · Publications ·
Recommandations · Plateforme.

Empty vu : « Aucune notification dans cette catégorie ».

Réf. : PRD §12 · addendum §4 (push natif APNs).

---

## 8. Mon compte

Route : `/profile`. Sur le web = 8 onglets ; **sur iOS = 8 pages** (ou
équivalent) sous un hub « Espace Personnel & Réglages ».

### 8.1 Hub

| # | Écran | Statut | Notes |
|---|---|---|---|
| C00 | Hub Mon compte | Vu | « Voir mon profil public » · crayon / « Modifier » → C01 enrichi (D26) ; bannière complétion → onboarding si essentiels manquants, sinon C01 |

### 8.2 Les 8 sections

| # | Écran | Statut | Contenu vu / PRD |
|---|---|---|---|
| C01 | Mon Profil | Vu | Photos 0/2 (gratuit), Ajouter · Genre/Âge/Pays lecture seule · identité · bio ≤600 · switch déménagement · confession / situation / pourquoi mariage · lien Ma Foi · Enregistrer (D26) |
| C02 | Ma Foi | Vu | Dénomination · années conversion · ministère · verset · témoignage · « Ce que Dieu fait » |
| C03 | Plus d’infos | Vu | Qualités /10 · passions /12 · famille · enfants · délai mariage · valeurs /12 — *hors matching* |
| C04 | Mes Publications | Vu | Empty + « Créer une publication » |
| C05 | Mes Favoris | Vu | Recherche · liste (0) — Premium pour ajouter |
| C06 | Qui s’intéresse à moi | Vu | Liste ; identités Premium (PRD §3) |
| C07 | Confidentialité | Vu | Switches confidentialité + préférences notifs + push appareil |
| C08 | Compte & Sécurité | Vu | Voir sous-écrans ci-dessous |

### 8.3 Sous-écrans Compte & Sécurité

| # | Écran | Statut | Contenu |
|---|---|---|---|
| C09 | Statut / soumission vérification | Vu | CTA « Soumettre pour vérification » |
| C10 | Changer l’email | Vu (CTA) | Confirmation par email |
| C11 | Changer le mot de passe | Vu (CTA) | |
| C12 | Export des données | Vu (CTA) | JSON téléchargé, jamais emailé |
| C13 | Comptes bloqués | PRD | Seul moyen de débloquer |
| C14 | Se déconnecter | Vu (CTA) | |
| C15 | Supprimer mon compte | Vu (CTA) | Irréversible, confirmation obligatoire |
| C16 | Gestion photos (+ selfie si déjà VERIFIED) | Vu / PRD | Nouveau lot après vérif → selfie live |

Réf. : PRD §§6, 14–15.

---

## 9. Premium & paiements

| # | Écran | Route web | Statut | Contenu |
|---|---|---|---|---|
| P01 | Mon Plan | `/premium` | Vu | Gratuit vs 7j / 15j / 30j / 90j (recommandé) |
| P02 | Popup relance Premium | — | Vu | Accueil 1×/session ; Découvrir à chaque load |
| P03 | Choix du moyen de paiement | — | PRD | Mobile Money vs carte |
| P04 | Attente SasPay (USSD / OTP) | — | PRD | Initiation encore **Q2** (`decisions.md`) |
| P05 | WebView Chariow | — | PRD / Mobile | Carte bancaire |
| P06 | Succès / échec / réconciliation | — | PRD | Observer `subscription_status` → `ACTIVE` |
| P07 | Mur abonnement `EXPIRED` | — | PRD | Page entière sur Découvrir / Messages / Support |

Tarifs vus (FCFA) : 2 335 / 4 086 / 7 003 / 17 507 (trimestriel « au lieu de
20 997 », ≈ 5 832/mois).

Réf. : PRD §11 · addendum §3.

---

## 10. Support, signalement, légal

| # | Écran | Route web | Statut | Contenu |
|---|---|---|---|---|
| L01 | Support — liste / empty | `/support` | Vu | Un seul dossier `OPEN` à la fois |
| L02 | Ouvrir un dossier | — | Vu | Objet + Message (+ image PRD) |
| L03 | Fil du dossier | — | PRD | |
| L04 | Signaler | — | PRD | Profil / message / post — motifs fixes |
| L05 | Confirmer un blocage | — | PRD | Immédiat, symétrique |
| L06 | CGU / CGV | `/cgv` | Vu | Public |
| L07 | Politique de confidentialité | `/politique-de-confidentialite` | Vu | Public |
| L08 | Mentions légales | `/mentions-legales` | Vu | Public |
| L09 | Charte d’éthique | `/charter` | Vu | 5 principes ; case à l’inscription |
| L10 | Normes sécurité enfants | — | PRD | Exigence stores ; URL non trouvée dans la nav membre |

Réf. : PRD §§13, 15, 22 · addendum §5.

---

## 11. Spécifique mobile

Pas de page web équivalente — à prévoir dès le début :

| # | Écran / flux | Réf. |
|---|---|---|
| X01 | Saisie OTP confirmation email | decisions D1 · addendum §1.1 |
| X02 | Retour deep link Google OAuth | addendum §1.2 |
| X03 | Retour deep link reset password | addendum §1.2 |
| X04 | Permission + enregistrement token APNs | addendum §4 |
| X05 | Capture selfie caméra live (permission caméra) | PRD §5–6 |
| X06 | Age gate 18+ | addendum §5 |
| X07 | Routage post-login (suspendu → expired → onboarding → shell) | addendum §1.3 |

---

## 12. Hors périmètre

| Surface | Pourquoi |
|---|---|
| Landing `/` + ancres marketing | Vitrine web, pas l’app membre |
| FAQ / témoignages / « Comment ça marche » vitrine | Contenu marketing |
| `/admin` et tout l’espace équipe | Reste web (PRD §16, §22) |
| Multi-langue | Aucune i18n existante |
| Offline complet | Non requis (addendum §6) |

---

## 13. État du repo

| Écran | Dans le code Flutter |
|---|---|
| A01 Splash | Oui (`features/onboarding/presentation/splash/`) |
| Tout le reste | Non |

---

## Annexe A — Compte de référence (tour 14/09/2026)

Session de cartographie (lecture seule) : profil **incomplet**, non vérifié,
plan **Gratuit**, **0** conversation, **0** notification, **0** publication,
**0** favori. Conséquence : fiches profil, chat, match, checkout n’ont pas été
ouverts — s’appuyer sur le PRD pour ces flux.

---

## Annexe B — Ordre de build suggéré

1. Shell 4 tabs + header cloche (S01, S04) + routage post-login (X07)
2. Auth (A02–A08) + OTP (A05)
3. Onboarding (O01–O05)
4. Fil (F01–F05)
5. Découvrir + paywalls (D01–D06)
6. Messages (M01–M07) au fur et à mesure des données
7. Notifications (N01) + push (X04)
8. Mon compte (C00–C16)
9. Premium (P01–P07)
10. Support / signalement / légal (L01–L10)

---

*Document constitué à partir du PRD comportemental, de l’addendum mobile, et
d’une inspection lecture seule de la production le 14 septembre 2026. En cas de
divergence de **comportement**, le code / le PRD principal tranche. En cas de
divergence de **découpage d’écrans**, ce document peut être mis à jour sans
réécrire le PRD.*
