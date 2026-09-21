import 'package:agapeo/features/notifications/domain/entities/app_notification.dart';
import 'package:agapeo/features/notifications/domain/notification_category.dart';
import 'package:agapeo/features/notifications/domain/notification_day_section.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 9, 21, 18);

  AppNotification item(DateTime at, {String id = '1'}) => AppNotification(
    id: id,
    title: 'T',
    body: '',
    createdAt: at,
    isRead: true,
    category: AppNotificationCategory.all,
  );

  test('notificationDaySection maps today / yesterday / earlier', () {
    expect(
      notificationDaySection(DateTime(2026, 9, 21, 9), now: now),
      NotificationDaySection.today,
    );
    expect(
      notificationDaySection(DateTime(2026, 9, 20, 23), now: now),
      NotificationDaySection.yesterday,
    );
    expect(
      notificationDaySection(DateTime(2026, 9, 10), now: now),
      NotificationDaySection.earlier,
    );
  });

  test('groupNotificationsByDay keeps chronological buckets', () {
    final groups = groupNotificationsByDay(
      [
        item(DateTime(2026, 9, 21, 12), id: 'a'),
        item(DateTime(2026, 9, 20, 8), id: 'b'),
        item(DateTime(2026, 9, 1), id: 'c'),
      ],
      now: now,
    );

    expect(groups.map((g) => g.$1).toList(), [
      NotificationDaySection.today,
      NotificationDaySection.yesterday,
      NotificationDaySection.earlier,
    ]);
    expect(groups[0].$2.single.id, 'a');
    expect(groups[1].$2.single.id, 'b');
    expect(groups[2].$2.single.id, 'c');
  });
}
