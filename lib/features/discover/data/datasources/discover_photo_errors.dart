bool isOversizedPhotoChunkError({
  required String message,
  String? code,
  Object? details,
}) {
  final normalizedCode = (code ?? '').toUpperCase();
  if (normalizedCode == '42501' || normalizedCode == 'PGRST301') {
    return false;
  }
  if (normalizedCode == '414' || normalizedCode == '413') return true;
  final all = '$message ${details ?? ''} $normalizedCode'.toLowerCase();
  return all.contains('too long') ||
      all.contains('request uri') ||
      all.contains('payload too large');
}
