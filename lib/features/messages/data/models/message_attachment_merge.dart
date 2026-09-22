/// Fusionne une ligne `message_attachments` dans le row `messages`.
void mergeAttachmentIntoMessage(
  Map<String, dynamic> message, {
  required Map<String, dynamic> attachment,
  String? resolvedUrl,
}) {
  final url = resolvedUrl?.trim();
  if (url != null && url.isNotEmpty) {
    message['media_url'] = url;
  }
  final fileName = attachment['file_name'];
  if (fileName is String && fileName.trim().isNotEmpty) {
    message['file_name'] = fileName.trim();
  }
  final duration = attachment['duration_seconds'];
  if (duration is num) {
    message['duration_seconds'] = duration.toInt();
  }
  final mime = attachment['mime_type'];
  if (mime is String && mime.trim().isNotEmpty) {
    message['mime_type'] = mime.trim();
  }
  final type = attachment['type'];
  if (type is String && type.trim().isNotEmpty) {
    final current = (message['type'] as String?)?.trim().toUpperCase() ?? '';
    if (current.isEmpty || current == 'TEXT') {
      message['type'] = type.trim().toUpperCase();
    }
  }
}

/// Chemin Storage à signer. On privilégie toujours `storage_path` : la
/// colonne `url` est souvent une URL publique/expirée du bucket privé, que
/// le lecteur iOS n'arrive jamais à ouvrir.
String? attachmentObjectPath(Map<String, dynamic> attachment) {
  final storagePath = _asNonEmpty(attachment['storage_path']);
  if (storagePath != null) {
    if (_isHttp(storagePath)) {
      return objectPathFromStorageUrl(storagePath) ?? _stripBucketPrefix(storagePath);
    }
    return _stripBucketPrefix(storagePath);
  }
  final url = _asNonEmpty(attachment['url']);
  if (url == null) return null;
  if (_isHttp(url)) return objectPathFromStorageUrl(url);
  return _stripBucketPrefix(url);
}

String? attachmentHttpUrl(Map<String, dynamic> attachment) {
  final url = _asNonEmpty(attachment['url']);
  if (url != null && _isHttp(url) && _looksLikeSignedUrl(url)) return url;
  final path = _asNonEmpty(attachment['storage_path']);
  if (path != null && _isHttp(path) && _looksLikeSignedUrl(path)) return path;
  return null;
}

String? objectPathFromStorageUrl(String url) {
  const markers = [
    '/object/sign/message-attachments/',
    '/object/public/message-attachments/',
    '/object/authenticated/message-attachments/',
  ];
  for (final marker in markers) {
    final index = url.indexOf(marker);
    if (index < 0) continue;
    var path = url.substring(index + marker.length);
    final query = path.indexOf('?');
    if (query >= 0) path = path.substring(0, query);
    return Uri.decodeComponent(path);
  }
  return null;
}

bool _looksLikeSignedUrl(String url) => url.contains('/object/sign/');

String _stripBucketPrefix(String path) {
  var value = path.startsWith('/') ? path.substring(1) : path;
  const prefix = 'message-attachments/';
  if (value.startsWith(prefix)) {
    value = value.substring(prefix.length);
  }
  return value;
}

bool _isHttp(String value) =>
    value.startsWith('http://') || value.startsWith('https://');

String? _asNonEmpty(Object? value) {
  if (value is! String) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
