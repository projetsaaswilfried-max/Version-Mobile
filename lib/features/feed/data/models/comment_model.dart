import '../../../../core/parsing/json.dart';
import '../../domain/entities/post_comment.dart';

class CommentModel {
  const CommentModel._();

  static PostComment? fromJson(Map<String, dynamic> map) {
    final json = Json(map);
    final body =
        json.stringOrNull('content') ??
        json.stringOrNull('body') ??
        json.stringOrNull('comment') ??
        json.string('text');

    final id = json.stringOrNull('id') ?? json.intOrNull('id')?.toString();
    if (id == null) return null;

    final parent =
        json.stringOrNull('parent_comment_id') ??
        json.stringOrNull('parent_id') ??
        json.intOrNull('parent_comment_id')?.toString() ??
        json.intOrNull('parent_id')?.toString();

    return PostComment(
      id: id,
      body: body,
      authorName: _authorName(json),
      authorAvatarUrl: _authorAvatar(json),
      isVerified: _authorVerified(json),
      parentId: parent,
      createdAt: json.dateTime('created_at'),
    );
  }

  static Json? _author(Json json) {
    for (final key in ['author', 'profiles', 'profile']) {
      final nested = json.nested(key);
      if (nested != null) return nested;
      final items = json.list(key, (item) => item);
      if (items.isNotEmpty) return items.first;
    }
    return null;
  }

  static String _authorName(Json json) {
    final nested = _author(json);
    if (nested == null) return 'Membre Agapeo';
    final first = nested.stringOrNull('first_name');
    final last = nested.stringOrNull('last_name');
    final parts = [if (first != null) first, if (last != null) last];
    final name = parts.join(' ').trim();
    if (name.isNotEmpty) return name;
    return nested.stringOrNull('display_name') ?? 'Membre Agapeo';
  }

  static bool _authorVerified(Json json) {
    final nested = _author(json);
    if (nested == null) return false;
    return nested.string('photo_verification_status').toUpperCase() ==
        'VERIFIED';
  }

  static String? _authorAvatar(Json json) {
    final nested = _author(json);
    if (nested == null) return null;
    final direct = _httpUrl(
      nested.stringOrNull('avatar_url') ?? nested.stringOrNull('photo_url'),
    );
    if (direct != null) return direct;
    final photos = nested.list('profile_photos', (item) => item);
    if (photos.isEmpty) return null;
    Json chosen = photos.first;
    for (final photo in photos) {
      if (photo.boolValue('is_primary')) {
        chosen = photo;
        break;
      }
    }
    for (final key in [
      'url',
      'public_url',
      'selfie_storage_path',
      'storage_path',
      'path',
    ]) {
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
