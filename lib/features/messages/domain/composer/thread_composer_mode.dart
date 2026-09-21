enum ThreadComposerMode {
  canCompose,
  inviteActions,
  waitingPeer,
  readOnlySystem,
}

ThreadComposerMode threadComposerMode({
  required String status,
  required bool isSystem,
  required bool isIncomingInvite,
}) {
  if (isSystem) return ThreadComposerMode.readOnlySystem;
  final s = status.trim().toUpperCase();
  if (s == 'PENDING') {
    return isIncomingInvite
        ? ThreadComposerMode.inviteActions
        : ThreadComposerMode.waitingPeer;
  }
  return ThreadComposerMode.canCompose;
}
