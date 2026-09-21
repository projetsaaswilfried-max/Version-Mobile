import 'package:agapeo/features/messages/domain/composer/thread_composer_mode.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ACCEPTED → canCompose', () {
    expect(
      threadComposerMode(
        status: 'ACCEPTED',
        isSystem: false,
        isIncomingInvite: false,
      ),
      ThreadComposerMode.canCompose,
    );
  });

  test('PENDING entrant → inviteActions', () {
    expect(
      threadComposerMode(
        status: 'PENDING',
        isSystem: false,
        isIncomingInvite: true,
      ),
      ThreadComposerMode.inviteActions,
    );
  });

  test('PENDING sortant → waitingPeer', () {
    expect(
      threadComposerMode(
        status: 'PENDING',
        isSystem: false,
        isIncomingInvite: false,
      ),
      ThreadComposerMode.waitingPeer,
    );
  });

  test('système → readOnlySystem', () {
    expect(
      threadComposerMode(
        status: 'ACCEPTED',
        isSystem: true,
        isIncomingInvite: false,
      ),
      ThreadComposerMode.readOnlySystem,
    );
  });
}
