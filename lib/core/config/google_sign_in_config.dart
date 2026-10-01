/// Le "Web Client ID" du provider Google déjà configuré côté Supabase
/// (Authentication → Providers → Google) - `google_sign_in` doit demander un
/// jeton dont l'audience correspond à ce client pour que
/// `Supabase.auth.signInWithIdToken` puisse le vérifier.
class GoogleSignInConfig {
  const GoogleSignInConfig._();

  static const webClientId =
      '58020321221-q95iffvkkitsflidtphbh8mk1kinuq2s.apps.googleusercontent.com';

  /// Client OAuth de type "iOS" (même projet GCP que [webClientId]) - requis
  /// par `google_sign_in_ios`. Ignoré sur Android (identifié par package +
  /// SHA-1, pas par ce client id). Lié au bundle ID `com.agapeo.app` (D43).
  static const iosClientId =
      '58020321221-asvugu3nmdukojmt3fvsh6j00mtbjdtj.apps.googleusercontent.com';
}
