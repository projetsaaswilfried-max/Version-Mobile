import 'package:agapeo/core/theme/app_theme.dart';
import 'package:agapeo/features/messages/data/repositories/seeded_messages_repository.dart';
import 'package:agapeo/features/messages/di/messages_providers.dart';
import 'package:agapeo/features/messages/presentation/thread/conversation_thread_page.dart';
import 'package:agapeo/features/profile/di/profile_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/auth_test_fakes.dart';

void main() {
  Future<void> pumpThread(WidgetTester tester, String id) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          messagesRepositoryProvider.overrideWithValue(
            SeededMessagesRepository(),
          ),
          profileGateRepositoryProvider.overrideWithValue(
            FakeProfileGateRepository(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: ConversationThreadPage(conversationId: id),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('Léa : proposer puis annuler', (tester) async {
    await pumpThread(tester, 'fake-accepted-1');

    expect(find.text('Proposer un match'), findsOneWidget);
    await tester.tap(find.text('Proposer un match'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Explique les conséquences (disparition de Découvrir) avant d'envoyer.
    expect(find.textContaining('Proposer un match à'), findsOneWidget);
    await tester.tap(find.text('Proposer'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('En attente de réponse'), findsOneWidget);
    await tester.tap(find.text('Annuler'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Proposer un match'), findsOneWidget);
  });

  testWidgets('Camille : accepter match entrant', (tester) async {
    await pumpThread(tester, 'fake-accepted-2');

    expect(find.text('Proposition de match reçue'), findsOneWidget);
    await tester.tap(find.text('Accepter'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Explique les conséquences (disparition de Découvrir) avant de valider.
    expect(find.textContaining('Accepter le match avec'), findsOneWidget);
    await tester.tap(find.text('Confirmer le match'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Vous êtes en couple'), findsOneWidget);
  });

  testWidgets('système : pas de bandeau match', (tester) async {
    await pumpThread(tester, 'fake-system-1');

    expect(find.text('Proposer un match'), findsNothing);
    expect(find.text('Proposition de match reçue'), findsNothing);
  });
}
