import 'package:agapeo/features/messages/data/models/conversation_match_model.dart';
import 'package:agapeo/features/messages/domain/entities/conversation_match.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PENDING entrant si proposer ≠ moi', () {
    final match = ConversationMatchModel.fromRow(
      row: {
        'id': 'm1',
        'status': 'PENDING',
        'proposer_id': 'other',
      },
      currentUserId: 'me',
    );
    expect(match.status, ConversationMatchStatus.pending);
    expect(match.isIncoming, isTrue);
  });

  test('ACCEPTED', () {
    final match = ConversationMatchModel.fromRow(
      row: {'id': 'm1', 'status': 'ACCEPTED', 'proposer_id': 'me'},
      currentUserId: 'me',
    );
    expect(match.status, ConversationMatchStatus.accepted);
    expect(match.isIncoming, isFalse);
  });

  test('CANCELLED → none', () {
    final match = ConversationMatchModel.fromRow(
      row: {'id': 'm1', 'status': 'CANCELLED'},
      currentUserId: 'me',
    );
    expect(match, ConversationMatch.none);
  });
}
