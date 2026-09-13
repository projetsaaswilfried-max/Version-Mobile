# Agapeo Mobile

App mobile de dating pour [agapeo.love](https://www.agapeo.love), Flutter.
Comportement produit : voir `docs/decisions.md` et `docs/mobile-addendum.md`
(PRD = source de vérité comportementale, addendum = delta mobile).

## Stack

| Domaine | Choix |
|---|---|
| State management | Riverpod (`Notifier` / `NotifierProvider`) |
| État immuable | `Equatable` + `copyWith` manuel (pas de codegen) |
| Réseau | Dio + interceptors (auth/refresh, retry, logging) |
| Stockage sécurisé | `flutter_secure_storage` (Keychain / Keystore) |
| Navigation | `Navigator` (push) pour l'instant — `go_router` prévu |
| SVG / images | `flutter_svg`, `image_picker` |

## Architecture — Clean Architecture, feature-first

Découpage par **feature**, pas par couche. Chaque feature complète a 3 couches,
avec la règle « les flèches pointent vers l'intérieur » :

```
presentation  ──►  domain  ◄──  data
 (UI + state)    (métier pur)   (API / cache)
```

- `domain/` — Dart pur (zéro Flutter/Dio) : `entities/`, `repositories/`
  (interfaces abstraites), `usecases/`.
- `data/` — `models/` (DTO + `fromJson` via la classe `Json`), `datasources/`
  (remote/local), `repositories/` (implémentations).
- `presentation/` — `pages/`, `widgets/`, et le state (Notifier Riverpod +
  classe d'état `Equatable`). Le state n'est pas une couche à part : c'est de
  la présentation.

**Pragmatisme** : on n'impose pas 3 couches à une feature triviale.

### Arborescence

```
lib/
├── core/                       # transverse à toutes les features
│   ├── config/                 # flavors (AppEnvironment), AppAssets
│   ├── di/                     # providers globaux Riverpod (dio, apiService, secureStorage…)
│   ├── error/                  # Failures (domain) + Exceptions (data)
│   ├── network/                # Dio + interceptors + ApiService
│   ├── parsing/                # classe Json (parsing défensif)
│   ├── security/                # SecureTokenStore
│   ├── theme/                  # design tokens + ThemeData (voir Design System)
│   ├── utils/                  # helpers (formatAmount, PhoneGroupFormatter…)
│   └── widgets/                # widgets réutilisables (design system) + barrel widgets.dart
├── features/
│   ├── auth/presentation/      # login/ · registration/ · forgot/ · widgets/
│   ├── home/presentation/      # home_shell + tabs/ + widgets/
│   └── onboarding/presentation # splash · welcome · onboarding · profile_choice
└── main.dart                   # ProviderScope + MaterialApp(AppTheme.light) + SplashPage
```

## State management (Riverpod)

Pont mental pour qui vient de `Provider` :

| Provider | Riverpod | Ici |
|---|---|---|
| `ChangeNotifier` | `Notifier<State>` | `RegistrationController extends Notifier<RegistrationState>` |
| `ChangeNotifierProvider` | `NotifierProvider` | `registrationProvider` |
| `notifyListeners()` | `state = newState` | `state = state.copyWith(...)` |
| `context.watch` | `ref.watch(p)` | s'abonner → rebuild (dans `build`) |
| `context.read` | `ref.read(p.notifier)` | agir (dans les callbacks) |

**Règle d'or** : `ref.watch` pour afficher, `ref.read` pour agir. L'état est
immuable (`Equatable` + `copyWith`) → Riverpod ne rebuild que si `==` change.

`ProviderScope` est à la racine (`main.dart`). Providers globaux dans
`core/di/providers.dart`.

## Design System

Tout est dans `core/theme/`. **Règle absolue : jamais de couleur/taille en
dur — toujours les tokens.**

- `AppColors` & `AppTypography` : `ThemeExtension` (mode-aware, prêts pour le
  dark mode).
- `AppSpacing`, `AppRadius`, `AppShadows` : classes `const` (invariantes au
  thème).
- Accès via les helpers : `context.colors.xxx` et `context.typography.xxx`
  (extensions dans `app_theme.dart`).
- Widgets réutilisables → `core/widgets/`.

### Assets

Chemins centralisés dans `core/config/app_assets.dart` (jamais de string en
dur). SVG dans `assets/icons/`, images dans `assets/images/`. Tinter un SVG :
`AppSvg(AppAssets.icXxx, size: …, color: …)`.

## Workflow Git

- Une branche par changement — on ne travaille jamais directement sur `main`.
- Nom de branche : `type/scope-court-descriptif`
  (ex. `feat/home-account-card`, `fix/auth-otp-focus`,
  `refactor/auth-merge-registration`).
- Toujours via Merge Request : revue de code obligatoire, aucun push direct
  sur `main` (ni sur les branches partagées).
- Messages de commit — Conventional Commits : `type(scope): titre court à
  l'impératif`
  - types : `feat`, `fix`, `refactor`, `chore`, `docs`, `style`, `test`, `perf`
  - scope = la feature/zone touchée : `home`, `auth`, `onboarding`,
    `design-system`, `core`…
  - exemples : `feat(home): carousel des comptes`,
    `fix(auth): focus du code secret`
  - corps optionnel pour le « pourquoi » ; **jamais de trailer
    Co-Authored-By**.
  - Garder des commits par lots logiques (un commit = une intention claire).
- Avant d'ouvrir la MR : `flutter analyze` propre + `flutter test` au vert.
