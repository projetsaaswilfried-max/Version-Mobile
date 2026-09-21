import 'package:agapeo/features/messages/domain/entities/conversation_match.dart';
import 'package:agapeo/features/messages/domain/entities/conversation_summary.dart';
import 'package:agapeo/features/messages/domain/match/match_banner_mode.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const accepted = ConversationSummary(id: 'c', peerName: 'Léa');
  const pendingInvite = ConversationSummary(
    id: 'p',
    peerName: 'Thomas',
    status: 'PENDING',
    isIncomingInvite: true,
  );
  const system = ConversationSummary(
    id: 's',
    peerName: 'Agapeo',
    isSystem: true,
  );

  test('hidden si système ou invitation PENDING', () {
    expect(
      matchBannerMode(conversation: system, match: ConversationMatch.none),
      MatchBannerMode.hidden,
    );
    expect(
      matchBannerMode(
        conversation: pendingInvite,
        match: ConversationMatch.none,
      ),
      MatchBannerMode.hidden,
    );
  });

  test('modes selon match sur ACCEPTED', () {
    expect(
      matchBannerMode(conversation: accepted, match: ConversationMatch.none),
      MatchBannerMode.propose,
    );
    expect(
      matchBannerMode(
        conversation: accepted,
        match: const ConversationMatch(
          status: ConversationMatchStatus.pending,
        ),
      ),
      MatchBannerMode.pendingOutgoing,
    );
    expect(
      matchBannerMode(
        conversation: accepted,
        match: const ConversationMatch(
          status: ConversationMatchStatus.pending,
          isIncoming: true,
        ),
      ),
      MatchBannerMode.pendingIncoming,
    );
    expect(
      matchBannerMode(
        conversation: accepted,
        match: const ConversationMatch(
          status: ConversationMatchStatus.accepted,
        ),
      ),
      MatchBannerMode.accepted,
    );
  });
}
