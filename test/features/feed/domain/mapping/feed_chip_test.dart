import 'package:agapeo/features/feed/domain/entities/feed_filter.dart';
import 'package:agapeo/features/feed/domain/entities/post_category.dart';
import 'package:agapeo/features/feed/domain/mapping/feed_chip.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('visible chips match web labels plus overflow trigger', () {
    expect(FeedChip.tabs.map((c) => c.label).toList(), [
      'Tout le fil',
      'Enseignements',
      'Témoignages',
      'Atelier/Mariage',
      'Conseils & Préparation',
      'Pensées & Citations',
    ]);
    expect(FeedChip.plus.isOverflowTrigger, isTrue);
  });

  test('maps chips to FeedFilter enums', () {
    expect(FeedChip.all.filter.isAll, isTrue);
    expect(FeedChip.teaching.filter.category, PostCategory.teaching);
    expect(FeedChip.testimony.filter.category, PostCategory.testimony);
    expect(FeedChip.workshop.filter.category, PostCategory.workshop);
    expect(FeedChip.advice.filter.category, PostCategory.advice);
    expect(FeedChip.quote.filter.category, PostCategory.quote);
    expect(FeedChip.announcement.filter.category, PostCategory.announcement);
    expect(FeedChip.verse.filter.category, PostCategory.verse);
    expect(FeedChip.news.filter.category, PostCategory.news);
  });

  test('overflow chips are announcement verse news', () {
    expect(FeedChip.overflow, [
      FeedChip.announcement,
      FeedChip.verse,
      FeedChip.news,
    ]);
    expect(FeedChip.plus.isOverflowTrigger, isTrue);
    expect(FeedChip.announcement.isOverflow, isTrue);
  });

  test('FeedFilter equality', () {
    expect(const FeedFilter.all(), const FeedFilter.all());
    expect(
      const FeedFilter.byCategory(PostCategory.teaching),
      const FeedFilter.byCategory(PostCategory.teaching),
    );
  });
}
