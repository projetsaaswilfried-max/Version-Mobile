import '../../../../core/error/result.dart';
import '../entities/my_profile.dart';

abstract class MyProfileRepository {
  Future<Result<MyProfile>> fetchMine();

  Future<Result<void>> save(MyProfile profile, {required bool savePhotos});
}
