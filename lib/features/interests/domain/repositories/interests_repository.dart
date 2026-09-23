import '../../../../core/error/result.dart';
import '../entities/interest.dart';

abstract class InterestsRepository {
  Future<Result<List<Interest>>> fetchAll();
}
