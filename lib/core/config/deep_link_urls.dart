/// Deep link redirect URLs for Supabase Auth (OAuth + password recovery).
///
/// Must match Supabase Redirect URLs and host well-known files (ops checklist).
class DeepLinkUrls {
  const DeepLinkUrls._();

  static const callback = 'https://www.agapeo.love/auth/callback';
  static const reset = 'https://www.agapeo.love/auth/reset';
}
