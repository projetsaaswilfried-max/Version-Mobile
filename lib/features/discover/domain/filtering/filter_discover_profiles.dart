import '../entities/discover_profile.dart';
import '../entities/discover_query.dart';

List<DiscoverProfile> filterDiscoverProfiles(
  List<DiscoverProfile> profiles,
  DiscoverQuery query,
) {
  if (query.isEmpty) return profiles;
  return profiles.where((profile) => _matches(profile, query)).toList();
}

bool _matches(DiscoverProfile profile, DiscoverQuery query) {
  final search = query.search?.trim();
  if (search != null && search.isNotEmpty) {
    final needle = search.toLowerCase();
    final name = profile.displayName.toLowerCase();
    final city = (profile.city ?? '').toLowerCase();
    if (!name.contains(needle) && !city.contains(needle)) return false;
  }

  final cityFilter = query.city?.trim();
  if (cityFilter != null && cityFilter.isNotEmpty) {
    final city = (profile.city ?? '').toLowerCase();
    if (!city.contains(cityFilter.toLowerCase())) return false;
  }

  final denomination = query.denomination?.trim();
  if (denomination != null && denomination.isNotEmpty) {
    final confession = (profile.traits.confession ?? '').toLowerCase();
    if (!confession.contains(denomination.toLowerCase())) return false;
  }

  // Profession : pas sur DiscoverProfile / DiscoverProfileDetail. Ignorée V1.
  return true;
}
