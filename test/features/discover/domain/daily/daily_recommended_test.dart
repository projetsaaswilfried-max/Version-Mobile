import 'package:agapeo/features/discover/domain/daily/daily_recommended.dart';
import 'package:flutter_test/flutter_test.dart';

class _Item {
  const _Item(this.id, {this.score = 0});

  final String id;
  final int score;
}

List<_Item> _ranked(Iterable<String> ids, {int Function(String id)? scoreOf}) {
  return ids
      .map((id) => _Item(id, score: scoreOf?.call(id) ?? 0))
      .toList(growable: false);
}

List<String> _ids(Iterable<_Item> items) =>
    items.map((item) => item.id).toList();

class _IdOnly {
  const _IdOnly(this.id);

  final String id;
}

void main() {
  const visitorId = 'visitor-1';
  final day = DateTime.utc(2026, 9, 18);

  test('same list, day and visitor yield the same three', () {
    final pool = _ranked([
      'a',
      'b',
      'c',
      'd',
      'e',
    ], scoreOf: (id) => 50 - id.codeUnitAt(0));

    final first = pickDailyRecommended(
      ranked: pool,
      visitorId: visitorId,
      utcDay: day,
      idOf: (item) => item.id,
      scoreOf: (item) => item.score,
    );
    final second = pickDailyRecommended(
      ranked: pool,
      visitorId: visitorId,
      utcDay: day,
      idOf: (item) => item.id,
      scoreOf: (item) => item.score,
    );

    expect(_ids(first), ['a', 'b', 'c']);
    expect(_ids(first), _ids(second));
    expect(_ids(first).toSet(), hasLength(3));
  });

  test('skips duplicate ids and keeps at most count', () {
    final picked = pickDailyRecommended(
      ranked: _ranked(
        ['a', 'a', 'b', 'b', 'c', 'd'],
        scoreOf: (id) {
          switch (id) {
            case 'a':
              return 40;
            case 'b':
              return 30;
            case 'c':
              return 20;
            default:
              return 10;
          }
        },
      ),
      visitorId: visitorId,
      utcDay: day,
      idOf: (item) => item.id,
      scoreOf: (item) => item.score,
    );

    expect(_ids(picked).toSet(), hasLength(3));
    expect(_ids(picked), ['a', 'b', 'c']);
  });

  test('returns the whole ranked list when shorter than count', () {
    final picked = pickDailyRecommended(
      ranked: _ranked(['a', 'b'], scoreOf: (id) => id == 'a' ? 2 : 1),
      visitorId: visitorId,
      utcDay: day,
      idOf: (item) => item.id,
      scoreOf: (item) => item.score,
    );

    expect(_ids(picked), ['a', 'b']);
  });

  test('uses visitorId|yyyy-mm-dd|id as deterministic tie-break', () {
    final tied = _ranked(['m', 'n', 'o', 'p', 'q', 'r', 's', 't']);
    final dayA = pickDailyRecommended(
      ranked: tied,
      visitorId: visitorId,
      utcDay: DateTime.utc(2026, 9, 18),
      idOf: (item) => item.id,
      scoreOf: (item) => item.score,
    );
    final dayAAgain = pickDailyRecommended(
      ranked: tied,
      visitorId: visitorId,
      utcDay: DateTime.utc(2026, 9, 18, 15, 30),
      idOf: (item) => item.id,
      scoreOf: (item) => item.score,
    );

    expect(_ids(dayA), hasLength(3));
    expect(_ids(dayA).toSet(), hasLength(3));
    expect(_ids(dayA), _ids(dayAAgain));

    var foundOtherDay = false;
    for (var dayOfMonth = 19; dayOfMonth <= 50; dayOfMonth++) {
      final otherDay = pickDailyRecommended(
        ranked: tied,
        visitorId: visitorId,
        utcDay: DateTime.utc(2026, 9, dayOfMonth),
        idOf: (item) => item.id,
        scoreOf: (item) => item.score,
      );
      if (_ids(otherDay).join() != _ids(dayA).join()) {
        foundOtherDay = true;
        break;
      }
    }
    expect(foundOtherDay, isTrue);

    var foundOtherVisitor = false;
    for (var i = 2; i <= 20; i++) {
      final otherVisitor = pickDailyRecommended(
        ranked: tied,
        visitorId: 'visitor-$i',
        utcDay: DateTime.utc(2026, 9, 18),
        idOf: (item) => item.id,
        scoreOf: (item) => item.score,
      );
      if (_ids(otherVisitor).join() != _ids(dayA).join()) {
        foundOtherVisitor = true;
        break;
      }
    }
    expect(foundOtherVisitor, isTrue);
  });

  test('uses scoreOf without dynamic score access', () {
    final picked = pickDailyRecommended(
      ranked: const [_IdOnly('a'), _IdOnly('b'), _IdOnly('c')],
      visitorId: visitorId,
      utcDay: day,
      idOf: (item) => item.id,
      scoreOf: (item) => item.id == 'c' ? 10 : 0,
    );

    expect(picked.first.id, 'c');
    expect(picked.map((item) => item.id).toSet(), {'a', 'b', 'c'});
  });
}
