import 'package:agapeo/core/utils/format_relative_time.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 9, 17, 15, 0);

  test('shows instant under a minute', () {
    expect(
      formatRelativeTime(now.subtract(const Duration(seconds: 20)), now: now),
      'À l\'instant',
    );
  });

  test('shows minutes, hours and days', () {
    expect(
      formatRelativeTime(now.subtract(const Duration(minutes: 8)), now: now),
      'il y a 8 min',
    );
    expect(
      formatRelativeTime(now.subtract(const Duration(hours: 3)), now: now),
      'il y a 3 h',
    );
    expect(
      formatRelativeTime(now.subtract(const Duration(days: 2)), now: now),
      'il y a 2 j',
    );
  });

  test('falls back to a date after a week', () {
    expect(
      formatRelativeTime(DateTime(2026, 1, 2, 10), now: now),
      '02/01/2026',
    );
  });

  test('uses a calendar date when the clock is ahead of the post', () {
    expect(
      formatRelativeTime(now.add(const Duration(hours: 2)), now: now),
      '17/09/2026',
    );
  });
}
