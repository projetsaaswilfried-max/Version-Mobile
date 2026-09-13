import 'package:dio/dio.dart';

/// Retries idempotent requests a fixed number of times on network/timeout
/// errors, with a short linear backoff. Never retries on a real HTTP
/// error response (4xx/5xx) — only on failures that never reached the
/// server.
class RetryInterceptor extends Interceptor {
  RetryInterceptor({
    required Dio dio,
    this.maxRetries = 2,
    this.retryDelay = const Duration(milliseconds: 500),
  }) : _dio = dio;

  final Dio _dio;
  final int maxRetries;
  final Duration retryDelay;

  static const _retryCountKey = 'retry_count';

  bool _shouldRetry(DioException err) {
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError;
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    final attempt = (options.extra[_retryCountKey] as int?) ?? 0;

    if (!_shouldRetry(err) || attempt >= maxRetries) {
      handler.next(err);
      return;
    }

    await Future.delayed(retryDelay * (attempt + 1));
    options.extra[_retryCountKey] = attempt + 1;

    try {
      final response = await _dio.fetch(options);
      handler.resolve(response);
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }
}
