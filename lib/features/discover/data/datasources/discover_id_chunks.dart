import '../../../../core/network/chunk_ids.dart';

/// Alias Discover : même découpage que le Feed.
List<List<String>> chunkDiscoverIds(List<String> ids, {int size = 80}) {
  return chunkIds(ids, size: size);
}
