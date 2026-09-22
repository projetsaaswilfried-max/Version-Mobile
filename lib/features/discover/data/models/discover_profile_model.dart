import '../../../../core/parsing/json.dart';
import '../../domain/entities/discover_profile.dart';
import '../../domain/entities/visitor_context.dart';
import '../../domain/scoring/compatibility_traits.dart';

class DiscoverProfileModel {
  const DiscoverProfileModel._();

  static DiscoverProfile? fromJson(
    Map<String, dynamic> map, {
    required CompatibilityTraits visitorTraits,
    required bool revealIdentity,
    DateTime Function()? now,
  }) {
    // visitorTraits / revealIdentity: masquage et score sont dans GetDiscoverPage.
    final json = Json(map);
    final id = json.stringOrNull('id') ?? json.intOrNull('id')?.toString();
    if (id == null) return null;

    final age = _ageFromBirth(
      json.dateTime('birth_date') ?? _dateOnly(json),
      now,
    );
    final traits = _traits(json, age);
    final photoUrl = _httpPhoto(json);
    // Une entrée profile_photos suffit pour la complétude §7 même si l'URL
    // publique n'est pas encore résolue (carte avec placeholder).
    final hasPhoto = photoUrl != null || _hasPhotoRecord(json);

    return DiscoverProfile(
      id: id,
      displayName: _displayName(json),
      age: age,
      city: json.stringOrNull('city'),
      profession: json.stringOrNull('profession'),
      photoUrl: photoUrl,
      isVerified: _isVerified(json),
      gender: json.stringOrNull('gender'),
      isStaff: json.boolValue('is_staff'),
      isMatched: json.boolValue('is_matched'),
      isComplete: _isComplete(json, hasPhoto: hasPhoto),
      traits: traits,
    );
  }

  static VisitorContext? visitorFromJson({
    required Map<String, dynamic> profile,
    required String subscriptionStatus,
    DateTime Function()? now,
  }) {
    final json = Json(profile);
    final id = json.stringOrNull('id') ?? json.intOrNull('id')?.toString();
    if (id == null) return null;
    final age = _ageFromBirth(
      json.dateTime('birth_date') ?? _dateOnly(json),
      now,
    );
    return VisitorContext(
      id: id,
      gender: json.stringOrNull('gender'),
      isVerified: _isVerified(json),
      subscriptionStatus: subscriptionStatus.trim().isEmpty
          ? 'FREE'
          : subscriptionStatus,
      traits: _traits(json, age),
      isStaff: json.boolValue('is_staff'),
    );
  }

  static String _displayName(Json json) {
    final first = json.stringOrNull('first_name');
    final last = json.stringOrNull('last_name');
    final parts = [if (first != null) first, if (last != null) last];
    final joined = parts.join(' ').trim();
    if (joined.isNotEmpty) return joined;
    return json.stringOrNull('display_name') ?? '';
  }

  static bool _isVerified(Json json) {
    return json.string('photo_verification_status').toUpperCase() == 'VERIFIED';
  }

  static bool _isComplete(Json json, {required bool hasPhoto}) {
    return json.stringOrNull('gender') != null &&
        (json.dateTime('birth_date') ?? _dateOnly(json)) != null &&
        json.stringOrNull('country') != null &&
        hasPhoto &&
        json.stringOrNull('church_denomination') != null &&
        json.stringOrNull('why_marriage') != null;
  }

  static CompatibilityTraits _traits(Json json, int? age) {
    return CompatibilityTraits(
      confession: json.stringOrNull('church_denomination'),
      spiritualEngagement: json.stringOrNull('spiritual_engagement'),
      values: _stringList(json, const ['values', 'core_values']),
      hobbies: _stringList(json, const ['hobbies', 'leisure']),
      country: json.stringOrNull('country'),
      acceptedCountries: _stringList(json, const [
        'accepted_countries',
        'accepted_country',
      ]),
      age: age,
      acceptedAgeMin: json.intOrNull('accepted_age_min'),
      acceptedAgeMax: json.intOrNull('accepted_age_max'),
      maritalStatus: json.stringOrNull('marital_status'),
      acceptedMarital: _stringList(json, const [
        'accepted_marital',
        'accepted_marital_status',
      ]),
    );
  }

  static List<String> _stringList(Json json, List<String> keys) {
    for (final key in keys) {
      final fromJson = json.stringList(key);
      if (fromJson.isNotEmpty) return fromJson;
    }
    return const [];
  }

  static DateTime? _dateOnly(Json json) {
    final raw = json.stringOrNull('birth_date');
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  static int? _ageFromBirth(DateTime? birth, DateTime Function()? now) {
    if (birth == null) return null;
    final today = (now ?? DateTime.now)().toUtc();
    var age = today.year - birth.year;
    final hadBirthday =
        today.month > birth.month ||
        (today.month == birth.month && today.day >= birth.day);
    if (!hadBirthday) age -= 1;
    return age < 0 ? 0 : age;
  }

  static bool _hasPhotoRecord(Json json) {
    return json.list('profile_photos', (item) => item).isNotEmpty;
  }

  static String? _httpPhoto(Json json) {
    final direct = _httpUrl(
      json.stringOrNull('photo_url') ?? json.stringOrNull('avatar_url'),
    );
    if (direct != null) return direct;
    final photos = json.list('profile_photos', (item) => item);
    if (photos.isEmpty) return null;
    Json chosen = photos.first;
    for (final photo in photos) {
      if (photo.boolValue('is_primary')) {
        chosen = photo;
        break;
      }
    }
    for (final key in ['url', 'public_url', 'storage_path', 'path']) {
      final value = _httpUrl(chosen.stringOrNull(key));
      if (value != null) return value;
    }
    return null;
  }

  static String? _httpUrl(String? value) {
    if (value == null) return null;
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    return null;
  }
}
