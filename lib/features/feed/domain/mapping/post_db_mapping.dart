import '../entities/post_category.dart';
import '../entities/post_media_type.dart';

PostCategory? categoryFromDb(String? raw) {
  return switch (raw?.toUpperCase()) {
    'TEACHING' => PostCategory.teaching,
    'TESTIMONY' => PostCategory.testimony,
    'WORKSHOP' => PostCategory.workshop,
    'ADVICE' => PostCategory.advice,
    'ANNOUNCEMENT' => PostCategory.announcement,
    'QUOTE' => PostCategory.quote,
    'VERSE' => PostCategory.verse,
    'NEWS' => PostCategory.news,
    _ => null,
  };
}

String categoryToDb(PostCategory category) {
  return switch (category) {
    PostCategory.teaching => 'TEACHING',
    PostCategory.testimony => 'TESTIMONY',
    PostCategory.workshop => 'WORKSHOP',
    PostCategory.advice => 'ADVICE',
    PostCategory.announcement => 'ANNOUNCEMENT',
    PostCategory.quote => 'QUOTE',
    PostCategory.verse => 'VERSE',
    PostCategory.news => 'NEWS',
  };
}

PostMediaType mediaTypeFromDb(String? raw) {
  return switch (raw?.toUpperCase()) {
    'IMAGE' => PostMediaType.image,
    'GALLERY' => PostMediaType.gallery,
    'VIDEO' => PostMediaType.video,
    'QUOTE_CARD' => PostMediaType.quoteCard,
    'TEXT_ONLY' => PostMediaType.textOnly,
    'YOUTUBE' => PostMediaType.youtube,
    _ => PostMediaType.textOnly,
  };
}

String mediaTypeToDb(PostMediaType type) {
  return switch (type) {
    PostMediaType.image => 'IMAGE',
    PostMediaType.gallery => 'GALLERY',
    PostMediaType.video => 'VIDEO',
    PostMediaType.quoteCard => 'QUOTE_CARD',
    PostMediaType.textOnly => 'TEXT_ONLY',
    PostMediaType.youtube => 'YOUTUBE',
  };
}
