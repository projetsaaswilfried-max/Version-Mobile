import 'package:agapeo/features/messages/presentation/thread/thread_time_labels.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('clock is 24h local', () {
    expect(formatThreadClock(DateTime(2026, 9, 19, 11, 22)), '11:22');
    expect(formatThreadClock(DateTime(2026, 9, 19, 9, 5)), '09:05');
  });

  test('day labels hier / aujourd\'hui / date', () {
    final now = DateTime(2026, 9, 19, 20);
    expect(
      formatThreadDayLabel(DateTime(2026, 9, 19, 8), now: now),
      'Aujourd\'hui',
    );
    expect(formatThreadDayLabel(DateTime(2026, 9, 18, 23), now: now), 'Hier');
    expect(
      formatThreadDayLabel(DateTime(2026, 9, 1, 10), now: now),
      '01/09/2026',
    );
  });

  test('same calendar day ignores time', () {
    expect(
      isSameCalendarDay(DateTime(2026, 9, 19, 1), DateTime(2026, 9, 19, 23)),
      isTrue,
    );
    expect(
      isSameCalendarDay(DateTime(2026, 9, 19), DateTime(2026, 9, 18)),
      isFalse,
    );
  });
}
