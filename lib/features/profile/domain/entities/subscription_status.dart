enum SubscriptionStatus { free, active, canceled, expired }

SubscriptionStatus parseSubscriptionStatus(String raw) {
  final normalized = raw.trim().toUpperCase();
  return SubscriptionStatus.values.firstWhere(
    (value) => value.name.toUpperCase() == normalized,
    orElse: () => SubscriptionStatus.free,
  );
}
