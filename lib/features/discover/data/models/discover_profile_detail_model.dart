import '../../../../core/parsing/json.dart';
import '../../domain/entities/discover_profile_detail.dart';
import '../../domain/scoring/compatibility_traits.dart';
import 'discover_profile_model.dart';

class DiscoverProfileDetailModel {
  const DiscoverProfileDetailModel._();

  static DiscoverProfileDetail? fromJson(
    Map<String, dynamic> map, {
    DateTime Function()? now,
    int score = 0,
  }) {
    final card = DiscoverProfileModel.fromJson(
      map,
      visitorTraits: const CompatibilityTraits(),
      revealIdentity: true,
      now: now,
    );
    if (card == null) return null;

    final json = Json(map);
    return DiscoverProfileDetail(
      id: card.id,
      displayName: card.displayName,
      age: card.age,
      city: card.city,
      country: card.traits.country ?? json.stringOrNull('country'),
      gender: card.gender,
      profession: json.stringOrNull('profession'),
      bio: json.stringOrNull('bio'),
      heightCm:
          json.intOrNull('height_cm') ??
          json.intOrNull('height') ??
          json.intOrNull('size_cm'),
      maritalStatus: card.traits.maritalStatus,
      photoUrls: _allHttpPhotos(json),
      isVerified: card.isVerified,
      score: score,
      confession: card.traits.confession,
      spiritualEngagement: card.traits.spiritualEngagement,
      whyMarriage: json.stringOrNull('why_marriage'),
      verse: _firstString(json, const [
        'favorite_verse',
        'bible_verse',
        'preferred_verse',
        'verse',
      ]),
      testimony: json.stringOrNull('testimony'),
      values: card.traits.values,
      hobbies: card.traits.hobbies,
      qualities: _stringList(json, const ['qualities', 'personal_qualities']),
    );
  }

  static String? _firstString(Json json, List<String> keys) {
    for (final key in keys) {
      final value = json.stringOrNull(key)?.trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  static List<String> _stringList(Json json, List<String> keys) {
    for (final key in keys) {
      final fromJson = json.stringList(key);
      if (fromJson.isNotEmpty) return fromJson;
    }
    return const [];
  }

  static List<String> _allHttpPhotos(Json json) {
    final urls = <String>[];

    void add(String? value) {
      if (value == null) return;
      if (!value.startsWith('http://') && !value.startsWith('https://')) {
        return;
      }
      if (!urls.contains(value)) urls.add(value);
    }

    void addFromPhoto(Json photo) {
      for (final key in ['url', 'public_url', 'storage_path', 'path']) {
        final value = photo.stringOrNull(key);
        if (value != null &&
            (value.startsWith('http://') || value.startsWith('https://'))) {
          add(value);
          return;
        }
      }
    }

    final photos = json.list('profile_photos', (item) => item);
    for (final photo in photos) {
      if (photo.boolValue('is_primary')) addFromPhoto(photo);
    }
    for (final photo in photos) {
      if (!photo.boolValue('is_primary')) addFromPhoto(photo);
    }
    add(json.stringOrNull('photo_url'));
    add(json.stringOrNull('avatar_url'));
    return urls;
  }
}
