# Design : routage post-login (X07 / #6) + « Revenir plus tard »

Date : 2026-09-17  
Issue : [#6](https://github.com/BespokApps/agapeo-mobile/issues/6)  
Réfs : PRD §4-5, addendum §1.3, inventaire O06 / X07, design onboarding UI local

## Contexte

L’auth (#5) aboutit aujourd’hui sur `SessionStubPage` (ou l’onboarding local après inscription hors Supabase). Le web route via `proxy.ts` ; le mobile doit refaire cet ordre (addendum §1.3).

L'assistant O01-O05 existe en UI locale. L'inventaire prévoit **« Revenir plus tard »** sur les étapes ; ce CTA manquait. Décision produit : ce lien **ne marque pas** `onboarding_completed` (comportement A). Destination immédiate : `SessionStub` (placeholder jusqu'au shell #7).

## Décisions produit (cette itération)

| Sujet | Choix |
|---|---|
| « Revenir plus tard » | Sortie sans écrire `onboarding_completed` ; atterrit sur SessionStub |
| Lecture gate | Réelle via Supabase (`profiles` + `profile_restricted`) |
| Home post-gate OK | SessionStub (shell = #7) |
| « Terminer sans soumettre » | Inchangé (local) ; écriture API = #8 |
| Redesign O01-O05 | Hors scope (dette flaggée #27) |

## Périmètre

### Inclus

- CTA **« Revenir plus tard »** sur O01-O05 → SessionStub, zéro écriture API
- Usecase `ResolvePostLoginRoute` : ordre  
  1. `profile_restricted.is_suspended` → O06  
  2. `subscription_status == EXPIRED` → mur EXPIRED minimal  
  3. `profiles.onboarding_completed == false` → `OnboardingFlowPage`  
  4. sinon → SessionStub
- Remplacer les navigations « session OK → SessionStub » (Splash si session, Login, OTP, deep link OAuth / reset réussi) par ce routeur
- UI minimale O06 + mur EXPIRED (copy + Déconnexion → Welcome)
- Tests domain (priorité des 4 branches) + smokes UI

### Hors scope

- Shell 4 onglets (#7)
- Onboarding métier API / `onboarding_completed = true` (#8)
- Redesign Material → Datify/Nestle (#27)
- Paywall Premium riche (P07)
- Sync session → Dio / `SecureTokenStore`

## Architecture

Feature légère **`profile`** (gate), flèches vers l’intérieur :

```
presentation ──► domain ◄── data
```

### Domain (Dart pur)

- `MemberGateSnapshot` : `isSuspended`, `subscriptionStatus`, `onboardingCompleted`
- `PostLoginDestination` (sealed / enum) : `suspended`, `expired`, `onboarding`, `homeStub`
- `ProfileGateRepository` (abstract) : `Future<Result<MemberGateSnapshot>> fetchGate()`
- `ResolvePostLoginRoute` : pure sur le snapshot (priorité ci-dessus)

Sans session auth : le caller ne doit pas invoquer le usecase pour une entrée « connectée » ; Splash sans session continue intro / welcome.

Sans Supabase configuré : `fetchGate` → `Err` ; navigation défensive (Welcome ou message), pas de crash.

### Data

- `SupabaseProfileGateDataSource` :
  - `profiles` : `onboarding_completed` pour `id = auth.uid()`
  - `profile_restricted` : `is_suspended`, `subscription_status` pour le même id
- Mapping `EXPIRED` strict (string / enum aligné PRD) ; `FREE` / `ACTIVE` / `CANCELED` → pas le mur EXPIRED
- `_Unconfigured` / erreurs réseau → `Result.Err` (jamais throw non catché vers l’UI)

### Presentation

- Helper `navigateAfterAuth(BuildContext, WidgetRef, {required String email})` :
  1. `ResolvePostLoginRoute`
  2. `pushAndRemoveUntil` vers la page cible (email passé au stub / onboarding context si besoin)
- Branchements : Splash (session), Login succès, OTP succès, `AuthDeepLinkListener` (OAuth session + password recovery OK → stub via routeur, recovery reste A08 puis stub via routeur)
- **« Revenir plus tard »** : **ne pas** rappeler le usecase (sinon reboucle onboarding) → SessionStub direct

## UI

### Revenir plus tard

- Lien secondary sous le CTA principal de `OnboardingFlowPage` (toutes étapes)
- Label : `Revenir plus tard`
- Pas de validation d’étape ; draft local inchangé

### O06 Compte suspendu

- Surface tokens, logo, titre « Compte suspendu », courte copy, `Déconnexion` → Welcome
- Aucun lien vers shell / onboarding / stub

### Mur EXPIRED

- Même squelette : titre du type « Abonnement expiré », copy, `Déconnexion`
- Pas de CTA paiement dans cette MR

### SessionStub

- Inchangé (Continuer l’onboarding + Déconnexion)
- Sert de home jusqu’à #7

## Erreurs

| Cas | Comportement |
|---|---|
| Gate `Err` après login | Snackbar message + SessionStub défensif **ou** rester sur l’écran auth avec message (préférer snackbar + stub si session déjà établie) |
| Suspendu | O06 uniquement |
| Double navigation OAuth | Inchangé (#26) : seul le deep link listener navigue ; il appelle `navigateAfterAuth` |

## Tests

### Automatisés

- `ResolvePostLoginRoute` : chaque branche + priorité (suspendu gagne si EXPIRED + onboarding false)
- Widget : présence « Revenir plus tard » ; tap → SessionStub (overrides)
- Smoke O06 / EXPIRED : titre + Déconnexion

### Manuel

- Compte `onboarding_completed = false` → onboarding après login
- « Revenir plus tard » → stub ; kill + relogin → onboarding à nouveau
- Compte suspendu / EXPIRED si disponibles en staging

## Acceptation (#6 + skip)

- [ ] Les 4 destinations sont atteignables (fakes ou comptes réels)
- [ ] Aucune session suspendue n’atteint SessionStub / shell
- [ ] Pas d’hypothèse `onboarding_completed => VERIFIED`
- [ ] « Revenir plus tard » n’écrit pas `onboarding_completed` et n’empêche pas le re-prompt au prochain login
- [ ] `flutter analyze` + `flutter test` verts

## Suite

1. Plan d’implémentation (`docs/superpowers/plans/`)
2. MR `feat/post-login-routing`
3. Puis #7 shell (remplace SessionStub comme destination `homeStub`)
