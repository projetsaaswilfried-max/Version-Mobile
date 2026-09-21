import 'package:agapeo/features/notifications/data/notification_owner_columns.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('N01 utilise recipient_id, pas user_id ni profile_id', () {
    expect(notificationOwnerColumn, 'recipient_id');
  });
}
