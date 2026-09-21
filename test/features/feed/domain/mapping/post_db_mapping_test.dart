import 'package:agapeo/features/feed/domain/entities/post_category.dart';
import 'package:agapeo/features/feed/domain/entities/post_media_type.dart';
import 'package:agapeo/features/feed/domain/mapping/post_db_mapping.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps post_category DB strings', () {
    expect(categoryFromDb('TEACHING'), PostCategory.teaching);
    expect(categoryFromDb('TESTIMONY'), PostCategory.testimony);
    expect(categoryFromDb('WORKSHOP'), PostCategory.workshop);
    expect(categoryFromDb('ADVICE'), PostCategory.advice);
    expect(categoryFromDb('ANNOUNCEMENT'), PostCategory.announcement);
    expect(categoryFromDb('QUOTE'), PostCategory.quote);
    expect(categoryFromDb('VERSE'), PostCategory.verse);
    expect(categoryFromDb('NEWS'), PostCategory.news);
    expect(categoryFromDb('unknown'), isNull);
    expect(categoryFromDb(null), isNull);
  });

  test('maps post_media_type including underscore names', () {
    expect(mediaTypeFromDb('IMAGE'), PostMediaType.image);
    expect(mediaTypeFromDb('GALLERY'), PostMediaType.gallery);
    expect(mediaTypeFromDb('VIDEO'), PostMediaType.video);
    expect(mediaTypeFromDb('QUOTE_CARD'), PostMediaType.quoteCard);
    expect(mediaTypeFromDb('TEXT_ONLY'), PostMediaType.textOnly);
    expect(mediaTypeFromDb('YOUTUBE'), PostMediaType.youtube);
    expect(mediaTypeFromDb('nope'), PostMediaType.textOnly);
    expect(mediaTypeFromDb(null), PostMediaType.textOnly);
  });

  test('maps category to DB', () {
    expect(categoryToDb(PostCategory.teaching), 'TEACHING');
    expect(categoryToDb(PostCategory.quote), 'QUOTE');
  });

  test('card labels match the web feed meta line', () {
    expect(PostCategory.teaching.cardLabel, 'Enseignement');
    expect(PostCategory.testimony.cardLabel, 'Témoignage');
    expect(PostCategory.workshop.cardLabel, 'Atelier/Mariage');
    expect(PostCategory.advice.cardLabel, 'Conseil');
    expect(PostCategory.announcement.cardLabel, 'Annonce');
    expect(PostCategory.quote.cardLabel, 'Citation');
    expect(PostCategory.verse.cardLabel, 'Verset');
    expect(PostCategory.news.cardLabel, 'Nouveauté');
  });
}
