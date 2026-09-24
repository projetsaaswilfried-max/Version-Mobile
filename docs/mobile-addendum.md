# Agapeo Mobile — Addendum de construction

**Complément au [PRD](./PRD.md), pas un remplacement.**

Le PRD décrit **le comportement** de l'application — partagé entre le web et le
mobile, parce que les deux clients tapent la même base Supabase avec les mêmes
règles RLS. Ce document décrit **ce que le mobile doit construire en plus**, que
le PRD ne couvre pas parce que ça n'a pas de sens côté web : navigation native,
intégrations de plateforme, exigences des stores.

Règle : si une information concerne le comportement (qui peut faire quoi, quelle
règle s'applique), elle vit dans le PRD et on la référence ici. Si elle concerne
la réalisation mobile, elle vit ici. On ne recopie jamais le comportement — sinon
les deux documents divergent.

Les points non tranchés sont dans [decisions.md](./decisions.md) avec leur statut.

---

## 1. Authentification & routage

### 1.1 Confirmation d'inscription — OTP (décidée, voir decisions.md)

La confirmation d'email requise (`mailer_autoconfirm: false` sur le projet) crée
un piège sur mobile : le lien s'ouvre dans un navigateur, souvent sur un autre
appareil, et la session n'atterrit jamais dans l'app.

**Cible : code OTP à 6 chiffres.** Le membre saisit `{{ .Token }}` dans l'app,
`verifyOtp` établit la session directement in-app — pas de navigateur, pas de
deep link, robuste au cross-device. Cohérent avec l'usage OTP déjà connu des
utilisateurs (Mobile Money).

**Longueur du code — réglage à vérifier après tout changement Dashboard.**
Supabase génère `{{ .Token }}` selon *Authentication → Emails → Email OTP
Length* (défaut Supabase : 8 chiffres). Le produit est fixé à **6** — voir
decisions.md D1 : le réglage Dashboard doit être à 6, et
`AuthValidators.otpLength` côté mobile doit toujours matcher.

**Contrainte projet-wide :** le template d'email de confirmation est unique pour
tout le projet Supabase (web + mobile). Pour ne pas casser le web (qui utilise le
lien), le template doit contenir **les deux** : `{{ .ConfirmationURL }}` (lien,
web) et `{{ .Token }}` (code, mobile).

**Si la connexion échoue en `email_not_confirmed`** (le membre a quitté l'app
avant de confirmer, ou le code d'origine a expiré) : pas d'écran séparé ni de
bouton à cliquer — l'app renvoie l'email (`resend`) elle-même et redirige
directement vers l'écran OTP. Le code d'origine est de toute façon périmé à
ce stade, donc aucune raison de faire rejouer `signInWithPassword` en
premier ; l'écran OTP a son propre « Renvoyer le code » (débouncé 60 s,
rate-limit Supabase) si ce renvoi automatique échoue.

### 1.2 Deep links — nécessaires malgré l'OTP

L'OTP évite le deep link pour la confirmation d'inscription seulement. Il reste
**obligatoire** pour :
- **Google OAuth** — le retour dans l'app après consentement Google passe par un
  redirect ; sans deep link, l'app ne récupère pas la session.
- **Réinitialisation du mot de passe** — même mécanique.

À configurer : App Links (Android) + Universal Links (iOS), et déclarer les URL
de redirection côté Supabase (Auth → URL Configuration). Le manifeste PWA
référence déjà un identifiant de package Play Store (§21) — le réutiliser.

### 1.3 Routage post-connexion — à la charge du mobile

Le PRD §4 est explicite : la logique de redirection post-connexion vit dans un
`proxy.ts` propre au web. **Le mobile doit la refaire.** Juste après une
connexion réussie, lire et router dans cet ordre :

1. `profile_restricted.is_suspended` → écran de suspension (session invalidée
   côté Auth de toute façon).
2. `profile_restricted.subscription_status` → `EXPIRED` verrouille davantage que
   `FREE` (voir matrice §3 du PRD).
3. `profiles.onboarding_completed` → si faux, (ré)afficher l'assistant
   d'onboarding. Attention (§2, §5) : `onboarding_completed` **n'implique ni
   profil complet ni vérifié** — ne jamais en déduire l'un des deux.

---

## 2. Messagerie temps réel

Le modèle (invitation, statuts, types de message, accusés de lecture) est décrit
au PRD §8. Ici : comment le mobile réalise le temps réel.

### 2.1 Les trois canaux → mécanismes Supabase

| Canal (PRD §8) | Mécanisme | Notes |
|---|---|---|
| Messages de la conversation ouverte | Postgres Changes sur `messages`, filtré `conversation_id` | INSERT = nouveau message ; UPDATE `read_at` = accusé ; UPDATE `deleted_at` = suppression douce |
| Liste globale + badges non-lus | Postgres Changes sur `messages` / `conversation_participants.last_read_at` | Doit rester frais sur les fils non ouverts |
| « En train d'écrire… » (expire 3 s) | Broadcast (éphémère, non persisté) | Jamais écrit en base |

`supabase_flutter` gère les trois — aucun travail serveur neuf pour le temps réel.

Démarrer une conversation : RPC `create_conversation_with_participant` (§21). Un
insert direct dans `conversations` échoue.

### 2.2 Cycle de vie de la connexion — spécifique mobile

Une app mobile est suspendue en arrière-plan, le websocket tombe. Deux
conséquences absentes du PRD (web-centré) :

- **Reconnexion + rattrapage au premier plan.** Ne pas se fier au seul flux
  realtime pendant la suspension : au retour, requêter les messages depuis
  `conversation_participants.last_read_at` pour combler le trou.
- **Push en arrière-plan.** Realtime ne délivre rien quand l'app est fermée. Un
  nouveau message app fermée = **push** (voir §4 de cet addendum), déclenché par
  l'insertion dans `notifications`. Messagerie mobile = realtime au premier plan
  **+** push en arrière-plan. Deux systèmes, les deux nécessaires.

---

## 3. Paiement Premium

Comportement, formules, prestataires : PRD §11. Ici : réalisation mobile.

### 3.1 Ce qui est déjà mutualisé

`subscription_status` vit dans `profile_restricted`, **écrit uniquement côté
serveur** (§18). Un client ne peut pas se rendre Premium. Toute la branche
confirmation — webhook Chariow signé, réconciliation SasPay à la minute, bascule
du statut, cron d'expiration quotidien — est serveur et sert les deux clients
sans rien recoder. **Le mobile n'a qu'à observer `subscription_status` passer à
`ACTIVE`** après paiement.

### 3.2 Initiation du paiement : renvoi vers le checkout web (D — voir Q2)

Décidé (`decisions.md` Q2, suite 2026-09-23) : le mobile n'intègre **pas**
SasPay/Chariow directement — il renvoie vers le checkout web existant, déjà
fonctionnel pour les deux prestataires. Ça règle par construction les points
auparavant ouverts (clé SasPay, SDK vs API, réconciliation `transactions`) :
rien de tout ça ne touche le mobile.

Livré et câblé (`decisions.md` Q2, suite 2026-09-24) : fonction Supabase
`mobile-payment-handoff` (lien magique `type=magiclink` via Supabase Auth,
pas de table de jetons maison), consommée par `lib/features/premium/`
(`PremiumCheckoutRepository` → `SupabasePremiumCheckoutDataSource` →
`functions.invoke`). `PremiumPlanPage` ouvre l'URL reçue dans un navigateur
externe (`url_launcher`, `LaunchMode.externalApplication`) et observe
`subscription_status` passer à `ACTIVE` (§3.1) — aucun deep link de retour
nécessaire.

---

## 4. Notifications push natives

Le push web (Web Push / VAPID) est déclenché par chaque insertion dans
`notifications` (§12, §21). **Ce n'est pas réutilisable tel quel** : l'émetteur
actuel pousse du Web Push. Le mobile a besoin d'un **émetteur FCM (Android) /
APNs (iOS)** branché sur le même déclencheur `notifications`.

À construire (probablement une Edge Function ou un trigger→fonction) :
- lire les insertions dans `notifications`,
- résoudre les tokens de l'appareil du destinataire (nouvelle table type
  `push_tokens` natifs, distincte de `push_subscriptions` qui est Web Push),
- pousser vers FCM/APNs.

Les préférences de notification agissent en amont, sur la création de la ligne
`notifications` (§12) — donc le mobile n'a pas de second système de préférences à
gérer, seulement l'enregistrement du token et la réception.

---

## 5. Exigences des stores (catégorie rencontre)

Apple et Google sont stricts sur les apps de rencontre. À prévoir dès le départ,
sous peine de rejet :

- **Barrière d'âge 18+** — déjà dans la logique (18 ans minimum à l'onboarding,
  §5), mais les stores exigent un age gate explicite et une classification de
  contenu adéquate.
- **Signalement & blocage accessibles** — déjà couverts (PRD §15), Apple l'exige
  explicitement pour l'UGC. Vérifier qu'ils sont atteignables en peu de gestes.
- **Modération & délai de traitement** — Apple demande un engagement de
  traitement des signalements sous 24 h et un moyen de bloquer les utilisateurs
  abusifs (existe côté admin, PRD §16).
- **Pages légales** — CGU, confidentialité, sécurité des enfants existent en web
  (§22), à rendre accessibles depuis l'app.
- **Paiement** — attention aux règles de facturation des stores. Le Mobile Money
  pour un service numérique peut tomber sous la politique d'achat intégré
  d'Apple/Google — à vérifier, c'est un motif de rejet fréquent.

---

## 6. Hors périmètre mobile

- **Espace admin** (`/admin`) — reste web (PRD §16, §22).
- **Capacités élevées** (rôles, suspension, Premium manuel, modération) — passent
  par le serveur avec la clé de service que le mobile n'a jamais (§18). À exposer
  via une API Agapeo dédiée si un jour nécessaire côté mobile, jamais en appelant
  Supabase avec les identifiants d'un membre.
- **Multi-langue** — aucune infrastructure i18n existante ; hors périmètre sauf
  demande explicite.
- **Offline** — non requis (app de dating connectée). Prévoir néanmoins des états
  de chargement / vide / erreur propres, pas un cache offline.
