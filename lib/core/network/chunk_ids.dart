/// Découpe une liste d'ids pour les `inFilter` PostgREST.
/// Un `in` trop long fait échouer la requête (URL / payload trop gros).
List<List<String>> chunkIds(List<String> ids, {int size = 80}) {
  if (size <= 0) {
    throw ArgumentError.value(size, 'size', 'must be > 0');
  }
  if (ids.isEmpty) return const [];
  final chunks = <List<String>>[];
  for (var i = 0; i < ids.length; i += size) {
    final end = i + size > ids.length ? ids.length : i + size;
    chunks.add(ids.sublist(i, end));
  }
  return chunks;
}
