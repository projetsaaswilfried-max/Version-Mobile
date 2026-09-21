import 'package:agapeo/core/theme/app_theme.dart';
import 'package:agapeo/features/messages/data/repositories/seeded_messages_repository.dart';
import 'package:agapeo/features/messages/di/messages_providers.dart';
import 'package:agapeo/features/messages/presentation/thread/conversation_thread_controller.dart';
import 'package:agapeo/features/messages/presentation/thread/conversation_thread_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpThread(
    WidgetTester tester, {
    required String conversationId,
    SeededMessagesRepository? repo,
  }) async {
    final seeded = repo ?? SeededMessagesRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [messagesRepositoryProvider.overrideWithValue(seeded)],
        child: MaterialApp(
          theme: AppTheme.light,
          home: ConversationThreadPage(conversationId: conversationId),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('ACCEPTED : envoi local visible', (tester) async {
    final repo = SeededMessagesRepository();
    late ProviderContainer container;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [messagesRepositoryProvider.overrideWithValue(repo)],
        child: Builder(
          builder: (context) {
            container = ProviderScope.containerOf(context);
            return MaterialApp(
              theme: AppTheme.light,
              home: const ConversationThreadPage(
                conversationId: 'fake-accepted-1',
              ),
            );
          },
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('À dimanche après la messe ?'), findsOneWidget);

    await container
        .read(conversationThreadControllerProvider('fake-accepted-1').notifier)
        .send('Salut test');
    await tester.pump();

    expect(find.text('Salut test'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('refreshMessages ne bascule pas isLoading', (tester) async {
    final repo = SeededMessagesRepository();
    late ProviderContainer container;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [messagesRepositoryProvider.overrideWithValue(repo)],
        child: Builder(
          builder: (context) {
            container = ProviderScope.containerOf(context);
            return MaterialApp(
              theme: AppTheme.light,
              home: const ConversationThreadPage(
                conversationId: 'fake-accepted-1',
              ),
            );
          },
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    final notifier = container.read(
      conversationThreadControllerProvider('fake-accepted-1').notifier,
    );
    expect(
      container.read(conversationThreadControllerProvider('fake-accepted-1'))
          .isLoading,
      isFalse,
    );

    await notifier.refreshMessages();
    await tester.pump();

    final state = container.read(
      conversationThreadControllerProvider('fake-accepted-1'),
    );
    expect(state.isLoading, isFalse);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('À dimanche après la messe ?'), findsOneWidget);
  });

  testWidgets('PENDING entrant : Accepter / Refuser sans saisie', (
    tester,
  ) async {
    await pumpThread(tester, conversationId: 'fake-pending-1');

    expect(find.text('Accepter'), findsOneWidget);
    expect(find.text('Refuser'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('système : lecture seule', (tester) async {
    await pumpThread(tester, conversationId: 'fake-system-1');

    expect(
      find.text('Les messages Agapeo sont en lecture seule'),
      findsOneWidget,
    );
    expect(find.byType(TextField), findsNothing);
    expect(find.text('Accepter'), findsNothing);
  });

  testWidgets('PENDING sortant : en attente', (tester) async {
    await pumpThread(tester, conversationId: 'fake-pending-out');

    expect(find.text('En attente de réponse'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('joindre ouvre le sheet d\'options', (tester) async {
    await pumpThread(tester, conversationId: 'fake-accepted-1');

    await tester.tap(find.byTooltip('Joindre'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Note vocale'), findsOneWidget);
    await tester.tap(find.text('Document'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Média : bientôt'), findsOneWidget);
  });
}
