import 'package:agapeo/core/error/result.dart';
import 'package:agapeo/features/feed/domain/usecases/list_personal_posts.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/feed_test_fakes.dart';

void main() {
  test('returns empty without calling repo when authorId is blank', () async {
    final repo = FakeFeedRepository()..myPosts = [fakePost(id: 'p1')];
    final result = await ListPersonalPosts(repo)('  ');
    expect(result, isA<Ok>());
    expect((result as Ok).value, isEmpty);
  });

  test('delegates to repository for a real authorId', () async {
    final repo = FakeFeedRepository()..myPosts = [fakePost(id: 'p1')];
    final result = await ListPersonalPosts(repo)('user-1');
    expect(result, isA<Ok>());
    expect((result as Ok).value.single.id, 'p1');
  });
}
