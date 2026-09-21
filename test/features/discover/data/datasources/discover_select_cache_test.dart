import 'package:agapeo/features/discover/data/datasources/discover_select_cache.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keeps visitor and candidate selects independent', () {
    final cache = DiscoverSelectCache();
    cache.set('visitor-select', single: true);
    cache.set('candidate-select', single: false);

    expect(cache.get(single: true), 'visitor-select');
    expect(cache.get(single: false), 'candidate-select');
  });

  test('falls back on missing column or oversized URI', () {
    expect(
      shouldFallbackDiscoverSelect(
        message: 'column values does not exist',
        code: '42703',
      ),
      isTrue,
    );
    expect(
      shouldFallbackDiscoverSelect(
        message: 'Request URI too long',
        code: '414',
      ),
      isTrue,
    );
  });

  test('does not fall back on RLS or expired session', () {
    expect(
      shouldFallbackDiscoverSelect(message: 'permission denied', code: '42501'),
      isFalse,
    );
    expect(
      shouldFallbackDiscoverSelect(message: 'JWT expired', code: 'PGRST301'),
      isFalse,
    );
  });
}
