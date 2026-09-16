# Design : Auth Google + deep links + A08 (issue #5, MR2)

**Date** : 2026-09-16  
**Issue** : [#5](https://github.com/BespokApps/agapeo-mobile/issues/5) `1/11 Auth`  
**Branche prévue** : `feat/auth-google-deeplinks`  
**Statut** : validé en brainstorming

## Contexte

Compléter #5 après MR1 (email / OTP) : brancher Google OAuth pour de vrai,
configurer les deep links iOS/Android, et livrer l’écran A08 de nouveau mot
de passe.

État du repo au moment du design :
- Feature `auth/` Clean Arch pragmatique + stub session
- Bouton Google UI déjà présent (Welcome / Login / Register) avec snackbar stub
- A07 envoie déjà `resetPasswordForEmail` **sans** `redirectTo`
- Pas de `app_links` ; pas d’écran A08
- Projet Supabase : `cfmrykzqxcjhpktuxopu` (`docs/decisions.md`)

Réfs : PRD §4 · addendum §1.2 · `docs/screens-prd.md` A08 · décisions Q4

## Décisions produit (MR2)

| Sujet | Choix |
|---|---|
| Découpage | Une MR : Google + Universal/App Links + A08 |
| Plateformes | iOS + Android dès cette MR |
| Ops host / consoles | Hors app : checklist dans ce doc (URLs conventionnelles) |
| Après succès Google / A08 | Stub « Connecté » (#6 hors scope) |
| Approche OAuth | `supabase_flutter` `signInWithOAuth` + `app_links` (pas `google_sign_in` natif) |

## Approche technique

**`supabase_flutter` OAuth + `app_links`** :
- `signInWithOAuth(OAuthProvider.google, redirectTo: DeepLinkUrls.callback)`
- Listener URI (cold + warm) → `getSessionFromUrl` / recovery
- Reset : `resetPasswordForEmail(..., redirectTo: DeepLinkUrls.reset)` → A08 → `updateUser(password:)`

Domain = Dart pur. Presentation → domain ← data (même pattern MR1).

Use cases ajoutés :
- `SignInWithGoogle` → `Result<void>` (lance le navigateur OAuth ; session via deep link / `authStateChanges`)
- `UpdatePassword` → `Result<AuthSession>`
- `handleAuthDeepLink(Uri)` sur le repository → `oauthSession` | `passwordRecovery` | `ignored`

## Architecture & navigation

### URLs conventionnelles

| Rôle | URL |
|---|---|
| OAuth callback | `https://www.agapeo.love/auth/callback` |
| Reset password | `https://www.agapeo.love/auth/reset` |

Centralisées dans `lib/core/config/deep_link_urls.dart` (miroir de `LegalUrls`).

### Infra

- Package `app_links`
- iOS : Associated Domains `applinks:www.agapeo.love` (et `agapeo.love` si besoin)
- Android : intent-filter `autoVerify` sur les deux paths
- Listener démarré tôt (`main` / root) ; router :
  - `/auth/callback` → session → `SessionStubPage`
  - `/auth/reset` → recovery → `ResetPasswordPage` (A08)
  - autre → ignore
- Cold start reset : Splash court puis A08 (pas d’intro)
- Cold start OAuth : Splash → session → stub

### Auth layers

- `AuthRepository` : `signInWithGoogle`, `updatePassword`, `handleAuthDeepLink(Uri)` (ou équivalent data)
- `SupabaseAuthDataSource` : OAuth, `getSessionFromUrl`, `updateUser`, `resetPasswordForEmail` + `redirectTo`
- Retirer `showGoogleComingSoon` ; brancher Welcome / Login / Registration

### Flux

1. Google → navigateur / Custom Tab → callback → session → stub  
2. A07 → mail → `/auth/reset` → A08 → `updateUser` → stub  
3. Annulation OAuth → message soft, écran d’origine  

## UI

| Écran | Contenu |
|---|---|
| Welcome / Login / Register | `GoogleSignInButton` réel + loading |
| A08 | Titre, MDP ×2, CTA « Enregistrer » ; style Datify comme Login |
| Lien reset invalide | Message + CTA « Retour à la connexion » |

Validation MDP A08 = mêmes règles inscription (`AuthValidators.password`).

## Erreurs

- Mapping Auth → `Failure` inchangé (MR1)
- OAuth annulé / sans code → soft, pas de crash
- Reset expiré → `ValidationFailure` lisible

## Checklist ops (hors app)

À faire hors repo (ou repo web) avant acceptation manuelle complète :

1. **Supabase Auth → URL Configuration** : ajouter  
   `https://www.agapeo.love/auth/callback` et  
   `https://www.agapeo.love/auth/reset` (Redirect URLs).
2. **Google Cloud Console** : clients OAuth iOS + Android ; SHA-1 debug/release Android ; activer Google provider dans Supabase Auth.
3. **Host `agapeo.love`** :
   - `/.well-known/apple-app-site-association` (appID team + `com.agapeo.agapeo`, paths `/auth/*`)
   - `/.well-known/assetlinks.json` (package `com.agapeo.agapeo` + fingerprints)
4. Vérifier Associated Domains iOS + App Links Android une fois les fichiers host live.

Le code de l’app assume ces URLs même si l’ops n’est pas encore live (tests avec fakes / URI injectées).

## Tests

Automatisés :
- Domain : `UpdatePassword` (règles + mismatch) ; `SignInWithGoogle` délègue
- Router deep link : callback / reset / inconnu
- Controllers Google + A08 (loading / succès / erreur)
- Widget : A08 smoke ; Welcome/Login/Register sans snackbar « bientôt »

Manuel (ops branchés) :
- [ ] Google Welcome / Login / Register → stub
- [ ] Annulation OAuth soft
- [ ] Mail reset → A08 → stub
- [ ] Lien expiré → message + Login
- [ ] Cold start callback / reset
- [ ] `flutter analyze` + `flutter test` verts

## Hors scope

- Routage post-login (#6), shell (#7), onboarding métier (#8)
- Rebranchement age gate
- Sync session → `SecureTokenStore` / Dio
- `google_sign_in` SDK natif
