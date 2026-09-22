/// Libellé d'aperçu liste pour un message média sans texte.
String? mediaTypePreviewLabel(String? type) {
  return switch (type?.trim().toUpperCase()) {
    'IMAGE' => 'Photo',
    'VOICE' || 'AUDIO' => 'Audio',
    'VIDEO' => 'Vidéo',
    'DOCUMENT' => 'Document',
    _ => null,
  };
}

/// Aperçu d'une ligne de liste : le texte s'affiche tel quel, un fichier
/// affiche le type (Photo / Audio / …), jamais le nom de fichier.
String? conversationLastMessagePreview({
  required String? type,
  String? content,
  String? fileName,
}) {
  final fromType = mediaTypePreviewLabel(type);
  if (fromType != null) return fromType;

  final inferred = mediaTypeFromFileName(fileName) ??
      mediaTypeFromFileName(content);
  final fromName = mediaTypePreviewLabel(inferred);
  if (fromName != null) return fromName;

  final text = content?.trim();
  if (text == null || text.isEmpty) return null;
  return text;
}

String? mediaTypeFromFileName(String? name) {
  final value = name?.trim().toLowerCase() ?? '';
  if (value.isEmpty) return null;
  const images = ['.png', '.jpg', '.jpeg', '.gif', '.webp', '.heic', '.heif'];
  const audio = ['.m4a', '.mp3', '.aac', '.wav', '.caf', '.webm', '.ogg'];
  const video = ['.mp4', '.mov', '.m4v'];
  const docs = ['.pdf', '.doc', '.docx', '.xls', '.xlsx', '.txt', '.zip'];
  if (images.any(value.endsWith)) return 'IMAGE';
  if (audio.any(value.endsWith)) return 'VOICE';
  if (video.any(value.endsWith)) return 'VIDEO';
  if (docs.any(value.endsWith)) return 'DOCUMENT';
  return null;
}
