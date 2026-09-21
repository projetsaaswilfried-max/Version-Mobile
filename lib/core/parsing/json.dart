/// Defensive wrapper around a JSON map, used by `data/models` in their
/// `fromJson` constructors. Supabase/Postgrest payloads are dynamically
/// typed at the edges (numbers that arrive as strings, nullable columns,
/// enum values as raw strings) — every read here tolerates the wrong
/// shape instead of throwing, and falls back instead.
class Json {
  const Json(this._map);

  final Map<String, dynamic> _map;

  Object? _raw(String key) => _map[key];

  String string(String key, {String fallback = ''}) {
    final value = _raw(key);
    if (value is String) return value;
    if (value == null) return fallback;
    return value.toString();
  }

  String? stringOrNull(String key) {
    final value = _raw(key);
    if (value is String && value.isNotEmpty) return value;
    return null;
  }

  int intValue(String key, {int fallback = 0}) {
    return intOrNull(key) ?? fallback;
  }

  /// Returns null if the key is missing, null, or not a number.
  int? intOrNull(String key) {
    if (!_map.containsKey(key)) return null;
    final value = _raw(key);
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  double doubleValue(String key, {double fallback = 0}) {
    final value = _raw(key);
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  bool boolValue(String key, {bool fallback = false}) {
    final value = _raw(key);
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    return fallback;
  }

  DateTime? dateTime(String key) {
    final value = _raw(key);
    if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
    return null;
  }

  List<T> list<T>(String key, T Function(Json item) mapper) {
    final value = _raw(key);
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((item) => mapper(Json(Map<String, dynamic>.from(item))))
        .toList();
  }

  List<String> stringList(String key) {
    final value = _raw(key);
    if (value is! List) return const [];
    return value.whereType<String>().toList();
  }

  Json? nested(String key) {
    final value = _raw(key);
    if (value is Map) return Json(Map<String, dynamic>.from(value));
    return null;
  }

  /// Maps a raw string to an enum, tolerant of an unknown/missing value.
  T enumValue<T extends Enum>(String key, List<T> values, T fallback) {
    final raw = stringOrNull(key);
    if (raw == null) return fallback;
    return values.firstWhere(
      (v) => v.name.toUpperCase() == raw.toUpperCase(),
      orElse: () => fallback,
    );
  }
}
