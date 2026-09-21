import '../entities/post.dart';

String postShareText(Post post) {
  final title = post.title?.trim();
  if (title != null && title.isNotEmpty) return title;
  return post.body.trim();
}

/// Canonical web URL of a post. Unknown on mobile v1: share text only.
String? postShareUrl(Post post) => null;
