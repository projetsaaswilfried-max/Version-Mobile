import 'package:agapeo/core/config/app_environment.dart';
import 'package:agapeo/core/error/result.dart';
import 'package:agapeo/features/messages/di/messages_providers.dart';
import 'package:agapeo/features/messages/domain/entities/conversation_summary.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/messages_test_fakes.dart';

void main() {
  setUpAll(AppEnvironment.init);

  test('getConversationsProvider forwards to repository', () async {
    final repo = FakeMessagesRepository(
      conversations: Ok([const ConversationSummary(id: 'c1', peerName: 'Léa')]),
    );
    final container = ProviderContainer(
      overrides: [messagesRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    final result = await container.read(getConversationsProvider)();
    expect(result, isA<Ok>());
    expect(repo.fetchConversationsCalls, 1);
  });

  test('flag fakes désactivé (liste live slice A)', () {
    expect(kUseFakeMessagesConversations, isFalse);
  });

  test('sans Supabase configuré → UnconfiguredMessagesRepository', () {
    // AppEnvironment.init sans dart-define → url/key vides en test.
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(
      container.read(messagesRepositoryProvider),
      isA<UnconfiguredMessagesRepository>(),
    );
  });
}
