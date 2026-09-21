Map<String, dynamic> normalizeCommentRow(Map<String, dynamic> row) {
  final copy = Map<String, dynamic>.from(row);
  final author = _authorMap(copy);
  if (author != null) {
    copy['author'] = author;
  }
  return copy;
}

List<String> commentAuthorIds(List<Map<String, dynamic>> rows) {
  final ids = <String>[];
  for (final row in rows) {
    final id = _authorId(normalizeCommentRow(row));
    if (id != null && !ids.contains(id)) ids.add(id);
  }
  return ids;
}

List<String> missingCommentAuthorIds(List<Map<String, dynamic>> rows) {
  final ids = <String>[];
  for (final row in rows) {
    final normalized = normalizeCommentRow(row);
    if (_hasAuthorName(normalized['author'])) continue;
    final id = _authorId(normalized);
    if (id != null && !ids.contains(id)) ids.add(id);
  }
  return ids;
}

List<String> missingCommentVerificationIds(List<Map<String, dynamic>> rows) {
  final ids = <String>[];
  for (final row in rows) {
    final normalized = normalizeCommentRow(row);
    if (_hasVerificationStatus(normalized['author'])) continue;
    final id = _authorId(normalized);
    if (id != null && !ids.contains(id)) ids.add(id);
  }
  return ids;
}

List<String> missingCommentAvatarIds(List<Map<String, dynamic>> rows) {
  final ids = <String>[];
  for (final row in rows) {
    final normalized = normalizeCommentRow(row);
    if (_hasAvatar(normalized['author'])) continue;
    final id = _authorId(normalized);
    if (id != null && !ids.contains(id)) ids.add(id);
  }
  return ids;
}

List<Map<String, dynamic>> mergeCommentAuthors(
  List<Map<String, dynamic>> comments,
  List<Map<String, dynamic>> profiles,
) {
  final byId = <String, Map<String, dynamic>>{
    for (final profile in profiles)
      if (profile['id'] != null)
        '${profile['id']}': Map<String, dynamic>.from(profile),
  };
  return [
    for (final row in comments) _mergeOne(normalizeCommentRow(row), byId),
  ];
}

List<Map<String, dynamic>> mergeCommentPhotos(
  List<Map<String, dynamic>> comments,
  List<Map<String, dynamic>> photos,
) {
  final byProfile = <String, List<Map<String, dynamic>>>{};
  for (final photo in photos) {
    final id = photo['profile_id'] ?? photo['user_id'] ?? photo['author_id'];
    if (id == null) continue;
    byProfile
        .putIfAbsent('$id', () => [])
        .add(Map<String, dynamic>.from(photo));
  }
  return [
    for (final row in comments)
      _mergePhotos(normalizeCommentRow(row), byProfile),
  ];
}

Map<String, dynamic> _mergeOne(
  Map<String, dynamic> row,
  Map<String, Map<String, dynamic>> profiles,
) {
  final id = _authorId(row);
  final profile = id == null ? null : profiles[id];
  if (profile == null) return row;
  final author = row['author'] is Map
      ? Map<String, dynamic>.from(row['author'] as Map)
      : <String, dynamic>{};
  for (final entry in profile.entries) {
    final current = author[entry.key];
    final empty =
        current == null || (current is String && current.trim().isEmpty);
    if (empty && entry.value != null) {
      author[entry.key] = entry.value;
    }
  }
  return {...row, 'author': author};
}

Map<String, dynamic> _mergePhotos(
  Map<String, dynamic> row,
  Map<String, List<Map<String, dynamic>>> photos,
) {
  if (_hasAvatar(row['author'])) return row;
  final id = _authorId(row);
  final list = id == null ? null : photos[id];
  if (list == null || list.isEmpty) return row;
  final author = row['author'] is Map
      ? Map<String, dynamic>.from(row['author'] as Map)
      : <String, dynamic>{'id': id};
  author['profile_photos'] = list;
  return {...row, 'author': author};
}

bool _hasVerificationStatus(Object? author) {
  if (author is! Map) return false;
  final value = author['photo_verification_status'];
  return value is String && value.trim().isNotEmpty;
}

bool _hasAuthorName(Object? author) {
  if (author is! Map) return false;
  final map = Map<String, dynamic>.from(author);
  for (final key in ['first_name', 'last_name', 'display_name']) {
    final value = map[key];
    if (value is String && value.trim().isNotEmpty) return true;
  }
  return false;
}

bool _hasAvatar(Object? author) {
  if (author is! Map) return false;
  final map = Map<String, dynamic>.from(author);
  for (final key in ['avatar_url', 'photo_url']) {
    if (_httpUrl(map[key]) != null) return true;
  }
  final photos = map['profile_photos'];
  if (photos is! List) return false;
  for (final photo in photos.whereType<Map>()) {
    for (final key in ['url', 'public_url']) {
      if (_httpUrl(photo[key]) != null) return true;
    }
  }
  return false;
}

String? _httpUrl(Object? value) {
  if (value is! String) return null;
  final trimmed = value.trim();
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return trimmed;
  }
  return null;
}

String? _authorId(Map<String, dynamic> row) {
  for (final key in ['user_id', 'author_id', 'profile_id']) {
    final value = row[key];
    if (value != null && '$value'.isNotEmpty) return '$value';
  }
  final author = row['author'];
  if (author is Map && author['id'] != null) return '${author['id']}';
  return null;
}

Map<String, dynamic>? _authorMap(Map<String, dynamic> row) {
  final value = row['author'] ?? row['profiles'] ?? row['profile'];
  if (value is Map) return Map<String, dynamic>.from(value);
  if (value is List && value.isNotEmpty && value.first is Map) {
    return Map<String, dynamic>.from(value.first as Map);
  }
  return null;
}
