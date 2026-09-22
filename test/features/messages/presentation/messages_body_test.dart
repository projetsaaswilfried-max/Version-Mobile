import 'package:agapeo/core/error/failure.dart';
import 'package:agapeo/core/error/result.dart';
import 'package:agapeo/core/theme/app_theme.dart';
import 'package:agapeo/features/home/presentation/tabs/messages_tab_page.dart';
import 'package:agapeo/features/messages/data/repositories/seeded_messages_repository.dart';
import 'package:agapeo/features/messages/di/messages_providers.dart';
import 'package:agapeo/features/messages/domain/entities/conversation_summary.dart';
import 'package:agapeo/features/messages/presentation/messages_body.dart';
import 'package:agapeo/features/messages/presentation/widgets/messages_conversation_tile.dart';
import 'package:agapeo/features/profile/di/profile_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/auth_test_fakes.dart';
import '../../../helpers/messages_test_fakes.dart';

void main() {
  Future<void> pumpMessages(
    WidgetTester tester, {
    required FakeMessagesRepository repo,
    Widget home = const Scaffold(body: MessagesBody()),
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          messagesRepositoryProvider.overrideWithValue(repo),
          profileGateRepositoryProvider.overrideWithValue(
            FakeProfileGateRepository(),
          ),
        ],
        child: MaterialApp(theme: AppTheme.light, home: home),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('shows empty state with Discover hint', (tester) async {
    await pumpMessages(tester, repo: FakeMessagesRepository());

    expect(find.text('Aucune conversation'), findsOneWidget);
    expect(
      find.text('Démarre une discussion depuis Découvrir.'),
      findsOneWidget,
    );
    expect(find.text('Bientôt'), findsNothing);
  });

  testWidgets('shows list rows, invitation chip and unread badge', (
    tester,
  ) async {
    await pumpMessages(
      tester,
      repo: FakeMessagesRepository(
        conversations: Ok([
          ConversationSummary(
            id: 'c1',
            peerName: 'Léa Martin',
            preview: 'Salut',
            lastAt: DateTime.utc(2026, 9, 19, 10),
            unreadCount: 2,
            isIncomingInvite: true,
          ),
          const ConversationSummary(
            id: 'c2',
            peerName: 'Paul',
            preview: 'À bientôt',
          ),
        ]),
      ),
    );

    expect(find.byType(MessagesConversationTile), findsNWidgets(2));
    expect(find.text('Léa Martin'), findsOneWidget);
    expect(find.text('Salut'), findsOneWidget);
    expect(find.text('Invitation'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('Paul'), findsOneWidget);
  });

  testWidgets('incoming invite shows web copy when preview is empty', (
    tester,
  ) async {
    await pumpMessages(
      tester,
      repo: FakeMessagesRepository(
        conversations: Ok([
          const ConversationSummary(
            id: 'c-invite',
            peerName: 'Sarah Cet-line',
            status: 'PENDING',
            isIncomingInvite: true,
          ),
        ]),
      ),
    );

    expect(find.text('Sarah Cet-line'), findsOneWidget);
    expect(find.text('Souhaite discuter avec toi'), findsOneWidget);
    expect(find.text('Invitation'), findsOneWidget);
  });

  testWidgets('filters the list on search', (tester) async {
    await pumpMessages(
      tester,
      repo: FakeMessagesRepository(
        conversations: Ok([
          const ConversationSummary(
            id: 'c1',
            peerName: 'Léa Martin',
            preview: 'Salut',
          ),
          const ConversationSummary(
            id: 'c2',
            peerName: 'Paul',
            preview: 'Dimanche',
          ),
        ]),
      ),
    );

    await tester.enterText(find.byType(TextField), 'paul');
    await tester.pump();

    expect(find.text('Paul'), findsOneWidget);
    expect(find.text('Léa Martin'), findsNothing);
  });

  testWidgets('shows expired wall without list', (tester) async {
    await pumpMessages(
      tester,
      repo: FakeMessagesRepository(subscription: const Ok('EXPIRED')),
    );

    expect(find.text('Abonnement expiré'), findsOneWidget);
    expect(find.text('Aucune conversation'), findsNothing);
    expect(find.byType(TextField), findsNothing);
    expect(find.byType(MessagesConversationTile), findsNothing);
  });

  testWidgets('shows error and retries', (tester) async {
    final repo = FakeMessagesRepository(
      subscription: const Err(NetworkFailure('offline')),
    );
    await pumpMessages(tester, repo: repo);

    expect(find.text('Impossible de charger Messages'), findsOneWidget);
    expect(find.text('Réessayer'), findsOneWidget);

    repo.subscription = const Ok('FREE');
    repo.conversations = Ok([
      const ConversationSummary(id: 'ok', peerName: 'Léa'),
    ]);
    await tester.tap(find.text('Réessayer'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Léa'), findsOneWidget);
    expect(find.text('Réessayer'), findsNothing);
  });

  testWidgets('tap row ouvre le fil de conversation', (tester) async {
    final repo = SeededMessagesRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          messagesRepositoryProvider.overrideWithValue(repo),
          profileGateRepositoryProvider.overrideWithValue(
            FakeProfileGateRepository(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: MessagesBody()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Léa Martin'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Conversation : bientôt'), findsNothing);
    expect(find.byKey(const Key('thread-send')), findsOneWidget);
  });

  testWidgets('Messages tab is not the Bientôt placeholder', (tester) async {
    await pumpMessages(
      tester,
      repo: FakeMessagesRepository(),
      home: const MessagesTabPage(),
    );

    expect(find.text('Messages'), findsWidgets);
    expect(find.text('Aucune conversation'), findsOneWidget);
    expect(find.text('Bientôt'), findsNothing);
  });
}
