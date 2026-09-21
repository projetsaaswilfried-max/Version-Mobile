String? youtubeVideoId(String? raw) {
  if (raw == null) return null;
  final value = raw.trim();
  if (value.isEmpty) return null;
  if (RegExp(r'^[\w-]{11}$').hasMatch(value)) return value;

  final uri = Uri.tryParse(value);
  if (uri == null || uri.host.isEmpty) return null;

  final host = uri.host.replaceFirst(RegExp(r'^www\.'), '');
  if (host == 'youtu.be' && uri.pathSegments.isNotEmpty) {
    return uri.pathSegments.first;
  }
  if (!host.endsWith('youtube.com') && !host.endsWith('youtube-nocookie.com')) {
    return null;
  }
  final fromQuery = uri.queryParameters['v'];
  if (fromQuery != null && fromQuery.isNotEmpty) return fromQuery;

  final segments = uri.pathSegments;
  for (var i = 0; i < segments.length - 1; i++) {
    if (segments[i] == 'embed' ||
        segments[i] == 'shorts' ||
        segments[i] == 'live' ||
        segments[i] == 'v') {
      return segments[i + 1];
    }
  }
  return null;
}

String youtubeWatchUrl(String videoId) =>
    'https://www.youtube.com/watch?v=$videoId';

String youtubeThumbnailUrl(String videoId) =>
    'https://img.youtube.com/vi/$videoId/hqdefault.jpg';

String youtubeEmbedUrl(String videoId) =>
    'https://www.youtube-nocookie.com/embed/$videoId?playsinline=1&rel=0';
