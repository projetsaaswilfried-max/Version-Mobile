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

---

## EN ATTENTE (réponse du porteur produit)

### Q1 — Découvrir : vérifié, complet, ou les deux ?
*réf. PRD §3, §6, §7 — contradiction interne*

Le PRD se contredit : §3 dit `VERIFIED`, §6 dit « la complétude, PAS la
vérification », §7 dit les deux. Bloquant pour l'écran Découvrir. À trancher
contre le code (le PRD dit lui-même « en cas de divergence, le code tranche »).
Tant que non tranché, le PRD n'est pas corrigé (voir V1).

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
