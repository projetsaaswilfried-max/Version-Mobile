import '../entities/feed_filter.dart';
import '../entities/post_category.dart';

enum FeedChip {
  all,
  teaching,
  testimony,
  workshop,
  advice,
  quote,
  plus,
  announcement,
  verse,
  news;

  static const tabs = [all, teaching, testimony, workshop, advice, quote];

  static const visible = [...tabs, plus];

  static const overflow = [announcement, verse, news];

  /// Toutes les catégories réelles (hors déclencheur [plus]), affichées sur
  /// une seule ligne horizontale scrollable — voir D13.
  static const allVisible = [...tabs, ...overflow];

  bool get isOverflowTrigger => this == plus;

  bool get isOverflow => overflow.contains(this);

  String get label => switch (this) {
    all => 'Tout le fil',
    teaching => 'Enseignements',
    testimony => 'Témoignages',
    workshop => 'Atelier/Mariage',
    advice => 'Conseils & Préparation',
    quote => 'Pensées & Citations',
    plus => 'Plus',
    announcement => 'Annonce',
    verse => 'Verset',
    news => 'Nouveauté',
  };

  FeedFilter get filter => switch (this) {
    all || plus => const FeedFilter.all(),
    teaching => const FeedFilter.byCategory(PostCategory.teaching),
    testimony => const FeedFilter.byCategory(PostCategory.testimony),
    workshop => const FeedFilter.byCategory(PostCategory.workshop),
    advice => const FeedFilter.byCategory(PostCategory.advice),
    quote => const FeedFilter.byCategory(PostCategory.quote),
    announcement => const FeedFilter.byCategory(PostCategory.announcement),
    verse => const FeedFilter.byCategory(PostCategory.verse),
    news => const FeedFilter.byCategory(PostCategory.news),
  };
}
