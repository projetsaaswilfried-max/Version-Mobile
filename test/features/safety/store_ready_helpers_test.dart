import 'package:agapeo/features/notifications/domain/notification_category.dart';
import 'package:agapeo/features/profile/domain/photo_quota.dart';
import 'package:agapeo/features/safety/domain/report_reason.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('mappe les types notifications vers les filtres N01', () {
    expect(
      notificationCategoryFromType('NEW_MESSAGE'),
      AppNotificationCategory.messages,
    );
    expect(
      notificationCategoryFromType('PROFILE_LIKE'),
      AppNotificationCategory.profile,
    );
    expect(
      notificationCategoryFromType('POST_COMMENT'),
      AppNotificationCategory.posts,
    );
    expect(
      notificationCategoryFromType('WEEKLY_RECOMMENDATION'),
      AppNotificationCategory.recommendations,
    );
  });

  test('quota photos 2 gratuit / 10 Premium', () {
    expect(myProfilePhotoQuota(isPremium: false), 2);
    expect(myProfilePhotoQuota(isPremium: true), 10);
  });

  test('motifs de signalement PRD', () {
    expect(ReportReason.values, hasLength(5));
    expect(reportTargetDbValue(ReportTargetType.profile), 'PROFILE');
  });
}
