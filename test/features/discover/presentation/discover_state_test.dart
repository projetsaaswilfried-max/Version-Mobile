import 'package:agapeo/features/discover/presentation/discover_state.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/discover_test_fakes.dart';

void main() {
  test('isEmpty is false while a search/loadMore fetch is in flight', () {
    // Pendant que `_runSearch` interroge le serveur, `recommended`/`others`
    // sont vidés avant la réponse — sans ce garde, l'écran affichait "Aucun
    // profil pour le moment" le temps de la requête (bug remonté en test
    // manuel), au lieu d'un état de chargement.
    const loading = DiscoverState(isLoadingMore: true);
    expect(loading.isEmpty, isFalse);
    expect(loading.isReloadingResults, isTrue);
  });

  test('isReloadingResults is false when loadMore appends to a list', () {
    final loadingMore = DiscoverState(
      isLoadingMore: true,
      others: [fakeDiscoverProfile('p01')],
    );
    expect(loadingMore.isReloadingResults, isFalse);
  });

  test('isEmpty is true once loading settles with no results', () {
    const settled = DiscoverState();
    expect(settled.isEmpty, isTrue);
  });
}
