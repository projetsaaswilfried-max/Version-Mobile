import 'package:agapeo/features/onboarding/data/datasources/intro_local_datasource.dart';
import 'package:agapeo/features/onboarding/data/repositories/intro_store_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('isSeen false by default then true after markSeen', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = IntroStoreImpl(IntroLocalDataSource(prefs));

    expect(await store.isSeen(), isFalse);
    await store.markSeen();
    expect(await store.isSeen(), isTrue);
  });
}
