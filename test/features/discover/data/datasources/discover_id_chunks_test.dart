import 'package:agapeo/core/network/chunk_ids.dart';
import 'package:agapeo/features/discover/data/datasources/discover_id_chunks.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('chunks 1000 ids into batches of 80', () {
    final ids = [for (var i = 0; i < 1000; i++) 'id-$i'];
    final chunks = chunkDiscoverIds(ids, size: 80);
    expect(chunks, hasLength(13));
    expect(chunks.first, hasLength(80));
    expect(chunks.last, hasLength(40));
    expect(chunks.expand((c) => c).length, 1000);
    expect(chunkIds(ids, size: 80), chunks);
  });

  test('empty input yields no chunks', () {
    expect(chunkDiscoverIds(const []), isEmpty);
    expect(chunkIds(const []), isEmpty);
  });
}
