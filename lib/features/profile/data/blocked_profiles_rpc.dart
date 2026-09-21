import '../domain/entities/account_person.dart';

/// Parse la réponse de `get_my_blocked_profiles` (forme variable côté SQL).
List<AccountPerson> parseBlockedProfilesRpc(Object? raw) {
  final rows = _asList(raw);
  final out = <AccountPerson>[];
  for (final row in rows) {
    final person = _personFromRow(row);
    if (person != null) out.add(person);
  }
  return out;
}

/// Conserve l'ordre des ids : profil hydraté si dispo, sinon placeholder
/// (RLS peut masquer les `profiles` des comptes bloqués).
List<AccountPerson> mergeBlockedPeople({
  required List<String> ids,
  required List<AccountPerson> hydrated,
}) {
  final byId = {for (final person in hydrated) person.id: person};
  return [
    for (final id in ids)
      byId[id] ??
          AccountPerson(id: id, displayName: 'Profil bloqué'),
  ];
}

List<Object?> _asList(Object? raw) {
  if (raw == null) return const [];
  if (raw is List) return raw;
  if (raw is Map) {
    for (final key in const ['data', 'profiles', 'rows', 'result']) {
      final value = raw[key];
      if (value is List) return value;
    }
  }
  return const [];
}

AccountPerson? _personFromRow(Object? row) {
  if (row is String) {
    final id = row.trim();
    if (id.isEmpty) return null;
    return AccountPerson(id: id, displayName: 'Profil bloqué');
  }
  if (row is! Map) return null;
  final map = Map<String, dynamic>.from(row);

  final nested = map['profile'] ?? map['profiles'] ?? map['blocked_profile'];
  final source = nested is Map
      ? <String, dynamic>{...map, ...Map<String, dynamic>.from(nested)}
      : map;

  final id = _firstString(source, const [
    'id',
    'blocked_id',
    'profile_id',
    'user_id',
    'blocked_profile_id',
  ]);
  if (id == null || id.isEmpty) return null;

  final first = _firstString(source, const ['first_name', 'firstname']);
  final last = _firstString(source, const ['last_name', 'lastname']);
  final composed = [
    if (first != null && first.isNotEmpty) first,
    if (last != null && last.isNotEmpty) last,
  ].join(' ').trim();
  final display =
      _firstString(source, const [
        'display_name',
        'full_name',
        'name',
      ]) ??
      (composed.isEmpty ? null : composed);

  final photo = _firstString(source, const [
    'photo_url',
    'avatar_url',
    'avatar',
    'public_url',
  ]);
  final city = _firstString(source, const ['city']);

  return AccountPerson(
    id: id,
    displayName: (display == null || display.isEmpty)
        ? 'Profil bloqué'
        : display,
    photoUrl: photo,
    city: city,
  );
}

String? _firstString(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final value = map[key];
    if (value is String && value.trim().isNotEmpty) return value.trim();
    if (value != null && value is! Map && value is! List) {
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
  }
  return null;
}
