import 'package:agapeo/core/error/result.dart';
import 'package:agapeo/core/theme/app_theme.dart';
import 'package:agapeo/features/auth/di/auth_providers.dart';
import 'package:agapeo/features/auth/domain/entities/auth_session.dart';
import 'package:agapeo/features/feed/di/feed_providers.dart';
import 'package:agapeo/features/feed/presentation/pages/my_posts_page.dart';
import 'package:agapeo/features/home/presentation/tabs/profile_tab_page.dart';
import 'package:agapeo/features/profile/di/profile_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/auth_test_fakes.dart';
import '../../../../helpers/feed_test_fakes.dart';
import '../../../../helpers/profile_test_fakes.dart';

void main() {
  testWidgets('opens Mes publications from the profile tab', (tester) async {
    // Le surface par défaut du test (~800x600) est trop courte pour la
    // liste de sections du hub (un sliver plus haut que ça la fait
    // disparaître du tree, pas juste hors écran) - même taille que
    // profile_hub_body_test.dart, qui pompe le même ProfileTabPage.
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(
              currentSession: const AuthSession(id: '1', email: 'a@b.c'),
            ),
          ),
          feedRepositoryProvider.overrideWithValue(FakeFeedRepository()),
          profileFieldsRepositoryProvider.overrideWithValue(
            FakeProfileFieldsRepository(
              result: Ok(fakeProfileFieldsSnapshot()),
            ),
          ),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const ProfileTabPage()),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.ensureVisible(find.text('Mes Publications'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mes Publications'));
    await tester.pumpAndSettle();
    expect(find.byType(MyPostsPage), findsOneWidget);
  });
}
