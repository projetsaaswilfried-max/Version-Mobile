import 'package:equatable/equatable.dart';

import 'discover_profile.dart';
import 'visitor_context.dart';

class DiscoverPage extends Equatable {
  const DiscoverPage({
    required this.recommended,
    required this.others,
    required this.visitor,
    this.hasMoreCandidates = false,
  });

  final List<DiscoverProfile> recommended;
  final List<DiscoverProfile> others;
  final VisitorContext visitor;

  /// Le serveur a peut-être d'autres candidats au-delà de la première page
  /// (voir `GetDiscoverPage.serverBatchSize`).
  final bool hasMoreCandidates;

  bool get expired => visitor.isExpired;
  bool get visitorVerified => visitor.isVerified;
  String get subscriptionStatus => visitor.subscriptionStatus;
  bool get visitorIsStaff => visitor.isStaff;
  bool get visitorTraitsIncomplete =>
      hasIncompleteCompatibilityTraits(visitor.traits);

  @override
  List<Object?> get props => [recommended, others, visitor, hasMoreCandidates];
}
