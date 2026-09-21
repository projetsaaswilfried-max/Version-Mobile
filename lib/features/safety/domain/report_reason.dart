enum ReportTargetType { profile, message, post }

enum ReportReason {
  disrespectful,
  fakeProfile,
  inappropriate,
  solicitation,
  other;

  String get label => switch (this) {
    ReportReason.disrespectful => 'Comportement irrespectueux',
    ReportReason.fakeProfile => 'Faux profil',
    ReportReason.inappropriate => 'Contenu inapproprié',
    ReportReason.solicitation => 'Sollicitation commerciale',
    ReportReason.other => 'Autre',
  };

  String get dbValue => switch (this) {
    ReportReason.disrespectful => 'DISRESPECTFUL',
    ReportReason.fakeProfile => 'FAKE_PROFILE',
    ReportReason.inappropriate => 'INAPPROPRIATE',
    ReportReason.solicitation => 'SOLICITATION',
    ReportReason.other => 'OTHER',
  };
}

String reportTargetDbValue(ReportTargetType type) => switch (type) {
  ReportTargetType.profile => 'PROFILE',
  ReportTargetType.message => 'MESSAGE',
  ReportTargetType.post => 'POST',
};
