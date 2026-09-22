import 'package:agapeo/features/messages/domain/composer/thread_composer_mode.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ACCEPTED and premium → canCompose', () {
    expect(
      threadComposerMode(
        status: 'ACCEPTED',
        isSystem: false,
        isIncomingInvite: false,
        isPremiumActive: true,
      ),
      ThreadComposerMode.canCompose,
    );
  });

  test('ACCEPTED without premium → premiumRequired (D29)', () {
    expect(
      threadComposerMode(
        status: 'ACCEPTED',
        isSystem: false,
        isIncomingInvite: false,
        isPremiumActive: false,
      ),
      ThreadComposerMode.premiumRequired,
    );
  });

  test('PENDING entrant → inviteActions, quel que soit le premium', () {
    expect(
      threadComposerMode(
        status: 'PENDING',
        isSystem: false,
        isIncomingInvite: true,
        isPremiumActive: false,
      ),
      ThreadComposerMode.inviteActions,
    );
  });

  test('PENDING sortant → waitingPeer, quel que soit le premium', () {
    expect(
      threadComposerMode(
        status: 'PENDING',
        isSystem: false,
        isIncomingInvite: false,
        isPremiumActive: false,
      ),
      ThreadComposerMode.waitingPeer,
    );
  });

  test('système → readOnlySystem, quel que soit le premium', () {
    expect(
      threadComposerMode(
        status: 'ACCEPTED',
        isSystem: true,
        isIncomingInvite: false,
        isPremiumActive: false,
      ),
      ThreadComposerMode.readOnlySystem,
    );
  });
}
