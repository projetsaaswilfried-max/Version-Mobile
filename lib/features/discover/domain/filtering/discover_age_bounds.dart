import '../entities/discover_query.dart';

class DiscoverAgeBounds {
  const DiscoverAgeBounds._();

  /// Youngest birth date still matching [ageMin] (inclusive).
  static DateTime bornOnOrBefore(int ageMin, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    return DateTime(today.year - ageMin, today.month, today.day);
  }

  /// Oldest birth date still matching [ageMax] (inclusive).
  static DateTime bornOnOrAfter(int ageMax, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    return DateTime(
      today.year - ageMax - 1,
      today.month,
      today.day,
    ).add(const Duration(days: 1));
  }

  static String toIsoDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  static String? isoBornOnOrBefore(DiscoverQuery query, DateTime now) {
    final ageMin = query.normalized.ageMin;
    if (ageMin == null) return null;
    return toIsoDate(bornOnOrBefore(ageMin, now));
  }

  static String? isoBornOnOrAfter(DiscoverQuery query, DateTime now) {
    final ageMax = query.normalized.ageMax;
    if (ageMax == null) return null;
    return toIsoDate(bornOnOrAfter(ageMax, now));
  }
}
