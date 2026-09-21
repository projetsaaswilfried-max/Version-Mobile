import 'package:agapeo/features/messages/domain/entities/conversation_summary.dart';
import 'package:agapeo/features/messages/domain/filtering/filter_conversations.dart';
import 'package:flutter_test/flutter_test.dart';

ConversationSummary _item({
  required String id,
  required String peerName,
  String? preview,
}) {
  return ConversationSummary(id: id, peerName: peerName, preview: preview);
}

void main() {
  final items = [
    _item(id: '1', peerName: 'Léa Martin', preview: 'Salut, comment vas-tu ?'),
    _item(id: '2', peerName: 'Paul', preview: 'Rendez-vous dimanche'),
  ];

  test('empty query keeps the list', () {
    expect(filterConversations(items, '  '), items);
  });

  test('filters on peer name ignoring case', () {
    expect(filterConversations(items, 'léa').map((c) => c.id), ['1']);
  });

  test('filters on preview text', () {
    expect(filterConversations(items, 'dimanche').map((c) => c.id), ['2']);
  });
}
