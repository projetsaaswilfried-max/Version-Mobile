# Auth email / OTP (MR1) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Livrer le cœur auth email de l’issue #5 : age gate, bienvenue, login, inscription, OTP, fallback mails, mdp oublié, stub session.

**Architecture:** Feature `auth/` en Clean Architecture pragmatique (domain ← data, presentation → domain). Session via `supabase_flutter` uniquement. Splash orchestre le premier hop. Pas de Google / deep links / A08.

**Tech Stack:** Flutter, Riverpod (`Notifier` / `NotifierProvider`), Equatable, `supabase_flutter`, `shared_preferences` (age gate), `url_launcher` (liens légaux), `flutter_test`.

**Spec:** `docs/superpowers/specs/2026-09-16-auth-email-otp-design.md`  
**Issue:** [#5](https://github.com/BespokApps/agapeo-mobile/issues/5)  
**Branche:** `feat/auth-email-otp` (partir de `main` à jour, ou rebase la branche `docs/auth-email-otp-design` dessus)

## Global Constraints

- Jamais de couleur / taille en dur : tokens `core/theme` + `AppButton` / `AppTextField`
- Domain = Dart pur (zéro Flutter / Supabase / Dio)
- `ref.watch` pour afficher, `ref.read` pour agir ; états `Equatable` + `copyWith`
- Pas de tiret cadratin / demi-cadratin dans code, docs, commits
- Branche `type/scope-court`, commits Conventional Commits, pas de `Co-Authored-By`
- `flutter analyze` propre + `flutter test` au vert avant MR
- Google absent de l’UI ; pas d’écriture `SecureTokenStore` en MR1
- Liens légaux : `https://www.agapeo.love/cgv`, `.../politique-de-confidentialite`, `.../charter`
- MDP ≥ 8, ≥ 1 lettre, ≥ 1 chiffre ; OTP = 6 digits ; resend débouncé 60 s

## File map

| Fichier | Rôle |
|---|---|
| `lib/features/auth/domain/entities/auth_session.dart` | `id` + `email` |
| `lib/features/auth/domain/repositories/auth_repository.dart` | Port auth |
| `lib/features/auth/domain/repositories/age_gate_store.dart` | Port flag 18+ |
| `lib/features/auth/domain/validation/auth_validators.dart` | Email / MDP / OTP |
| `lib/features/auth/domain/usecases/*.dart` | SignIn, SignUp, VerifyEmailOtp, ResendSignup, RequestPasswordReset, SignOut |
| `lib/features/auth/data/datasources/supabase_auth_datasource.dart` | Appels Supabase Auth |
| `lib/features/auth/data/datasources/age_gate_local_datasource.dart` | SharedPreferences |
| `lib/features/auth/data/repositories/auth_repository_impl.dart` | Map exceptions → `Failure` |
| `lib/features/auth/data/repositories/age_gate_store_impl.dart` | Impl store |
| `lib/features/auth/presentation/**` | Pages + Notifiers par écran |
| `lib/features/auth/di/auth_providers.dart` | Wiring Riverpod feature |
| `lib/features/onboarding/presentation/splash/splash_page.dart` | Premier hop |
| `pubspec.yaml` | `shared_preferences`, `url_launcher` |
| `test/features/auth/**` | Unit + widget smoke |

---

### Task 1: Domain (entité, ports, validateurs, use cases)

**Files:**
- Create: `lib/features/auth/domain/entities/auth_session.dart`
- Create: `lib/features/auth/domain/repositories/auth_repository.dart`
- Create: `lib/features/auth/domain/repositories/age_gate_store.dart`
- Create: `lib/features/auth/domain/validation/auth_validators.dart`
- Create: `lib/features/auth/domain/usecases/sign_in_with_password.dart`
- Create: `lib/features/auth/domain/usecases/sign_up.dart`
- Create: `lib/features/auth/domain/usecases/verify_email_otp.dart`
- Create: `lib/features/auth/domain/usecases/resend_signup_email.dart`
- Create: `lib/features/auth/domain/usecases/request_password_reset.dart`
- Create: `lib/features/auth/domain/usecases/sign_out.dart`
- Test: `test/features/auth/domain/validation/auth_validators_test.dart`

**Interfaces:**
- Produces: `AuthSession`, `AuthRepository`, `AgeGateStore`, `AuthValidators`, use cases ci-dessous

- [ ] **Step 1: Write failing validators tests**

```dart
import 'package:agapeo/features/auth/domain/validation/auth_validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthValidators.email', () {
    test('rejects empty', () {
      expect(AuthValidators.email(''), isNotNull);
    });
    test('rejects invalid', () {
      expect(AuthValidators.email('pas-un-email'), isNotNull);
    });
    test('accepts valid', () {
      expect(AuthValidators.email('a@b.co'), isNull);
    });
  });

  group('AuthValidators.password', () {
    test('rejects short', () {
      expect(AuthValidators.password('Ab1'), isNotNull);
    });
    test('rejects no digit', () {
      expect(AuthValidators.password('Abcdefgh'), isNotNull);
    });
    test('rejects no letter', () {
      expect(AuthValidators.password('12345678'), isNotNull);
    });
    test('accepts valid', () {
      expect(AuthValidators.password('Abcdefg1'), isNull);
    });
  });

  group('AuthValidators.otp', () {
    test('requires exactly 6 digits', () {
      expect(AuthValidators.otp('12345'), isNotNull);
      expect(AuthValidators.otp('1234567'), isNotNull);
      expect(AuthValidators.otp('12ab56'), isNotNull);
      expect(AuthValidators.otp('123456'), isNull);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/auth/domain/validation/auth_validators_test.dart`  
Expected: FAIL (library not found / undefined)

- [ ] **Step 3: Implement domain files**

`auth_session.dart`:

```dart
import 'package:equatable/equatable.dart';

class AuthSession extends Equatable {
  const AuthSession({required this.id, required this.email});

  final String id;
  final String email;

  @override
  List<Object?> get props => [id, email];
}
```

`auth_repository.dart`:

```dart
import '../../../../core/error/result.dart';
import '../entities/auth_session.dart';

abstract class AuthRepository {
  AuthSession? get currentSession;

  Stream<AuthSession?> get authStateChanges;

  Future<Result<AuthSession>> signInWithPassword({
    required String email,
    required String password,
  });

  /// No session until email confirmed (OTP or link).
  Future<Result<void>> signUp({
    required String email,
    required String password,
    required String firstName,
    String? lastName,
  });

  Future<Result<AuthSession>> verifyEmailOtp({
    required String email,
    required String token,
  });

  Future<Result<void>> resendSignupEmail({required String email});

  Future<Result<void>> requestPasswordReset({required String email});

  Future<Result<void>> signOut();
}
```

`age_gate_store.dart`:

```dart
abstract class AgeGateStore {
  Future<bool> isAccepted();
  Future<void> accept();
}
```

`auth_validators.dart`:

```dart
class AuthValidators {
  const AuthValidators._();

  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final _hasLetter = RegExp(r'[A-Za-z]');
  static final _hasDigit = RegExp(r'\d');
  static final _otp = RegExp(r'^\d{6}$');

  /// Returns a French error message, or null if valid.
  static String? email(String value) {
    final v = value.trim();
    if (v.isEmpty) return 'L\'email est requis.';
    if (!_email.hasMatch(v)) return 'Email invalide.';
    return null;
  }

  static String? password(String value) {
    if (value.length < 8) {
      return 'Le mot de passe doit contenir au moins 8 caractères.';
    }
    if (!_hasLetter.hasMatch(value) || !_hasDigit.hasMatch(value)) {
      return 'Le mot de passe doit contenir au moins une lettre et un chiffre.';
    }
    return null;
  }

  static String? otp(String value) {
    if (!_otp.hasMatch(value.trim())) {
      return 'Saisis le code à 6 chiffres.';
    }
    return null;
  }
}
```

Use cases (même pattern pour chacun) :

```dart
// sign_in_with_password.dart
import '../../../../core/error/result.dart';
import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';
import '../validation/auth_validators.dart';
import '../../../../core/error/failure.dart';

class SignInWithPassword {
  const SignInWithPassword(this._repo);

  final AuthRepository _repo;

  Future<Result<AuthSession>> call({
    required String email,
    required String password,
  }) async {
    final emailError = AuthValidators.email(email);
    final passwordError = AuthValidators.password(password);
    if (emailError != null || passwordError != null) {
      return Err(
        ValidationFailure(
          'Vérifie les champs.',
          fieldErrors: {
            if (emailError != null) 'email': emailError,
            if (passwordError != null) 'password': passwordError,
          },
        ),
      );
    }
    return _repo.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }
}
```

`SignUp` : valide email, password, `firstName` non vide, passwords match (passer `passwordConfirm`), mappe fieldErrors `firstName` / `passwordConfirm`.  
`VerifyEmailOtp` : valide email + otp puis `_repo.verifyEmailOtp`.  
`ResendSignupEmail` / `RequestPasswordReset` : valide email puis repo.  
`SignOut` : `_repo.signOut()`.

- [ ] **Step 4: Run validators tests**

Run: `flutter test test/features/auth/domain/validation/auth_validators_test.dart`  
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git checkout -b feat/auth-email-otp  # si pas encore créée depuis main + spec
git add lib/features/auth/domain test/features/auth/domain
git commit -m "$(cat <<'EOF'
feat(auth): domain session, ports, validateurs et use cases

EOF
)"
```

---

### Task 2: Data layer Supabase + age gate local

**Files:**
- Modify: `pubspec.yaml` (ajouter `shared_preferences`)
- Create: `lib/features/auth/data/datasources/supabase_auth_datasource.dart`
- Create: `lib/features/auth/data/datasources/age_gate_local_datasource.dart`
- Create: `lib/features/auth/data/repositories/auth_repository_impl.dart`
- Create: `lib/features/auth/data/repositories/age_gate_store_impl.dart`
- Create: `lib/features/auth/di/auth_providers.dart`
- Test: `test/features/auth/data/auth_repository_impl_test.dart`

**Interfaces:**
- Consumes: `AuthRepository`, `AgeGateStore`, `AuthSession`, `Failure` / `Result`
- Produces: `authRepositoryProvider`, `ageGateStoreProvider`, use case providers

- [ ] **Step 1: Write failing repository mapping test**

Fake datasource :

```dart
class FakeSupabaseAuthDataSource {
  Exception? toThrow;
  Future<({String id, String email})> signIn({
    required String email,
    required String password,
  }) async {
    if (toThrow != null) throw toThrow!;
    return (id: 'u1', email: email);
  }
  // stub other methods similarly for the test file scope
}
```

Test : quand datasource lance `UnauthorizedException('Invalid login')`, `AuthRepositoryImpl.signInWithPassword` retourne `Err` avec `UnauthorizedFailure` dont le `message` est en français mappé (ou le message fourni).

Au minimum couvrir :
1. succès → `Ok(AuthSession(...))`
2. `UnauthorizedException` → `UnauthorizedFailure`
3. `NetworkException` → `NetworkFailure`
4. `ValidationException` → `ValidationFailure` (garde `fieldErrors`)
5. autre → `UnknownFailure`

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/auth/data/auth_repository_impl_test.dart`  
Expected: FAIL

- [ ] **Step 3: Add dependency and implement data**

```bash
flutter pub add shared_preferences
```

`supabase_auth_datasource.dart` (extraits) :

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/exceptions.dart';

class SupabaseAuthDataSource {
  SupabaseAuthDataSource(this._client);

  final SupabaseClient _client;

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  Future<User> signInWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final user = res.user;
      if (user == null) {
        throw const UnauthorizedException('Identifiants incorrects.');
      }
      return user;
    } on AuthException catch (e) {
      throw _mapAuthException(e);
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String firstName,
    String? lastName,
  }) async {
    try {
      await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'first_name': firstName,
          if (lastName != null && lastName.isNotEmpty) 'last_name': lastName,
        },
      );
    } on AuthException catch (e) {
      throw _mapAuthException(e);
    }
  }

  Future<User> verifyEmailOtp({
    required String email,
    required String token,
  }) async {
    try {
      final res = await _client.auth.verifyOTP(
        type: OtpType.signup,
        email: email,
        token: token,
      );
      final user = res.user;
      if (user == null) {
        throw const ValidationException('Code incorrect ou expiré.');
      }
      return user;
    } on AuthException catch (e) {
      throw _mapAuthException(e);
    }
  }

  Future<void> resendSignupEmail({required String email}) async {
    try {
      await _client.auth.resend(type: OtpType.signup, email: email);
    } on AuthException catch (e) {
      throw _mapAuthException(e);
    }
  }

  Future<void> requestPasswordReset({required String email}) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      throw _mapAuthException(e);
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Exception _mapAuthException(AuthException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('invalid login') || msg.contains('invalid credentials')) {
      return const UnauthorizedException('Email ou mot de passe incorrect.');
    }
    if (msg.contains('email not confirmed')) {
      return const UnauthorizedException(
        'Email non confirmé. Vérifie ta boîte mail ou saisis le code.',
      );
    }
    if (msg.contains('user already registered')) {
      return const ValidationException(
        'Un compte existe déjà avec cet email.',
        fieldErrors: {'email': 'Un compte existe déjà avec cet email.'},
      );
    }
    if (msg.contains('network') || msg.contains('socket')) {
      return NetworkException(e.message);
    }
    return ServerException(e.message);
  }
}
```

`AuthRepositoryImpl` mappe `User` → `AuthSession(id: user.id, email: user.email ?? '')`, catch exceptions → `Failure` via `Result`.  
`authStateChanges` : mappe `onAuthStateChange` vers `AuthSession?`.

`AgeGateLocalDataSource` / `AgeGateStoreImpl` :

```dart
static const _key = 'agapeo_age_gate_accepted';

Future<bool> isAccepted() async =>
    (await _prefs.getBool(_key)) ?? false;

Future<void> accept() async => _prefs.setBool(_key, true);
```

`auth_providers.dart` :

```dart
final ageGateStoreProvider = Provider<AgeGateStore>((ref) {
  throw UnimplementedError('Override in ProviderScope after SharedPreferences.init');
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    SupabaseAuthDataSource(ref.watch(supabaseClientProvider)),
  );
});

final signInWithPasswordProvider = Provider(
  (ref) => SignInWithPassword(ref.watch(authRepositoryProvider)),
);
// … other use cases
```

Dans `main.dart` (Task 3) : `SharedPreferences.getInstance()` puis `ProviderScope(overrides: [ageGateStoreProvider.overrideWithValue(...)])`.

- [ ] **Step 4: Run repository tests**

Run: `flutter test test/features/auth/data/auth_repository_impl_test.dart`  
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/features/auth/data lib/features/auth/di test/features/auth/data
git commit -m "$(cat <<'EOF'
feat(auth): data Supabase Auth et age gate local

EOF
)"
```

---

### Task 3: Splash routing + age gate (A09) + deps légales

**Files:**
- Modify: `pubspec.yaml` (`url_launcher`)
- Modify: `lib/main.dart`
- Modify: `lib/features/onboarding/presentation/splash/splash_page.dart`
- Create: `lib/features/auth/presentation/age_gate/age_gate_page.dart`
- Create: `lib/features/auth/presentation/welcome/welcome_page.dart` (shell minimal OK ; contenu Task 4)
- Create: `lib/features/auth/presentation/session_stub/session_stub_page.dart` (shell minimal)
- Create: `lib/core/config/legal_urls.dart`
- Test: `test/features/auth/presentation/age_gate/age_gate_store_test.dart` (unit sur store fake)

**Interfaces:**
- Consumes: `AgeGateStore`, `AuthRepository.currentSession`
- Produces: navigation Splash → A09 | A02 | stub

- [ ] **Step 1: Write failing age gate store test**

```dart
test('accept persists true', () async {
  final store = InMemoryAgeGateStore();
  expect(await store.isAccepted(), false);
  await store.accept();
  expect(await store.isAccepted(), true);
});
```

(`InMemoryAgeGateStore` dans le fichier de test.)

- [ ] **Step 2: Run to verify fail / then implement store already done in Task 2 ; use in-memory for test**

- [ ] **Step 3: Wire splash + pages**

`legal_urls.dart`:

```dart
class LegalUrls {
  const LegalUrls._();
  static const cgv = 'https://www.agapeo.love/cgv';
  static const privacy = 'https://www.agapeo.love/politique-de-confidentialite';
  static const charter = 'https://www.agapeo.love/charter';
}
```

`SplashPage` devient `ConsumerStatefulWidget` :

```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) => _route());
}

Future<void> _route() async {
  final auth = ref.read(authRepositoryProvider);
  final session = auth.currentSession;
  if (session != null) {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => SessionStubPage(email: session.email)),
    );
    return;
  }
  final accepted = await ref.read(ageGateStoreProvider).isAccepted();
  if (!mounted) return;
  Navigator.of(context).pushReplacement(
    MaterialPageRoute(
      builder: (_) => accepted ? const WelcomePage() : const AgeGatePage(),
    ),
  );
}
```

`AgeGatePage` : logo `AppAssets.logoFull`, texte 18+, `AppButton` « J’ai 18 ans ou plus » → `await store.accept()` → `pushReplacement(WelcomePage)`. Refus : texte d’erreur sous le bouton, pas de navigation.

`main.dart` :

```dart
final prefs = await SharedPreferences.getInstance();
runApp(
  ProviderScope(
    overrides: [
      ageGateStoreProvider.overrideWithValue(AgeGateStoreImpl(prefs)),
    ],
    child: const AgapeoApp(),
  ),
);
```

```bash
flutter pub add url_launcher
```

Helper (dans `lib/features/auth/presentation/widgets/legal_link_text.dart` ou inline) :

```dart
Future<void> openLegalUrl(String url) async {
  final uri = Uri.parse(url);
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}
```

- [ ] **Step 4: Update smoke test**

Le test splash actuel pump `AgapeoApp` sans overrides : fournir `ProviderScope` + fake `AgeGateStore` + mock/fake `AuthRepository` si `authRepositoryProvider` lit Supabase. Option : garder le test sur `SplashPage` seul avec overrides.

Si Supabase n’est pas initialisé en test, `authRepositoryProvider` ne doit pas toucher `Supabase.instance` : injecter un `FakeAuthRepository` via override dans les tests widget.

- [ ] **Step 5: Commit**

```bash
git add pubspec.yaml lib/main.dart lib/core/config/legal_urls.dart \
  lib/features/onboarding/presentation/splash \
  lib/features/auth/presentation/age_gate \
  lib/features/auth/presentation/welcome \
  lib/features/auth/presentation/session_stub \
  test/
git commit -m "$(cat <<'EOF'
feat(auth): splash routing, age gate et pages coquilles

EOF
)"
```

---

### Task 4: Welcome (A02) + Login (A03)

**Files:**
- Modify: `lib/features/auth/presentation/welcome/welcome_page.dart`
- Create: `lib/features/auth/presentation/login/login_state.dart`
- Create: `lib/features/auth/presentation/login/login_controller.dart`
- Create: `lib/features/auth/presentation/login/login_page.dart`
- Test: `test/features/auth/presentation/login/login_controller_test.dart`
- Test: `test/features/auth/presentation/welcome/welcome_page_test.dart`

**Interfaces:**
- Consumes: `SignInWithPassword`, `AuthSession`
- Produces: navigation vers stub / forgot / register

- [ ] **Step 1: Failing controller test**

Fake `AuthRepository` / use case : `signIn` succès met un flag ; validation email vide → `fieldErrors`.

```dart
test('submit with empty email sets field error', () async {
  final controller = // build Notifier with fake
  await controller.submit();
  expect(controller.state.fieldErrors['email'], isNotNull);
  expect(controller.state.isLoading, false);
});
```

- [ ] **Step 2: Run fail**

- [ ] **Step 3: Implement Welcome + Login**

`WelcomePage` : logo, accroche courte (« Rencontres chrétiennes pour le mariage » ou copy proche charte), `AppButton` « Se connecter » → `LoginPage`, `TextButton` « Créer un compte » → `RegistrationPage` (placeholder `SizedBox` jusqu’à Task 5 si besoin : créer page vide navigable).

`LoginState` :

```dart
class LoginState extends Equatable {
  const LoginState({
    this.email = '',
    this.password = '',
    this.isLoading = false,
    this.fieldErrors = const {},
    this.formError,
    this.succeeded = false,
  });
  // copyWith + props
}
```

`LoginController extends Notifier<LoginState>` :
- `setEmail` / `setPassword` clear field error
- `submit` : `isLoading true` → `ref.read(signInWithPasswordProvider)(...)` → on `Ok` `succeeded = true` ; on `Err` map `ValidationFailure.fieldErrors` / `formError = failure.message`

`LoginPage` : écoute `succeeded` via `ref.listen` → `pushReplacement(SessionStubPage)`. Liens : mdp oublié, inscription, CGU, confidentialité (`LegalUrls` + `url_launcher`). **Pas de Google.**

- [ ] **Step 4: Tests pass + widget smoke Welcome (find « Se connecter »)**

- [ ] **Step 5: Commit**

```bash
git commit -m "$(cat <<'EOF'
feat(auth): écrans bienvenue et connexion email

EOF
)"
```

---

### Task 5: Registration (A04)

**Files:**
- Create: `lib/features/auth/presentation/registration/registration_state.dart`
- Create: `lib/features/auth/presentation/registration/registration_controller.dart`
- Create: `lib/features/auth/presentation/registration/registration_page.dart`
- Test: `test/features/auth/presentation/registration/registration_controller_test.dart`
- Test: `test/features/auth/presentation/registration/registration_page_test.dart`

**Interfaces:**
- Consumes: `SignUp`
- Produces: on succès → `OtpPage(email:, password:)` (password en args route seulement)

- [ ] **Step 1: Failing tests** (CGU non cochées → erreur ; passwords mismatch → `passwordConfirm`)

- [ ] **Step 2: Run fail**

- [ ] **Step 3: Implement**

Champs : prénom, nom optionnel, email, MDP, confirm MDP, checkbox CGU, checkbox charte.  
`SignUp` use case doit refuser si `!acceptedTerms || !acceptedCharter` avec messages FR.  
Succès → `Navigator.pushReplacement(OtpPage(email: email, password: password))`.  
Liens CGU + charte via `LegalUrls`. Pas de Google.

- [ ] **Step 4: Tests pass**

- [ ] **Step 5: Commit**

```bash
git commit -m "$(cat <<'EOF'
feat(auth): inscription email avec CGU et charte

EOF
)"
```

---

### Task 6: OTP (A05) + Verify email fallback (A06)

**Files:**
- Create: `lib/features/auth/presentation/otp/otp_state.dart`
- Create: `lib/features/auth/presentation/otp/otp_controller.dart`
- Create: `lib/features/auth/presentation/otp/otp_page.dart`
- Create: `lib/features/auth/presentation/verify_email/verify_email_state.dart`
- Create: `lib/features/auth/presentation/verify_email/verify_email_controller.dart`
- Create: `lib/features/auth/presentation/verify_email/verify_email_page.dart`
- Test: `test/features/auth/presentation/otp/otp_controller_test.dart`
- Test: `test/features/auth/presentation/verify_email/verify_email_controller_test.dart`

**Interfaces:**
- Consumes: `VerifyEmailOtp`, `ResendSignupEmail`, `SignInWithPassword`
- Produces: session → stub ; lien A05 → A06

- [ ] **Step 1: Failing tests**

OTP : code `12345` → erreur validation ; resend démarre cooldown 60 ; second resend immédiat no-op / garde timer.  
A06 : `confirm` appelle signIn ; si `email_not_confirmed` → formError.

Utiliser une horloge injectable `DateTime Function() now` sur le controller pour tester le debounce sans `Future.delayed(60s)` :

```dart
class OtpController extends Notifier<OtpState> {
  OtpController({DateTime Function()? clock}) : _clock = clock ?? DateTime.now;
  final DateTime Function() _clock;
  // resendAllowedAt stored on state
}
```

- [ ] **Step 2: Run fail**

- [ ] **Step 3: Implement UI**

`OtpPage` : 6 cases (ou un `TextField` digit-only longueur 6 stylé tokens), CTA valider, « Renvoyer le code » disabled pendant cooldown, lien « Tu n’as pas reçu de code ? » → `VerifyEmailPage(email:, password:)`.

Inspiration visuelle (Figma Nestle / Free UI Kit) : cases OTP + timer, mais **6** digits Agapeo (pas 4), tokens Agapeo (`#E83E75`), logo Agapeo.

`VerifyEmailPage` : texte « Vérifie tes mails », « J’ai confirmé » → signIn, « Renvoyer » 60 s.

- [ ] **Step 4: Tests pass**

- [ ] **Step 5: Commit**

```bash
git commit -m "$(cat <<'EOF'
feat(auth): confirmation OTP et fallback vérifie tes mails

EOF
)"
```

---

### Task 7: Forgot password (A07) + Session stub polish

**Files:**
- Create: `lib/features/auth/presentation/forgot_password/forgot_password_state.dart`
- Create: `lib/features/auth/presentation/forgot_password/forgot_password_controller.dart`
- Create: `lib/features/auth/presentation/forgot_password/forgot_password_page.dart`
- Modify: `lib/features/auth/presentation/session_stub/session_stub_page.dart`
- Test: `test/features/auth/presentation/forgot_password/forgot_password_controller_test.dart`

**Interfaces:**
- Consumes: `RequestPasswordReset`, `SignOut`

- [ ] **Step 1: Failing test** : après submit (même email inconnu), `successMessage` générique anti-énumération, jamais « email introuvable ».

Message exact :

```text
Si un compte existe pour cette adresse, tu recevras un email avec la suite.
```

Même en cas d’erreur réseau, préférer le message générique pour le chemin « succès API » ; erreurs réseau franches peuvent rester `formError` réseau (OK).

- [ ] **Step 2: Run fail**

- [ ] **Step 3: Implement A07 + stub**

`SessionStubPage` : affiche email, `AppButton` Déconnexion → `signOut` → `pushAndRemoveUntil(WelcomePage)`.

Pas d’écran A08.

- [ ] **Step 4: Tests pass**

- [ ] **Step 5: Commit**

```bash
git commit -m "$(cat <<'EOF'
feat(auth): mot de passe oublié et stub session

EOF
)"
```

---

### Task 8: Widget smoke + analyze + checklist manuelle

**Files:**
- Modify/create widget tests A02/A03/A04
- Possibly fix splash `Colors.white` → `context.colors.surface` si croisé

- [ ] **Step 1: Widget smoke**

Pour chaque page, `ProviderScope(overrides: [...])` + `pumpWidget` + `expect(find.text(...))` / `find.byType(AppTextField)`.

- [ ] **Step 2: Run full suite**

```bash
flutter analyze
flutter test
```

Expected: no issues / all tests pass

- [ ] **Step 3: Manual checklist (dev machine avec `--dart-define` Supabase)**

- [ ] Age gate une fois puis Bienvenue  
- [ ] Login → stub → déconnexion  
- [ ] Inscription → OTP → stub  
- [ ] A06 depuis OTP  
- [ ] MDP oublié message générique  
- [ ] Liens légaux externes  
- [ ] Pas de bouton Google  

Ops (hors code) : template email Supabase = `{{ .ConfirmationURL }}` + `{{ .Token }}`.

- [ ] **Step 4: Commit + MR**

```bash
git commit -m "$(cat <<'EOF'
test(auth): smoke widgets et finalisation MR1

EOF
)"
# push + gh pr create lié à #5 quand demandé
```

---

## Spec coverage (self-review)

| Spec | Task |
|---|---|
| Age gate avant Bienvenue, 1×/install | 3 |
| A02 Bienvenue | 4 |
| A03 Login email/MDP + légal, pas Google | 4 |
| A04 Inscription + CGU + charte | 5 |
| A05 OTP 6 digits + resend 60 s | 6 |
| A06 minimal depuis A05 | 6 |
| A07 mdp oublié générique | 7 |
| Stub Connecté + logout | 3, 7 |
| Splash hop session / age / welcome | 3 |
| Domain + data Clean Arch | 1, 2 |
| Validators PRD | 1 |
| Tests unit / notifier / smoke | 1, 2, 4–8 |
| Hors scope Google / A08 / #6 | respecté |

## Placeholder scan

Aucun TBD / « implement later » laissé volontairement.

## Type consistency

- `AuthSession({id, email})` partout  
- Use cases retournent `Result<T>`  
- Controllers exposent `fieldErrors: Map<String, String>` + `formError: String?`  
- Cooldown resend : `DateTime? resendAvailableAt` sur l’état OTP / A06
