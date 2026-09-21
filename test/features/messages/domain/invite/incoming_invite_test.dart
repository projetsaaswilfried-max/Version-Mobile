import 'package:agapeo/features/messages/domain/invite/incoming_invite.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PENDING destinataire is an incoming invite', () {
    expect(
      isIncomingConversationInvite(
        status: 'PENDING',
        currentUserId: 'me',
        initiatorId: 'them',
      ),
      isTrue,
    );
  });

  test('PENDING initiateur is not incoming', () {
    expect(
      isIncomingConversationInvite(
        status: 'pending',
        currentUserId: 'me',
        initiatorId: 'me',
      ),
      isFalse,
    );
  });

  test('ACCEPTED is never an incoming invite', () {
    expect(
      isIncomingConversationInvite(
        status: 'ACCEPTED',
        currentUserId: 'me',
        initiatorId: 'them',
      ),
      isFalse,
    );
  });

  test('PENDING without initiator is not shown as incoming', () {
    expect(
      isIncomingConversationInvite(
        status: 'PENDING',
        currentUserId: 'me',
        initiatorId: null,
      ),
      isFalse,
    );
  });
}
