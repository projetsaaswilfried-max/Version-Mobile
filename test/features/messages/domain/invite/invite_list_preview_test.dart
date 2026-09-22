import 'package:agapeo/features/messages/domain/invite/invite_list_preview.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('incoming PENDING always uses the web copy', () {
    expect(
      conversationListPreview(
        status: 'PENDING',
        isIncomingInvite: true,
        isSystem: false,
        lastMessage: 'Bonjour, j\'aimerais faire connaissance.',
      ),
      kIncomingInvitePreview,
    );
  });

  test('outgoing PENDING keeps last message or falls back', () {
    expect(
      conversationListPreview(
        status: 'PENDING',
        isIncomingInvite: false,
        isSystem: false,
        lastMessage: 'Salut, on discute ?',
      ),
      'Salut, on discute ?',
    );
    expect(
      conversationListPreview(
        status: 'PENDING',
        isIncomingInvite: false,
        isSystem: false,
        lastMessage: null,
      ),
      kOutgoingInvitePreview,
    );
  });

  test('incoming headline includes the peer name', () {
    expect(
      incomingInviteHeadline('Sarah Cet-line'),
      'Sarah Cet-line souhaite discuter avec toi.',
    );
    expect(
      incomingInviteHeadline('  '),
      'Cette personne souhaite discuter avec toi.',
    );
  });

  test('ACCEPTED and system keep the last message', () {
    expect(
      conversationListPreview(
        status: 'ACCEPTED',
        isIncomingInvite: false,
        isSystem: false,
        lastMessage: 'ok',
      ),
      'ok',
    );
    expect(
      conversationListPreview(
        status: 'ACCEPTED',
        isIncomingInvite: false,
        isSystem: true,
        lastMessage: 'Bienvenue',
      ),
      'Bienvenue',
    );
  });
}
