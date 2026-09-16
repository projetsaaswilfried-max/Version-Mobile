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
