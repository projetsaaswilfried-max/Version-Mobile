/// Noms des buckets Supabase Storage.
///
/// PRD §21 : `avatars`, `post-media` (publics) ;
/// `message-attachments`, `support-attachments`, `verification-selfies` (privés).
///
/// Photos de profil et d'onboarding : alignées sur `avatars` (le bucket
/// `profile-photos` n'existe pas côté Supabase — voir decisions.md V4).
class AppStorageBuckets {
  const AppStorageBuckets._();

  static const avatars = 'avatars';
  static const postMedia = 'post-media';
  static const messageAttachments = 'message-attachments';
}
