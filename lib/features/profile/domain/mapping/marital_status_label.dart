/// Libellés FR pour `profiles.marital_status` (PRD §20 `marital_status_type`).
String? maritalStatusLabel(String? raw) {
  final value = raw?.trim();
  if (value == null || value.isEmpty) return null;

  switch (_normalizeMaritalDb(value)) {
    case 'SINGLE_NO_CHILDREN':
    case 'SINGLE':
      return 'Célibataire sans enfant';
    case 'SINGLE_WITH_CHILDREN':
      return 'Célibataire avec enfant(s)';
    case 'DIVORCED':
      return 'Divorcé(e)';
    case 'WIDOWED':
      return 'Veuf / veuve';
    default:
      // Valeur inconnue : ne pas afficher le brut enum.
      return null;
  }
}

String _normalizeMaritalDb(String raw) =>
    raw.toUpperCase().replaceAll('-', '_');

/// DB enum → id onboarding (`OnboardingMaritalStatus.name`).
String? maritalStatusToOnboardingId(String? db) {
  final value = db?.trim();
  if (value == null || value.isEmpty) return null;
  switch (_normalizeMaritalDb(value)) {
    case 'SINGLE_NO_CHILDREN':
    case 'SINGLE':
      return 'single';
    case 'SINGLE_WITH_CHILDREN':
      return 'singleWithChildren';
    case 'DIVORCED':
      return 'divorced';
    case 'WIDOWED':
      return 'widowed';
    default:
      return null;
  }
}

/// Id onboarding → valeur DB `profiles.marital_status`.
String? maritalStatusFromOnboardingId(String id) {
  switch (id) {
    case 'single':
      return 'SINGLE_NO_CHILDREN';
    case 'singleWithChildren':
      return 'SINGLE_WITH_CHILDREN';
    case 'divorced':
      return 'DIVORCED';
    case 'widowed':
      return 'WIDOWED';
    default:
      return null;
  }
}
