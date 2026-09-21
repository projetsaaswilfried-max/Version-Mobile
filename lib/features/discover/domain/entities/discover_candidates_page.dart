import 'package:equatable/equatable.dart';

import 'discover_profile.dart';

/// Une page de candidats bruts (avant filtrage d'éligibilité), avec
/// indication si le serveur a potentiellement d'autres lignes au-delà.
class DiscoverCandidatesPage extends Equatable {
  const DiscoverCandidatesPage({required this.profiles, required this.hasMore});

  final List<DiscoverProfile> profiles;
  final bool hasMore;

  @override
  List<Object?> get props => [profiles, hasMore];
}
