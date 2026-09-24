import 'package:agapeo/core/error/result.dart';
import 'package:agapeo/core/navigation/root_navigator.dart';
import 'package:agapeo/core/theme/app_theme.dart';
import 'package:agapeo/features/discover/di/discover_providers.dart';
import 'package:agapeo/features/discover/presentation/widgets/discover_profile_sheet.dart';
import 'package:agapeo/features/home/presentation/home_shell_controller.dart';
import 'package:agapeo/features/messages/di/messages_providers.dart';
import 'package:agapeo/features/messages/presentation/thread/conversation_thread_page.dart';
import 'package:agapeo/features/notifications/di/notifications_providers.dart';
import 'package:agapeo/features/notifications/domain/entities/app_notification.dart';
import 'package:agapeo/features/notifications/domain/notification_category.dart';
import 'package:agapeo/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:agapeo/features/notifications/presentation/notifications_page.dart';
import 'package:agapeo/features/premium/presentation/premium_plan_page.dart';
import 'package:agapeo/features/profile/di/profile_providers.dart';
import 'package:agapeo/features/profile/presentation/security/verification_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/auth_test_fakes.dart';
import '../../../helpers/discover_test_fakes.dart';
import '../../../helpers/messages_test_fakes.dart';
import '../../../helpers/profile_account_test_fakes.dart';

class _FakeNotificationsRepository implements NotificationsRepository {
  _FakeNotificationsRepository({this.items = const []});

  List<AppNotification> items;
  final markedRead = <String>[];
  var markedAllRead = false;

  @override
  Future<Result<List<AppNotification>>> fetchAll() async => Ok(items);

  @override
  Future<Result<void>> markRead(String id) async {
    markedRead.add(id);
    return const Ok(null);
  }

  @override
  Future<Result<void>> markAllRead() async {
    markedAllRead = true;
    items = [for (final item in items) item.asRead()];
    return const Ok(null);
  }
}

Future<(_FakeNotificationsRepository, ProviderContainer)> _pumpNotifications(
  WidgetTester tester, {
  List<AppNotification> items = const [],
  List<Override> extraOverrides = const [],
}) async {
  final repo = _FakeNotificationsRepository(items: items);
  late final ProviderContainer container;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        notificationsRepositoryProvider.overrideWithValue(repo),
        messagesRepositoryProvider.overrideWithValue(FakeMessagesRepository()),
        profileGateRepositoryProvider.overrideWithValue(
          FakeProfileGateRepository(),
        ),
        ...extraOverrides,
      ],
      child: Consumer(
        builder: (context, ref, _) {
          container = ProviderScope.containerOf(context);
          return MaterialApp(
            navigatorKey: rootNavigatorKey,
            theme: AppTheme.light,
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const NotificationsPage(),
                      ),
                    ),
                    child: const Text('open'),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  await tester.pump();
  return (repo, container);
}

void main() {
  testWidgets('empty state shows the per-category copy', (tester) async {
    await _pumpNotifications(tester);

    expect(find.text('Aucune notification'), findsOneWidget);
    expect(
      find.text('Les likes, messages et nouveautés apparaîtront ici.'),
      findsOneWidget,
    );
  });

  testWidgets('lists notifications with aggregate count and unread dot', (
    tester,
  ) async {
    await _pumpNotifications(
      tester,
      items: [
        AppNotification(
          id: '1',
          title: 'Nouveaux favoris',
          body: 'Marc et Léa se sont intéressés à toi',
          createdAt: DateTime.now(),
          isRead: false,
          category: AppNotificationCategory.profile,
          aggregateCount: 2,
        ),
        AppNotification(
          id: '2',
          title: 'Message reçu',
          body: '',
          createdAt: DateTime.now(),
          isRead: true,
          category: AppNotificationCategory.messages,
        ),
      ],
    );

    expect(find.text('Nouveaux favoris (2)'), findsOneWidget);
    expect(find.text('Marc et Léa se sont intéressés à toi'), findsOneWidget);
    expect(find.text('Message reçu'), findsOneWidget);
    expect(find.text('Tout lire'), findsOneWidget);
    expect(find.text('Aujourd\'hui'), findsOneWidget);
  });

  testWidgets('Tout lire marks every notification as read', (tester) async {
    final (repo, _) = await _pumpNotifications(
      tester,
      items: [
        AppNotification(
          id: '1',
          title: 'Nouveau like',
          body: '',
          createdAt: DateTime.now(),
          isRead: false,
          category: AppNotificationCategory.profile,
        ),
      ],
    );

    await tester.tap(find.text('Tout lire'));
    await tester.pump();
    await tester.pump();

    expect(repo.markedAllRead, isTrue);
    expect(find.text('Tout lire'), findsNothing);
  });

  testWidgets('tapping an unread notification marks it as read', (
    tester,
  ) async {
    final (repo, _) = await _pumpNotifications(
      tester,
      items: [
        AppNotification(
          id: '1',
          title: 'Nouveau like',
          body: 'Quelqu\'un a aimé ton profil',
          createdAt: DateTime.now(),
          isRead: false,
          category: AppNotificationCategory.profile,
        ),
      ],
    );

    await tester.tap(find.text('Nouveau like'));
    await tester.pump();
    await tester.pump();

    expect(repo.markedRead, ['1']);
    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
  });

  testWidgets('tapping an already-read notification does not call markRead', (
    tester,
  ) async {
    final (repo, _) = await _pumpNotifications(
      tester,
      items: [
        AppNotification(
          id: '1',
          title: 'Nouveau like',
          body: '',
          createdAt: DateTime.now(),
          isRead: true,
          category: AppNotificationCategory.profile,
        ),
      ],
    );

    await tester.tap(find.text('Nouveau like'));
    await tester.pump();
    await tester.pump();

    expect(repo.markedRead, isEmpty);
  });

  testWidgets('tapping a message notification opens the conversation thread', (
    tester,
  ) async {
    await _pumpNotifications(
      tester,
      items: [
        AppNotification(
          id: '1',
          title: 'Agapeo vous a envoyé un message',
          body: '',
          createdAt: DateTime.now(),
          isRead: false,
          category: AppNotificationCategory.messages,
          type: 'NEW_MESSAGE',
          targetUrl: '/messages?conversation=f0b675ed-2196-441d-be40',
        ),
      ],
    );

    await tester.tap(find.text('Agapeo vous a envoyé un message'));
    await tester.pump();
    await tester.pump();

    final page = tester.widget<ConversationThreadPage>(
      find.byType(ConversationThreadPage),
    );
    expect(page.conversationId, 'f0b675ed-2196-441d-be40');
  });

  testWidgets(
    'tapping a PROFILE_VISIT notification switches to the Découvrir tab',
    (tester) async {
      final (_, container) = await _pumpNotifications(
        tester,
        items: [
          AppNotification(
            id: '1',
            title: '3 personnes ont consulté votre profil',
            body: '',
            createdAt: DateTime.now(),
            isRead: false,
            category: AppNotificationCategory.profile,
            type: 'PROFILE_VISIT',
            targetUrl: '/discover',
          ),
        ],
      );

      // homeShellIndexProvider est autoDispose : dans la vraie app,
      // HomeShellPage l'observe en continu, ce qui le garde vivant. Ici on
      // simule cette écoute pour ne pas perdre la mutation entre le tap et
      // l'assertion.
      final subscription = container.listen(homeShellIndexProvider, (_, _) {});
      addTearDown(subscription.close);

      await tester.tap(find.text('3 personnes ont consulté votre profil'));
      await tester.pump();
      await tester.pump();

      expect(container.read(homeShellIndexProvider), 1);
    },
  );

  testWidgets(
    'tapping a PHOTO_APPROVED notification opens VerificationPage',
    (tester) async {
      await _pumpNotifications(
        tester,
        items: [
          AppNotification(
            id: '1',
            title: 'Profil vérifié',
            body: '',
            createdAt: DateTime.now(),
            isRead: false,
            category: AppNotificationCategory.platform,
            type: 'PHOTO_APPROVED',
          ),
        ],
        extraOverrides: [
          profileAccountRepositoryProvider.overrideWithValue(
            FakeProfileAccountRepository(),
          ),
        ],
      );

      await tester.tap(find.text('Profil vérifié'));
      await tester.pump();
      await tester.pump();

      expect(find.byType(VerificationPage), findsOneWidget);
    },
  );

  testWidgets(
    'tapping a PAYMENT_FAILED notification opens PremiumPlanPage',
    (tester) async {
      await _pumpNotifications(
        tester,
        items: [
          AppNotification(
            id: '1',
            title: 'Paiement échoué',
            body: '',
            createdAt: DateTime.now(),
            isRead: false,
            category: AppNotificationCategory.platform,
            type: 'PAYMENT_FAILED',
          ),
        ],
      );

      await tester.tap(find.text('Paiement échoué'));
      await tester.pump();
      await tester.pump();

      expect(find.byType(PremiumPlanPage), findsOneWidget);
    },
  );

  testWidgets(
    'tapping a PROFILE_LIKE notification with an actorId opens the profile sheet',
    (tester) async {
      await _pumpNotifications(
        tester,
        items: [
          AppNotification(
            id: '1',
            title: 'Quelqu\'un a aimé ton profil',
            body: '',
            createdAt: DateTime.now(),
            isRead: false,
            category: AppNotificationCategory.profile,
            type: 'PROFILE_LIKE',
            actorId: 'p1',
          ),
        ],
        extraOverrides: [
          discoverRepositoryProvider.overrideWithValue(
            FakeDiscoverRepository(),
          ),
        ],
      );

      await tester.tap(find.text('Quelqu\'un a aimé ton profil'));
      await tester.pump();
      await tester.pump();

      expect(find.byType(DiscoverProfileSheet), findsOneWidget);
    },
  );

  testWidgets('filter chips switch the visible category', (tester) async {
    await _pumpNotifications(
      tester,
      items: [
        AppNotification(
          id: '1',
          title: 'Nouveau message',
          body: '',
          createdAt: DateTime.now(),
          isRead: false,
          category: AppNotificationCategory.messages,
        ),
        AppNotification(
          id: '2',
          title: 'Nouveau like',
          body: '',
          createdAt: DateTime.now(),
          isRead: false,
          category: AppNotificationCategory.profile,
        ),
      ],
    );

    expect(find.text('Nouveau message'), findsOneWidget);
    expect(find.text('Nouveau like'), findsOneWidget);

    await tester.tap(find.text('Messages'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Nouveau message'), findsOneWidget);
    expect(find.text('Nouveau like'), findsNothing);
  });
}
