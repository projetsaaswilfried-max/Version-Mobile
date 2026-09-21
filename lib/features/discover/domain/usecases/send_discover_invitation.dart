import '../../../../core/error/result.dart';
import '../repositories/discover_repository.dart';

class SendDiscoverInvitation {
  const SendDiscoverInvitation(this._repo);

  final DiscoverRepository _repo;

  Future<Result<void>> call({
    required String profileId,
    String? message,
  }) =>
      _repo.sendInvitation(profileId: profileId, message: message);
}
