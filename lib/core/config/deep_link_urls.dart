/// Deep link redirect URL for Supabase Auth password recovery. Google
/// Sign-In is native (no browser, no deep link) - this is the only one left.
///
/// Must match Supabase Redirect URLs and host well-known files (ops checklist).
class DeepLinkUrls {
  const DeepLinkUrls._();

  static const reset = 'https://www.agapeo.love/auth/reset';
}
