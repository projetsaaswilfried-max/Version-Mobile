/// PostgREST embeds for `posts` / `post_comments` → `profiles`.
/// Always hint the FK (`!author_id`, `!user_id`). Unhinted `profiles(...)`
/// fails when several relationships exist between the two tables.
class FeedEmbedSelects {
  const FeedEmbedSelects._();

  static const posts = [
    '*, post_media(*), author:profiles!author_id(id, first_name, last_name, photo_verification_status, is_staff, profile_photos(storage_path, is_primary))',
    '*, post_media(*), author:profiles!posts_author_id_fkey(id, first_name, last_name, photo_verification_status, is_staff, profile_photos(storage_path, is_primary))',
    '*, post_media(*), author:profiles!author_id(id, first_name, last_name, photo_verification_status, is_staff)',
    '*, post_media(*), author:profiles!posts_author_id_fkey(id, first_name, last_name, photo_verification_status, is_staff)',
    '*, post_media(*)',
  ];

  static const comments = [
    'id, content, created_at, user_id, parent_comment_id, author:profiles!user_id(id, first_name, last_name, avatar_url, photo_verification_status, profile_photos(storage_path, selfie_storage_path, url, is_primary))',
    'id, content, created_at, user_id, parent_comment_id, author:profiles!post_comments_user_id_fkey(id, first_name, last_name, avatar_url, photo_verification_status, profile_photos(storage_path, selfie_storage_path, url, is_primary))',
    'id, content, created_at, author_id, parent_comment_id, author:profiles!author_id(id, first_name, last_name, avatar_url, photo_verification_status, profile_photos(storage_path, selfie_storage_path, url, is_primary))',
    '*, author:profiles!user_id(id, first_name, last_name, avatar_url, photo_verification_status, profile_photos(storage_path, selfie_storage_path, url, is_primary))',
    '*, author:profiles!author_id(id, first_name, last_name, avatar_url, photo_verification_status, profile_photos(storage_path, selfie_storage_path, url, is_primary))',
    'id, content, created_at, user_id, parent_comment_id, author:profiles!user_id(id, first_name, last_name, avatar_url, photo_verification_status)',
    'id, content, created_at, user_id, parent_comment_id, author:profiles!post_comments_user_id_fkey(id, first_name, last_name, avatar_url, photo_verification_status)',
    'id, content, created_at, author_id, parent_comment_id, author:profiles!author_id(id, first_name, last_name, avatar_url, photo_verification_status)',
    '*, author:profiles!user_id(id, first_name, last_name, avatar_url, photo_verification_status)',
    '*, author:profiles!author_id(id, first_name, last_name, avatar_url, photo_verification_status)',
    'id, content, body, created_at, user_id, parent_comment_id',
    '*',
  ];
}
