import '../../../../core/error/map_data_exception.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/interest.dart';
import '../../domain/repositories/interests_repository.dart';
import '../datasources/supabase_interests_datasource.dart';

class InterestsRepositoryImpl implements InterestsRepository {
  InterestsRepositoryImpl(this._remote);

  final SupabaseInterestsDataSource _remote;

  @override
  Future<Result<List<Interest>>> fetchAll() async {
    try {
      return Ok(await _remote.fetchAll());
    } catch (error) {
      return Err(mapDataException(error));
    }
  }
}
