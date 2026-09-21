# Design : onboarding métier API + bandeau S02 (issue #8)

Date : 2026-09-17  
Issue : [#8](https://github.com/BespokApps/agapeo-mobile/issues/8)  
Stack : PR empilée sur `feat/onboarding-ui-redesign`  
Réfs : PRD §5-§6, addendum §1.3, screens-prd S02, gate #6 / shell #7

## Contexte

Après le redesign UI local (D5 : **3 steps**), le flow reste hors ligne. #8 exige la
persistance Supabase (profil + photo Storage), le basculement
`onboarding_completed`, et le bandeau S02 dans le shell tant que le profil
est incomplet. `onboarding_completed` ≠ `VERIFIED` (PRD §2 / §5).

**Delta D5 vs texte issue #8** : pas de selfie live ni grille multi-photos dans
cet onboarding ; la vérif anti-usurpation reste hors flow (Mon compte). Le
critère d’acceptation « selfie live » de #8 est reporté hors cette PR.

## Décisions produit

| Sujet | Choix |
|---|---|
| Périmètre | #8 mobile aligné D5 (API + Storage photo profil + S02) |
| Terminer (avec photo) | Upload photo profil + update `profiles` ; `onboarding_completed = true` ; **pas** de `verification_requests` ni `VERIFIED` auto |
| Passer (sans photo) | Update `profiles` (essentials + foi) ; `onboarding_completed = true` ; pas de photo / pas de vérif |
| Revenir plus tard | Inchangé (#6) : aucune écriture `onboarding_completed` |
| Verrouillage essentials | Genre / DOB / pays : une fois écrits en DB, non modifiables côté app |
| S02 | Visible dans le shell si profil « incomplet » (PRD §6), indépendamment de `VERIFIED` |
| Profil complet | Calculé : photo principale + confession + pourquoi mariage + genre + DOB + pays |

## Périmètre

### Inclus

- Domain + data onboarding / profile : usecases + repository Supabase + Storage
- Brancher `OnboardingFlowController` : Soumettre / Terminer sans soumettre → réseau
- Verrouillage UI essentials si déjà présents côté serveur (reprise)
- Bandeau S02 dans `HomeShell` : texte + CTA « Compléter » → `OnboardingFlowPage`
- Liste courte des manques (optionnel si simple : au moins copy + CTA)
- Tests domain / data / widget S02
- Closes #8

### Hors scope

- Redesign UI (PR1)
- Apparition Découvrir / modération admin
- Premium 10 photos
- Resoumission post-rejet (parcours Mon compte)
- Sync Dio / `SecureTokenStore`

## Architecture

Flèches vers l’intérieur. On étend `onboarding/` (métier flow) et on lit la
complétude depuis `profile/` (déjà la feature gate) pour S02.

```
lib/features/onboarding/
  domain/
    entities/          # payload submit / chemins locaux
    repositories/      # OnboardingRepository (abstract)
    usecases/
      submit_onboarding.dart
      finish_without_verification.dart
  data/
    datasources/       # Supabase profiles + Storage + verification_requests
    repositories/      # impl
  presentation/profile_onboarding/  # controller branché usecases
  di/

lib/features/profile/
  domain/
    usecases/profile_completeness.dart   # pur sur snapshot champs
    repositories/                        # étendre ou ProfileRepository lecture champs
  presentation/                          # providers complétude pour le shell

lib/features/home/presentation/
  widgets/incomplete_profile_banner.dart # S02
  home_shell_page.dart                   # intègre le bandeau
```

### Use cases

**`SubmitOnboarding(draft)`** (CTA **Terminer** avec `profilePhotoPath`)
1. Upload photo locale → Storage ; row `profile_photos` (`is_primary`, modération `DRAFT`/`PENDING` selon conventions web)
2. Update `profiles` (essentials, foi, marital, why marriage, …)
3. `profiles.onboarding_completed = true`
4. Ne jamais créer `verification_requests` ici ; ne jamais forcer `VERIFIED`

**`FinishWithoutVerification(draft)`** (CTA **Passer** confirmé)
1. Update `profiles` avec essentials + foi (photo absente)
2. `onboarding_completed = true`
3. Navigation → HomeShell (bandeau S02 attendu)

**`ProfileCompleteness`**
- Entrée : champs profil lus (genre, DOB, pays, photo principale, confession, why marriage)
- Sortie : `isComplete` + liste des clés manquantes (pour S02)
- Pur Dart, testable sans Flutter

### Data

- SDK `supabase_flutter` (même projet que l’auth)
- Storage buckets alignés web (chemins `auth.uid()` / conventions existantes)
- Mapping erreurs → `Failure` (`NetworkFailure`, `ServerFailure`, `ValidationFailure`, …)
- Sans Supabase configuré : `Err` clair, pas de crash ; UI snackbar

### Presentation

- Controller : états `isSubmitting` / `submitError` ; succès → `pushAndRemoveUntil(HomeShell)`
- Snackbars locales « hors ligne » remplacées par succès / erreur réseau
- S02 : `ref.watch(profileCompletenessProvider)` ; si incomplet, bandeau global dans le shell (au-dessus de l’`IndexedStack`, visible sur tous les onglets)
- CTA « Compléter » → push `OnboardingFlowPage`

## UI S02

- Bandeau tokens (`colors` surface / border / primary)
- Titre court type « Profil incomplet » + CTA « Compléter »
- Sous-texte : jusqu’à 4 libellés issus de `missingKeys` (ex. Photos, Confession)
- Masqué dès `isComplete == true`

## Erreurs

| Cas | Comportement |
|---|---|
| Upload / update `Err` | Snackbar ; rester sur O05 ; draft conservé |
| Essentials déjà verrouillés serveur | Steps O01 en lecture seule si champs non null en DB |
| Gate Err (complétude) | Pas de bandeau plutôt que crash ; log soft |

## Tests

### Automatisés

- `SubmitOnboarding` / `FinishWithoutVerification` : ordres d’appels repo (fakes)
- `ProfileCompleteness` : chaque champ manquant ; cas complet
- Mapping Storage/DB → `Failure`
- Notifier : loading / succès / erreur
- Widget : bandeau visible si incomplet ; absent si complet ; tap → onboarding

### Manuel

- [ ] Soumettre → Storage + rows + `onboarding_completed` ; pas de VERIFIED auto
- [ ] Terminer sans soumettre → home ; bandeau S02 si incomplet
- [ ] Membre incomplet sur shell : bandeau ; complet : pas de bandeau
- [ ] Relogin après Revenir plus tard : onboarding à nouveau (`onboarding_completed` false)
- [ ] `flutter analyze` + `flutter test` verts

## Acceptation (#8, delta D5)

- [ ] 3 étapes, progression, retour arrière (déjà UI ; branché API en fin)
- [ ] Genre / naissance / pays non modifiables une fois validés en DB
- [ ] Photo profil : caméra ou galerie (selfie live hors scope → Mon compte)
- [ ] Bandeau S02 tant que profil incomplet
- [ ] `onboarding_completed` jamais confondu avec `VERIFIED`
- [ ] Analyze + tests verts

## Stack Git

1. Branche : `feat/onboarding-api` depuis `feat/onboarding-ui-redesign`
2. PR vers la branche redesign (ou `main` après merge PR1)
3. Body : `Stacked on <PR1>` · `Closes #8`
4. Après merge redesign : retarget / rebase sur `main` si besoin

## Suite

1. Plan PR1 redesign → implémentation
2. Plan PR2 API → implémentation
3. Puis contenus Fil / Découvrir (#9+)
