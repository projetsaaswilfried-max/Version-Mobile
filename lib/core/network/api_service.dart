import 'package:dio/dio.dart';

import '../error/exceptions.dart';

/// Thin wrapper around [Dio] used by `data/datasources`. Normalizes every
/// [DioException] into a typed exception from core/error — datasources
/// never handle Dio directly, and never catch anything themselves; the
/// repository implementation catches these and maps them to a [Failure].
class ApiService {
  const ApiService(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? query}) {
    return _request(() => _dio.get(path, queryParameters: query));
  }

  Future<Map<String, dynamic>> post(String path, {Object? data}) {
    return _request(() => _dio.post(path, data: data));
  }

  Future<Map<String, dynamic>> put(String path, {Object? data}) {
    return _request(() => _dio.put(path, data: data));
  }

  Future<Map<String, dynamic>> patch(String path, {Object? data}) {
    return _request(() => _dio.patch(path, data: data));
  }

  Future<Map<String, dynamic>> delete(String path, {Object? data}) {
    return _request(() => _dio.delete(path, data: data));
  }

  Future<Map<String, dynamic>> _request(
    Future<Response<dynamic>> Function() call,
  ) async {
    try {
      final response = await call();
      final body = response.data;
      if (body is Map<String, dynamic>) return body;
      return <String, dynamic>{};
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  Exception _mapError(DioException error) {
    final statusCode = error.response?.statusCode;

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return const NetworkException();
      default:
        break;
    }

    if (statusCode == 401 || statusCode == 403) {
      return const UnauthorizedException();
    }
    if (statusCode == 422 && error.response?.data is Map<String, dynamic>) {
      final data = error.response!.data as Map<String, dynamic>;
      return ValidationException(
        data['message']?.toString() ?? 'Validation échouée.',
        fieldErrors: (data['errors'] as Map<String, dynamic>?)?.map(
          (key, value) => MapEntry(key, value.toString()),
        ),
      );
    }
    return ServerException(
      error.response?.data?.toString() ?? error.message ?? 'Erreur serveur.',
      statusCode: statusCode,
    );
  }
}
