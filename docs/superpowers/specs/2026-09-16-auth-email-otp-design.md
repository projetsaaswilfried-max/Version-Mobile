# Design : Auth email / OTP (issue #5, MR1)

**Date** : 2026-09-16  
**Issue** : [#5](https://github.com/BespokApps/agapeo-mobile/issues/5) `1/11 Auth`  
**Branche prévue** : `feat/auth-email-otp`  
**Statut** : validé en brainstorming ; MR2 (Google + Universal Links + A08) hors de ce document

## Contexte

Permettre à un membre d’entrer dans l’app (hors landing marketing) via email +
mot de passe, avec confirmation d’inscription par OTP in-app (décision D1).

État du repo au moment du design :
- Splash (A01) présent ; `supabase_flutter` initialisé dans `main.dart`
- Logos brand dans `AppAssets` (`logo_full`, `logo_full_white`)
- Package / nom déjà alignés site : `com.agapeo.agapeo`, app `agapeo`
- Pas encore de feature `auth/`
- `SecureTokenStore` réservé au client Dio ; session Auth = SDK Supabase

Réfs : PRD §4 · addendum §1.1 · `docs/screens-prd.md` §2 · `docs/decisions.md` D1

## Décisions produit (MR1)

| Sujet | Choix |
|---|---|
| Découpage #5 | MR1 = cœur email ; MR2 = Google + deep links + A08 |
| Age gate (A09) | Avant Bienvenue, une fois par install, flag local |
| Après session OK | Stub « Connecté » (email + déconnexion) ; pas de routage #6 |
| A06 fallback | Minimal : lien depuis A05 « Pas de code ? » |
| Google | Absent de l’UI en MR1 |
| Branding | Réutiliser assets / package / nom existants ; liens légaux vers `agapeo.love` |

## Approche technique

**Clean Architecture pragmatique** dans `lib/features/auth/` :
- `domain/` : `AuthRepository` abstrait + use cases ciblés (pas un use case par bouton fantôme)
- `data/` : `SupabaseAuthDataSource` + `AuthRepositoryImpl`
- `presentation/` : pages + Notifiers Riverpod (`Equatable` + `copyWith`)

Domain = Dart pur (zéro Flutter / Supabase). Presentation → domain ← data.

Use cases retenus :
- `SignInWithPassword`
- `SignUp`
- `VerifyEmailOtp`
- `ResendSignupEmail`
- `RequestPasswordReset`
- `SignOut` (stub)

## Architecture & navigation

```
auth/
  domain/
    entities/
    repositories/
    usecases/
  data/
    datasources/
    repositories/
  presentation/
    age_gate/          # A09
    welcome/           # A02
    login/             # A03
    registration/      # A04
    otp/               # A05
    verify_email/      # A06
    forgot_password/   # A07
    session_stub/      # temporaire jusqu’à #6 / #7
```

Splash (A01) reste sous `features/onboarding` et orchestre le premier hop :
1. Session Supabase déjà présente → stub Connecté
2. Sinon si age gate non accepté → A09
3. Sinon → A02 Bienvenue

Flux :
- A09 accepté → flag local → A02
- A02 → A03 ou A04
- A03 succès → stub ; mdp oublié → A07 ; lien inscription → A04
- A04 `signUp` (pas de session) → A05 (email + mdp en mémoire volatile du Notifier pour A06)
- A05 `verifyOtp` OK → stub ; « Pas de code ? » → A06
- A06 « J’ai confirmé » → `signInWithPassword` ; « Renvoyer » débouncé 60 s
- A07 envoi reset → message générique anti-énumération ; **pas d’A08 en MR1**

Navigation : `Navigator` push (pas de `go_router` pour l’instant).

## UI & formulaires

Design system uniquement : `AppButton`, `AppTextField`, tokens `core/theme`.
Pas de couleur / taille en dur.

| Écran | Contenu |
|---|---|
| A09 | Logo, texte 18+, CTA accepter ; refus = reste bloqué / message |
| A02 | Logo, accroche, CTA connexion, lien inscription |
| A03 | Email, MDP, CTA, mdp oublié, inscription, liens CGU + confidentialité |
| A04 | Prénom, nom optionnel, email, MDP×2, cases CGU **et** charte, CTA (pas Google) |
| A05 | 6 chiffres, valider, renvoi 60 s, lien vers A06 |
| A06 | Texte, « J’ai confirmé », « Renvoyer » 60 s |
| A07 | Email + envoyer + message succès générique |
| Stub | Email session + Déconnexion → Bienvenue |

Validation locale :
- MDP ≥ 8 caractères, ≥ 1 lettre, ≥ 1 chiffre (PRD §4)
- Email format basique
- Inscription : MDP identiques ; CGU + charte cochées
- OTP : exactement 6 digits

Liens légaux (WebView ou navigateur externe) vers les URLs prod :
- CGU / CGV : `https://www.agapeo.love/cgv`
- Confidentialité : `https://www.agapeo.love/politique-de-confidentialite`
- Charte : `https://www.agapeo.love/charter`

## Data flow & erreurs

- Session source de vérité : `Supabase.instance.client.auth`
- Pas d’écriture `SecureTokenStore` en MR1
- `signUp` metadata : prénom / nom pour le trigger `profiles`
- Mot de passe pour A06 : uniquement en mémoire du Notifier de flux, jamais persisté
- Mapping Auth exceptions → `Failure` (`ValidationFailure`, `UnauthorizedFailure`, `NetworkFailure`, `ServerFailure`, `UnknownFailure`) via `Result<T>`
- UI : `fieldErrors` + message formulaire FR ; `AppButton.isLoading` ; anti double-submit
- Age gate : booléen local (`shared_preferences` recommandé pour un simple flag)

Ops hors code (critère d’acceptation issue) : template email confirmation projet
Supabase = `{{ .ConfirmationURL }}` **et** `{{ .Token }}`.

## Tests

Automatisés :
- Unit validation MDP / email / OTP (domain)
- Mapping erreurs repository (fake datasource)
- Notifiers : loading / succès / erreur / debounce 60 s (fake repo)
- Widget smoke A02, A03, A04 (champs + CTA, pas de réseau)

Acceptation manuelle MR1 :
- [ ] Age gate une fois puis Bienvenue
- [ ] Login email + MDP → stub + déconnexion
- [ ] Inscription → OTP 6 chiffres → session
- [ ] A06 depuis A05 (confirm + renvoi 60 s)
- [ ] MDP oublié : message générique
- [ ] Liens légaux vers `agapeo.love`
- [ ] Pas de bouton Google
- [ ] `flutter analyze` + `flutter test` verts

## Hors scope (MR1)

- Routage post-login (#6)
- Shell 4 tabs (#7)
- Onboarding métier (#8)
- Google OAuth + retour deep link (MR2 / #5)
- Universal Links reset password + écran A08 (MR2 / #5)
- Sync session Supabase → `SecureTokenStore` / Dio

## MR2 (même issue #5, doc séparée plus tard)

- Bouton Google sur A03 / A04
- Deep links iOS (OAuth + reset)
- Écran A08 nouveau mot de passe
- Retrait progressif du stub quand #6 land
