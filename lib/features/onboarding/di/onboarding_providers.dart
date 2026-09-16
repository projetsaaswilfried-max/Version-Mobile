import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/repositories/intro_store.dart';

final introStoreProvider = Provider<IntroStore>((ref) {
  throw UnimplementedError(
    'Override in ProviderScope after SharedPreferences.init',
  );
});
