List<T> pickDailyRecommended<T>({
  required List<T> ranked,
  required String visitorId,
  required DateTime utcDay,
  required String Function(T item) idOf,
  int Function(T item)? scoreOf,
  int count = 3,
}) {
  if (count <= 0 || ranked.isEmpty) return <T>[];

  final dayKey = _utcDateKey(utcDay);
  final unique = <T>[];
  final seen = <String>{};
  for (final item in ranked) {
    if (seen.add(idOf(item))) unique.add(item);
  }

  final indexed = [
    for (var i = 0; i < unique.length; i++) (item: unique[i], index: i),
  ];
  indexed.sort((a, b) {
    final scoreCmp = _itemScore(
      b.item,
      b.index,
      scoreOf,
    ).compareTo(_itemScore(a.item, a.index, scoreOf));
    if (scoreCmp != 0) return scoreCmp;
    final hashCmp =
        _tieBreakHash(
          visitorId: visitorId,
          dayKey: dayKey,
          id: idOf(a.item),
        ).compareTo(
          _tieBreakHash(visitorId: visitorId, dayKey: dayKey, id: idOf(b.item)),
        );
    if (hashCmp != 0) return hashCmp;
    return a.index.compareTo(b.index);
  });

  return indexed.take(count).map((entry) => entry.item).toList();
}

String _utcDateKey(DateTime utcDay) {
  final day = utcDay.toUtc();
  final y = day.year.toString().padLeft(4, '0');
  final m = day.month.toString().padLeft(2, '0');
  final d = day.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

int _itemScore<T>(T item, int fallbackIndex, int Function(T item)? scoreOf) {
  return scoreOf?.call(item) ?? -fallbackIndex;
}

int _tieBreakHash({
  required String visitorId,
  required String dayKey,
  required String id,
}) {
  return _fnv1a32('$visitorId|$dayKey|$id');
}

int _fnv1a32(String input) {
  var hash = 2166136261;
  for (final unit in input.codeUnits) {
    hash ^= unit;
    hash = (hash * 16777619) & 0xFFFFFFFF;
  }
  return hash;
}
