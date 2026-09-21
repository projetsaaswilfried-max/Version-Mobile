import 'entities/app_notification.dart';

/// Sections temporelles pour la liste N01.
enum NotificationDaySection { today, yesterday, earlier }

extension NotificationDaySectionX on NotificationDaySection {
  String get label => switch (this) {
    NotificationDaySection.today => 'Aujourd\'hui',
    NotificationDaySection.yesterday => 'Hier',
    NotificationDaySection.earlier => 'Plus tôt',
  };
}

NotificationDaySection notificationDaySection(
  DateTime createdAt, {
  DateTime? now,
}) {
  final reference = now ?? DateTime.now();
  final local = createdAt.isUtc ? createdAt.toLocal() : createdAt;
  final today = DateTime(reference.year, reference.month, reference.day);
  final day = DateTime(local.year, local.month, local.day);
  final delta = today.difference(day).inDays;
  if (delta <= 0) return NotificationDaySection.today;
  if (delta == 1) return NotificationDaySection.yesterday;
  return NotificationDaySection.earlier;
}

/// Regroupe une liste déjà triée (plus récent → plus ancien) en sections.
List<(NotificationDaySection, List<AppNotification>)> groupNotificationsByDay(
  List<AppNotification> items, {
  DateTime? now,
}) {
  final buckets = <NotificationDaySection, List<AppNotification>>{
    NotificationDaySection.today: [],
    NotificationDaySection.yesterday: [],
    NotificationDaySection.earlier: [],
  };
  for (final item in items) {
    buckets[notificationDaySection(item.createdAt, now: now)]!.add(item);
  }
  return [
    for (final section in NotificationDaySection.values)
      if (buckets[section]!.isNotEmpty) (section, buckets[section]!),
  ];
}
