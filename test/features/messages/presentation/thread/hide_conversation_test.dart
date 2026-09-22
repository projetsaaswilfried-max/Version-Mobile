import 'package:agapeo/core/error/result.dart';
import 'package:agapeo/features/messages/data/repositories/seeded_messages_repository.dart';
import 'package:agapeo/features/messages/domain/entities/conversation_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // hideConversation() reste utilisé en interne par le flux Bloquer - le
  // point d'entrée autonome "Masquer la discussion" a été retiré du sheet
  // Options (plus de moyen de la faire réapparaître depuis l'app).
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
}
