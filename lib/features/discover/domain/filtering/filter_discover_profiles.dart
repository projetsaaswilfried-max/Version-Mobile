import '../entities/discover_profile.dart';
import '../entities/discover_query.dart';

List<DiscoverProfile> filterDiscoverProfiles(
  List<DiscoverProfile> profiles,
  DiscoverQuery query,
) {
  final normalized = query.normalized;
  if (normalized.isEmpty) return profiles;
  return profiles.where((profile) => _matches(profile, normalized)).toList();
}

bool _matches(DiscoverProfile profile, DiscoverQuery query) {
  final search = query.search;
  if (search != null) {
    final needle = search.toLowerCase();
    final name = profile.displayName.toLowerCase();
    final city = (profile.city ?? '').toLowerCase();
    if (!name.contains(needle) && !city.contains(needle)) return false;
  }

  final country = query.country;
  if (country != null) {
    final value = (profile.traits.country ?? '').toLowerCase();
    if (value != country.toLowerCase()) return false;
  }

  final city = query.city;
  if (city != null) {
    final value = (profile.city ?? '').toLowerCase();
    if (!value.contains(city.toLowerCase())) return false;
  }

  final profession = query.profession;
  if (profession != null) {
    final value = (profile.profession ?? '').toLowerCase();
    if (!value.contains(profession.toLowerCase())) return false;
  }

  if (query.denominations.isNotEmpty) {
    final confession = (profile.traits.confession ?? '').toLowerCase();
    final allowed = {
      for (final item in query.denominations) item.toLowerCase(),
    };
    if (!allowed.contains(confession)) return false;
  }

  if (query.maritalStatuses.isNotEmpty) {
    final marital = _normalizeMarital(profile.traits.maritalStatus);
    final allowed = {
      for (final item in query.maritalStatuses) _normalizeMarital(item),
    }..removeWhere((item) => item.isEmpty);
    if (marital.isEmpty || !allowed.contains(marital)) return false;
  }

  final age = profile.age;
  final ageMin = query.ageMin;
  if (ageMin != null && (age == null || age < ageMin)) return false;
  final ageMax = query.ageMax;
  if (ageMax != null && (age == null || age > ageMax)) return false;

  return true;
}

String _normalizeMarital(String? raw) {
  final value = raw?.trim();
  if (value == null || value.isEmpty) return '';
  return value.toUpperCase().replaceAll('-', '_');
}
