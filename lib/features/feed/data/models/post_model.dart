import '../../../../core/parsing/json.dart';
import '../../domain/entities/post.dart';
import '../../domain/entities/post_author.dart';
import '../../domain/entities/post_media_type.dart';
import '../../domain/mapping/post_db_mapping.dart';
import '../../domain/mapping/youtube.dart';

class PostModel {
  const PostModel._();

  static Post? fromJson(
    Map<String, dynamic> map, {
    bool includePersonal = false,
  }) {
    final json = Json(map);
    final type = json.string('post_type').toUpperCase();
    if (includePersonal) {
      if (type != 'PERSONAL') return null;
    } else if (type == 'PERSONAL') {
      return null;
    }

    final id = json.stringOrNull('id');
    if (id == null) return null;

    final media = json.list('post_media', (item) => item);
    final firstMedia = media.isEmpty ? null : media.first;
    final mediaType = mediaTypeFromDb(
      json.stringOrNull('media_type') ??
          json.stringOrNull('type') ??
          firstMedia?.stringOrNull('media_type') ??
          firstMedia?.stringOrNull('type'),
    );

    final rawUrls = <String>[
      for (final item in media)
        if (_mediaUrl(item) != null) _mediaUrl(item)!,
    ];
    // Un post vidéo peut avoir plusieurs lignes post_media (le fichier vidéo
    // + une vignette générée) sans ordre garanti — ne jamais prendre une URL
    // qui ressemble à une image comme source à lire (ExoPlayer plante sinon).
    final playableUrls = mediaType == PostMediaType.video
        ? rawUrls.where((url) => !_looksLikeImage(url)).toList()
        : rawUrls;
    final thumbnailFromMedia = mediaType == PostMediaType.video
        ? _firstMatching(rawUrls, _looksLikeImage)
        : null;
    final urls = playableUrls.isNotEmpty ? playableUrls : rawUrls;
    // Un post VIDEO natif (non YouTube) n'a souvent aucune ligne post_media :
    // le fichier vit directement dans posts.video_url (avec sa vignette dans
    // posts.video_thumbnail) - à ne jamais confondre avec le champ générique
    // `url` ci-dessous, qui n'existe même pas sur cette table pour ce cas.
    final nativeVideoUrl = mediaType == PostMediaType.video
        ? json.stringOrNull('video_url')
        : null;
    final imageUrl = urls.isNotEmpty
        ? urls.first
        : nativeVideoUrl ??
              _firstNonEmpty(json, const ['url', 'image_url', 'cover_url']);

    final youtubeRaw =
        _firstNonEmpty(json, const [
          'video_url',
          'youtube_url',
          'youtube_id',
          'external_url',
        ]) ??
        _firstNonEmpty(firstMedia ?? json, const [
          'youtube_url',
          'youtube_id',
          'external_url',
          'video_url',
        ]);
    final youtubeId = youtubeVideoId(
      youtubeRaw ?? (mediaType == PostMediaType.youtube ? imageUrl : null),
    );
    final youtubeUrl = youtubeId == null ? null : youtubeWatchUrl(youtubeId);

    final thumbnailUrl =
        json.stringOrNull('video_thumbnail') ??
        _firstNonEmpty(firstMedia ?? json, const [
          'thumbnail_url',
          'poster_url',
          'thumbnail_path',
        ]) ??
        thumbnailFromMedia ??
        (youtubeId != null ? youtubeThumbnailUrl(youtubeId) : null) ??
        ((mediaType == PostMediaType.video ||
                mediaType == PostMediaType.youtube)
            ? imageUrl
            : null);

    return Post(
      id: id,
      author: _author(json),
      category: categoryFromDb(json.stringOrNull('category')),
      title: json.stringOrNull('title') ?? json.stringOrNull('headline'),
      body:
          json.stringOrNull('content') ??
          json.stringOrNull('body') ??
          json.string('text'),
      mediaType: mediaType,
      imageUrl: imageUrl,
      thumbnailUrl: thumbnailUrl,
      mediaUrls: urls.isEmpty && imageUrl != null ? [imageUrl] : urls,
      galleryCount: mediaType == PostMediaType.gallery && urls.isEmpty
          ? 1
          : urls.length,
      quoteAttribution:
          json.stringOrNull('quote_author') ??
          json.stringOrNull('quote_attribution') ??
          firstMedia?.stringOrNull('attribution'),
      youtubeUrl: youtubeUrl,
      isPinned: json.boolValue('is_pinned') || json.boolValue('pinned'),
      likeCount: _count(json, const ['likes_count', 'like_count']),
      commentCount: _count(json, const ['comments_count', 'comment_count']),
      shareCount: _count(json, const ['shares_count', 'share_count']),
      viewCount: _count(json, const ['views_count', 'view_count']),
      createdAt: json.dateTime('created_at') ?? json.dateTime('published_at'),
    );
  }

  static PostAuthor _author(Json json) {
    final nested =
        json.nested('author') ??
        json.nested('profiles') ??
        json.nested('profile');
    if (nested == null) {
      return const PostAuthor(displayName: 'Équipe Agapeo');
    }
    final first = nested.stringOrNull('first_name');
    final last = nested.stringOrNull('last_name');
    final parts = [if (first != null) first, if (last != null) last];
    final name = parts.join(' ').trim();
    final verified =
        nested.string('photo_verification_status').toUpperCase() == 'VERIFIED';
    return PostAuthor(
      id: nested.stringOrNull('id'),
      displayName: name.isEmpty ? 'Équipe Agapeo' : name,
      avatarUrl: _authorAvatar(nested),
      isVerified: verified,
    );
  }

  static String? _authorAvatar(Json nested) {
    final direct =
        nested.stringOrNull('avatar_url') ?? nested.stringOrNull('photo_url');
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
    return _firstNonEmpty(chosen, const [
      'url',
      'public_url',
      'storage_path',
      'path',
    ]);
  }

  static const _imageExtensions = {
    'jpg',
    'jpeg',
    'png',
    'webp',
    'gif',
    'bmp',
    'heic',
    'heif',
  };

  static bool _looksLikeImage(String url) {
    final path = Uri.tryParse(url)?.path ?? url;
    final dot = path.lastIndexOf('.');
    if (dot == -1 || dot == path.length - 1) return false;
    return _imageExtensions.contains(path.substring(dot + 1).toLowerCase());
  }

  static String? _firstMatching(
    List<String> values,
    bool Function(String) test,
  ) {
    for (final value in values) {
      if (test(value)) return value;
    }
    return null;
  }

  static String? _mediaUrl(Json item) {
    return _firstNonEmpty(item, const [
      'url',
      'public_url',
      'storage_path',
      'path',
      'src',
    ]);
  }

  static String? _firstNonEmpty(Json json, List<String> keys) {
    for (final key in keys) {
      final value = json.stringOrNull(key);
      if (value != null) return value;
    }
    return null;
  }

  static int _count(Json json, List<String> keys) {
    for (final key in keys) {
      final value = json.intOrNull(key);
      if (value != null) return value;
    }
    return 0;
  }
}
