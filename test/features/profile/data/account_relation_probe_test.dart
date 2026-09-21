import 'package:agapeo/features/profile/data/account_relation_probe.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Mes Favoris utilise favorite_profile_id, jamais target_id', () {
    expect(
      AccountRelationPairs.favorites.first,
      ('user_id', 'favorite_profile_id'),
    );
    expect(
      AccountRelationPairs.favorites.map((pair) => pair.$2),
      isNot(contains('target_id')),
    );
  });

  test('infère profile_id comme cible d’un favori', () {
    expect(
      inferRelationTargetColumn({
        'id': 'row-1',
        'user_id': '11111111-1111-1111-1111-111111111111',
        'profile_id': '22222222-2222-2222-2222-222222222222',
        'created_at': '2026-09-19T00:00:00Z',
      }, ownerCol: 'user_id'),
      'profile_id',
    );
  });
}
