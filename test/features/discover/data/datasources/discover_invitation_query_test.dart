import 'package:agapeo/features/discover/data/datasources/discover_invitation_query.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('RPC attempts use participant_id then other_user_id, with message', () {
    expect(
      discoverInvitationRpcParamAttempts(
        profileId: 'p-1',
        message: '  Bonjour  ',
      ),
      [
        {'participant_id': 'p-1', 'message': 'Bonjour'},
        {'participant_id': 'p-1'},
        {'other_user_id': 'p-1', 'message': 'Bonjour'},
        {'other_user_id': 'p-1'},
      ],
    );
  });

  test('RPC attempts omit message when blank', () {
    expect(
      discoverInvitationRpcParamAttempts(profileId: 'p-1', message: '  '),
      [
        {'participant_id': 'p-1'},
        {'other_user_id': 'p-1'},
      ],
    );
  });
}
