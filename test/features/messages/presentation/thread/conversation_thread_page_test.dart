import 'dart:io';

import 'package:agapeo/core/error/result.dart';
import 'package:agapeo/core/theme/app_theme.dart';
import 'package:agapeo/features/messages/data/repositories/seeded_messages_repository.dart';
import 'package:agapeo/features/messages/di/messages_providers.dart';
import 'package:agapeo/features/messages/domain/entities/conversation_summary.dart';
import 'package:agapeo/features/messages/domain/entities/message.dart';
import 'package:agapeo/features/messages/presentation/thread/conversation_thread_controller.dart';
import 'package:agapeo/features/messages/presentation/thread/conversation_thread_page.dart';
import 'package:agapeo/features/premium/presentation/widgets/premium_feature_sheet.dart';
import 'package:agapeo/features/profile/di/profile_providers.dart';
import 'package:agapeo/features/profile/domain/entities/member_gate_snapshot.dart';
import 'package:agapeo/features/profile/domain/entities/subscription_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/auth_test_fakes.dart';
import '../../../../helpers/messages_test_fakes.dart';

void main() {
  Future<void> pumpThread(
    WidgetTester tester, {
    required String conversationId,
    SeededMessagesRepository? repo,
    MemberGateSnapshot? gate,
  }) async {
    final seeded = repo ?? SeededMessagesRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          messagesRepositoryProvider.overrideWithValue(seeded),
          profileGateRepositoryProvider.overrideWithValue(
            FakeProfileGateRepository(gate),
          ),
        ],
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
        overrides: [
          messagesRepositoryProvider.overrideWithValue(repo),
          profileGateRepositoryProvider.overrideWithValue(
            FakeProfileGateRepository(),
          ),
        ],
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

  testWidgets('ouvrir une discussion la marque comme lue', (tester) async {
    final repo = SeededMessagesRepository();
    final before = await repo.fetchConversations();
    expect(
      (before as Ok).value
          .firstWhere((c) => c.id == 'fake-accepted-1')
          .unreadCount,
      2,
    );

    await pumpThread(tester, conversationId: 'fake-accepted-1', repo: repo);
    await tester.pump();

    final after = await repo.fetchConversations();
    expect(
      (after as Ok).value
          .firstWhere((c) => c.id == 'fake-accepted-1')
          .unreadCount,
      0,
    );
  });

  testWidgets('refreshMessages ne bascule pas isLoading', (tester) async {
    final repo = SeededMessagesRepository();
    late ProviderContainer container;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          messagesRepositoryProvider.overrideWithValue(repo),
          profileGateRepositoryProvider.overrideWithValue(
            FakeProfileGateRepository(),
          ),
        ],
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
      container
          .read(conversationThreadControllerProvider('fake-accepted-1'))
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
    expect(find.text('Invitation reçue'), findsOneWidget);
    expect(
      find.text('Thomas Dubois souhaite discuter avec toi.'),
      findsOneWidget,
    );
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('PENDING entrant vide : n\'incite pas à écrire', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          messagesRepositoryProvider.overrideWithValue(
            FakeMessagesRepository(
              conversations: Ok([
                const ConversationSummary(
                  id: 'invite',
                  peerName: 'Sarah Cet-line',
                  status: 'PENDING',
                  isIncomingInvite: true,
                ),
              ]),
            ),
          ),
          profileGateRepositoryProvider.overrideWithValue(
            FakeProfileGateRepository(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const ConversationThreadPage(conversationId: 'invite'),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Invitation reçue'), findsWidgets);
    expect(
      find.textContaining('Sarah Cet-line souhaite discuter avec toi'),
      findsWidgets,
    );
    expect(find.text('Pas encore de messages'), findsNothing);
    expect(
      find.text('Envoie le premier message pour démarrer la conversation.'),
      findsNothing,
    );
    expect(find.text('Accepter'), findsOneWidget);
    expect(find.text('Refuser'), findsOneWidget);
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

  testWidgets('ACCEPTED sans Premium : bandeau au lieu du composer (D29)', (
    tester,
  ) async {
    await pumpThread(
      tester,
      conversationId: 'fake-accepted-1',
      gate: const MemberGateSnapshot(
        isSuspended: false,
        subscriptionStatus: SubscriptionStatus.free,
        onboardingCompleted: true,
      ),
    );

    expect(find.text('Passe Premium pour écrire ici'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);

    await tester.tap(find.text('Passe Premium pour écrire ici'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(PremiumFeatureSheet), findsOneWidget);
  });

  testWidgets('PENDING sortant : en attente', (tester) async {
    await pumpThread(tester, conversationId: 'fake-pending-out');

    expect(find.text('En attente de réponse'), findsOneWidget);
    expect(find.text('Invitation envoyée'), findsOneWidget);
    expect(find.text('Pas encore de messages'), findsNothing);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets(
    'long-press sur mon message propose Supprimer, remplace par le texte',
    (tester) async {
      await pumpThread(tester, conversationId: 'fake-accepted-1');

      // m5 (document, envoyé par moi) - m7 est déjà "Message supprimé"
      // dans le seed, donc on part de findsOneWidget avant suppression.
      expect(find.text('Document'), findsOneWidget);
      expect(find.text('Message supprimé'), findsOneWidget);

      await tester.longPress(find.text('Document'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Supprimer ce message ?'), findsOneWidget);
      await tester.tap(find.text('Supprimer'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Document'), findsNothing);
      expect(find.text('Message supprimé'), findsNWidgets(2));
    },
  );

  testWidgets('joindre ouvre le sheet d\'options : seule Photo est proposée', (
    tester,
  ) async {
    await pumpThread(tester, conversationId: 'fake-accepted-1');

    await tester.tap(find.byTooltip('Joindre'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Photo'), findsOneWidget);
    expect(find.text('Vidéo'), findsNothing);
    // Le fil derrière le sheet contient déjà un message "Document" (seed) :
    // on vérifie qu'il n'y a plus de ListTile "Document" dans le sheet lui-
    // même, pas l'absence globale du texte.
    expect(find.widgetWithText(ListTile, 'Document'), findsNothing);
  });

  test(
    'refreshMessages ne écrase pas une photo déjà hydratée par un refetch '
    'prématuré (race realtime avant que la pièce jointe soit signée)',
    () async {
      final tempFile = await File(
        '${Directory.systemTemp.path}/agapeo-test-${DateTime.now().microsecondsSinceEpoch}.jpg',
      ).create();
      addTearDown(() => tempFile.delete());

      final repo = FakeMessagesRepository(
        conversations: Ok([
          const ConversationSummary(
            id: 'c1',
            peerName: 'Léa',
            status: 'ACCEPTED',
          ),
        ]),
        messages: const Ok([]),
      );
      final container = ProviderContainer(
        overrides: [
          messagesRepositoryProvider.overrideWithValue(repo),
          profileGateRepositoryProvider.overrideWithValue(
            FakeProfileGateRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(
        conversationThreadControllerProvider('c1').notifier,
      );
      await notifier.load();

      await notifier.sendImage(tempFile.path);
      final afterSend = container.read(
        conversationThreadControllerProvider('c1'),
      );
      expect(afterSend.messages.single.mediaUrl, isNotEmpty);

      // Simule le refetch réaliste déclenché par le realtime avant que
      // message_attachments/l'URL signée n'existent côté serveur.
      repo.messages = Ok([
        Message(
          id: afterSend.messages.single.id,
          conversationId: 'c1',
          type: MessageType.image,
          createdAt: afterSend.messages.single.createdAt,
          senderIsMe: true,
        ),
      ]);
      await notifier.refreshMessages();

      final afterRefresh = container.read(
        conversationThreadControllerProvider('c1'),
      );
      expect(afterRefresh.messages.single.mediaUrl, isNotEmpty);
    },
  );

  test(
    'sendImage remplace un placeholder déjà inséré par un refresh prématuré '
    '(race realtime déclenchée avant notre propre réponse hydratée)',
    () async {
      final tempFile = await File(
        '${Directory.systemTemp.path}/agapeo-test-${DateTime.now().microsecondsSinceEpoch}.jpg',
      ).create();
      addTearDown(() => tempFile.delete());

      final repo = FakeMessagesRepository(
        conversations: Ok([
          const ConversationSummary(
            id: 'c1',
            peerName: 'Léa',
            status: 'ACCEPTED',
          ),
        ]),
        messages: const Ok([]),
      );
      final container = ProviderContainer(
        overrides: [
          messagesRepositoryProvider.overrideWithValue(repo),
          profileGateRepositoryProvider.overrideWithValue(
            FakeProfileGateRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(
        conversationThreadControllerProvider('c1').notifier,
      );
      await notifier.load();

      // Le realtime déclenche un refreshMessages() sur notre propre INSERT
      // avant que sendImage() ne reçoive sa réponse hydratée : la ligne
      // existe déjà côté serveur mais sans media_url (upload/URL signée pas
      // encore prêts).
      repo.messages = Ok([
        Message(
          id: 'fake-image-sent',
          conversationId: 'c1',
          type: MessageType.image,
          createdAt: DateTime.now(),
          senderIsMe: true,
        ),
      ]);
      await notifier.refreshMessages();
      final afterPrematureRefresh = container.read(
        conversationThreadControllerProvider('c1'),
      );
      expect(afterPrematureRefresh.messages.single.mediaUrl, isNull);

      // sendImage() reçoit maintenant sa propre réponse, déjà hydratée avec
      // le mediaUrl - elle doit remplacer le placeholder, pas être ignorée.
      await notifier.sendImage(tempFile.path);
      final afterSend = container.read(
        conversationThreadControllerProvider('c1'),
      );
      expect(afterSend.messages.single.mediaUrl, isNotEmpty);
    },
  );

  test(
    'destinataire : une photo encore vide au chargement se résout toute '
    'seule via le retry, sans réponse locale hydratée à recevoir',
    () async {
      final repo = FakeMessagesRepository(
        conversations: Ok([
          const ConversationSummary(
            id: 'c1',
            peerName: 'Léa',
            status: 'ACCEPTED',
          ),
        ]),
        // Le destinataire charge le fil alors que l'INSERT est arrivé mais
        // que message_attachments/l'URL signée ne sont pas encore prêts.
        messages: Ok([
          Message(
            id: 'm1',
            conversationId: 'c1',
            type: MessageType.image,
            createdAt: DateTime.now(),
            senderIsMe: false,
          ),
        ]),
      );
      final container = ProviderContainer(
        overrides: [
          messagesRepositoryProvider.overrideWithValue(repo),
          profileGateRepositoryProvider.overrideWithValue(
            FakeProfileGateRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      // build() planifie déjà load() en microtask - ne pas l'appeler une
      // deuxième fois ici (course entre deux générations qui ferait
      // résoudre cet await avant que l'autre n'ait fini de poser l'état).
      // autoDispose : container.read seul ne garde pas le provider vivant
      // le temps que load() (planifié en microtask par build()) se
      // termine - un listener actif est nécessaire.
      container.listen(
        conversationThreadControllerProvider('c1'),
        (_, _) {},
        fireImmediately: true,
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(
        container
            .read(conversationThreadControllerProvider('c1'))
            .messages
            .single
            .mediaUrl,
        isNull,
      );

      // Le seul déclencheur realtime (INSERT messages) est déjà consommé -
      // rien d'autre ne rafraîchirait jamais sans le filet de secours.
      repo.messages = Ok([
        Message(
          id: 'm1',
          conversationId: 'c1',
          type: MessageType.image,
          createdAt: DateTime.now(),
          senderIsMe: false,
          mediaUrl: 'https://picsum.photos/seed/fake/800/1200',
        ),
      ]);
      // Le retry attend ~1.5s avant de rafraîchir de lui-même.
      await Future<void>.delayed(const Duration(milliseconds: 1800));

      expect(
        container
            .read(conversationThreadControllerProvider('c1'))
            .messages
            .single
            .mediaUrl,
        isNotEmpty,
      );
    },
  );
}
