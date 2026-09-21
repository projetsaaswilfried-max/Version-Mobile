import 'package:agapeo/features/messages/domain/unread/unread_count.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final older = DateTime.utc(2026, 9, 18, 10);
  final lastRead = DateTime.utc(2026, 9, 18, 12);
  final newer = DateTime.utc(2026, 9, 18, 13);

  test('counts every incoming message when never read', () {
    expect(
      countUnreadMessages(lastReadAt: null, incomingCreatedAts: [older, newer]),
      2,
    );
  });

  test('counts only messages strictly after last_read_at', () {
    expect(
      countUnreadMessages(
        lastReadAt: lastRead,
        incomingCreatedAts: [older, lastRead, newer],
      ),
      1,
    );
  });
}
