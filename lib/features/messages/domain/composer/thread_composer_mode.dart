enum ThreadComposerMode {
  canCompose,
  inviteActions,
  waitingPeer,
  readOnlySystem,
  premiumRequired,
}

/// Écrire dans une conversation déjà acceptée exige un abonnement Premium
/// actif, sans tolérance gratuite (D29) — même règle que l'invitation.
ThreadComposerMode threadComposerMode({
  required String status,
  required bool isSystem,
  required bool isIncomingInvite,
  required bool isPremiumActive,
}) {
  if (isSystem) return ThreadComposerMode.readOnlySystem;
  final s = status.trim().toUpperCase();
  if (s == 'PENDING') {
    return isIncomingInvite
        ? ThreadComposerMode.inviteActions
        : ThreadComposerMode.waitingPeer;
  }
  if (!isPremiumActive) return ThreadComposerMode.premiumRequired;
  return ThreadComposerMode.canCompose;
}
