# Design : Intro onboarding 3 slides (style Nestle)

**Date** : 2026-09-16  
**Branche prévue** : `feat/intro-onboarding` (ou commit sur la branche auth en cours si on préfère enchaîner)  
**Statut** : validé en brainstorming

## Contexte

Remplacer la barrière d’âge 18+ (A09) en tête de flux par un **carousel d’intro marketing** inspiré Nestle (3 slides), puis l’écran Bienvenue existant.

L’age gate reste une exigence stores (addendum §5) : **hors flux pour cette itération**, à rebrancher plus tard **juste avant** Login / Créer un compte (une fois par install).

Hors scope : assistant profil O01–O05, Google, deep links, A08.

## Décisions validées

| Sujet | Choix |
|---|---|
| Type d’onboarding | A : carousel pré-auth (pas O01–O05) |
| Nombre de slides | 3 |
| Après les slides | Continuer → **Welcome** existant (option B) |
| Age gate 18+ | Retiré du splash ; reprise future **option 1** (avant auth) |
| Architecture | Approche 1 : `IntroStore` + flag `intro_seen` dédié |
| Layout UI | **A** : illustration haute + texte + dots + CTA |
| Passer | Lien « Passer » en haut → même effet que Continuer |

## Flux

```
Splash (durée mini 1,8 s)
  → session ? SessionStub
  → sinon introSeen ? Welcome
  → sinon IntroOnboardingPage (3 slides)
        → Continuer / Passer → mark intro_seen → Welcome
              → Login / Registration
```

Logout depuis le stub → Welcome (pas de rejeu de l’intro).

## Architecture

```
features/onboarding/
  domain/repositories/intro_store.dart      # isSeen / markSeen
  data/.../intro_local_datasource.dart
  data/.../intro_store_impl.dart
  presentation/intro/
    intro_onboarding_page.dart              # PageView + dots + CTA
    intro_slide.dart                        # modèle UI (titre, sous-titre, asset?)
  presentation/splash/splash_page.dart      # hop mis à jour
```

- Provider `introStoreProvider` + override dans `main.dart` (SharedPreferences), miroir de l’age gate.
- `AgeGatePage` / `AgeGateStore` : **conservés**, plus de navigation depuis Splash.
- Tokens uniquement (`AppButton`, `context.colors`, `context.typography`, `AppAssets`).

## UI (layout A)

Par slide :

1. Zone illustration (~55 % hauteur) : fond soft / dégradé brand, placeholder cœur ou asset dédié si disponible.
2. Titre + sous-titre centrés.
3. Indicateurs (3 dots).
4. CTA :
   - slides 1–2 : « Suivant » (page suivante)
   - slide 3 : « Continuer » → `markSeen` + `pushReplacement(WelcomePage)`
5. AppBar / coin : TextButton « Passer » → même navigation que Continuer.

### Copy

| # | Titre | Sous-titre |
|---|---|---|
| 1 | Rencontres sincères | Des profils qui cherchent le mariage, dans la foi. |
| 2 | La foi au centre | Confession, valeurs et projet de vie alignés. |
| 3 | Prêt à commencer | Crée ton compte ou connecte-toi en toute simplicité. |

## Persistance

- Clé SharedPreferences : `agapeo_intro_seen` (bool).
- Une fois `true`, Splash saute l’intro jusqu’à réinstall / clear data.

## Remise age gate (hors cette itération)

Quand on le remet :

1. Après Welcome, **avant** ouverture Login / Registration (ou au tap des CTA Welcome).
2. Une fois par install (`AgeGateStore` existant).
3. Refus : pas d’accès auth (comportement actuel AgeGate).

## Tests

- Splash → Intro si `intro_seen == false` et pas de session.
- Splash → Welcome si `intro_seen == true`.
- Splash → stub si session.
- Continuer / Passer → Welcome + `intro_seen == true`.
- Smoke : 3 titres visibles via swipe ou pomp pages.
- Régression : Splash ne pousse plus `AgeGatePage`.

## Critères de succès

- Au premier lancement (sans session), l’utilisateur voit 3 slides Nestle-like puis Bienvenue.
- Aux lancements suivants, Splash → Bienvenue directement.
- Aucun écran 18+ dans le flux.
- `flutter analyze` / tests splash + intro au vert.
