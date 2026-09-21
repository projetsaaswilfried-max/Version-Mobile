import 'package:agapeo/core/error/result.dart';
import 'package:agapeo/core/theme/app_theme.dart';
import 'package:agapeo/features/messages/data/repositories/seeded_messages_repository.dart';
import 'package:agapeo/features/messages/di/messages_providers.dart';
import 'package:agapeo/features/messages/domain/entities/conversation_summary.dart';
import 'package:agapeo/features/messages/presentation/thread/conversation_thread_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('hideConversation retire la conv du seed', () async {
    final repo = SeededMessagesRepository();
    await repo.hideConversation('fake-accepted-1');
    final gone =
        (await repo.fetchConversation('fake-accepted-1')
                as Ok<ConversationSummary?>)
            .value;
    expect(gone, isNull);
    final list =
        (await repo.fetchConversations() as Ok<List<ConversationSummary>>)
            .value;
    expect(list.any((c) => c.id == 'fake-accepted-1'), isFalse);
  });

  testWidgets('menu Masquer + confirm ferme le fil', (tester) async {
    final repo = SeededMessagesRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [messagesRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const ConversationThreadPage(conversationId: 'fake-accepted-1'),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Masquer la discussion'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Masquer la discussion ?'), findsOneWidget);
    await tester.tap(find.text('Masquer'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(ConversationThreadPage), findsNothing);
    final list =
        (await repo.fetchConversations() as Ok<List<ConversationSummary>>)
            .value;
    expect(list.any((c) => c.id == 'fake-accepted-1'), isFalse);
  });

  testWidgets('Annuler le dialog laisse le fil ouvert', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          messagesRepositoryProvider.overrideWithValue(
            SeededMessagesRepository(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const ConversationThreadPage(conversationId: 'fake-accepted-1'),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Masquer la discussion'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Annuler'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(ConversationThreadPage), findsOneWidget);
    expect(find.text('Léa Martin'), findsWidgets);
  });
}
