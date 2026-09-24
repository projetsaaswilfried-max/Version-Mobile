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
  /// SHA-1, pas par ce client id).
  static const iosClientId =
      '58020321221-kalne97sckgk9dkar18af8iq1ka7qlfc.apps.googleusercontent.com';
}
