import 'package:dio/dio.dart';

import '../../security/secure_token_store.dart';

/// Attaches the bearer token to every request, and on a 401 attempts one
/// silent refresh (via [onRefresh]) before retrying the original request.
/// Clears the token store and lets the 401 through if the refresh fails.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required Dio dio,
    required SecureTokenStore tokenStore,
    required Future<String?> Function(String refreshToken) onRefresh,
  }) : _dio = dio,
       _tokenStore = tokenStore,
       _onRefresh = onRefresh;

  final Dio _dio;
  final SecureTokenStore _tokenStore;
  final Future<String?> Function(String refreshToken) _onRefresh;

  bool _isRefreshing = false;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _tokenStore.readAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final isUnauthorized = err.response?.statusCode == 401;
    if (!isUnauthorized || _isRefreshing) {
      handler.next(err);
      return;
    }

    final refreshToken = await _tokenStore.readRefreshToken();
    if (refreshToken == null) {
      await _tokenStore.clear();
      handler.next(err);
      return;
    }

    _isRefreshing = true;
    try {
      final newAccessToken = await _onRefresh(refreshToken);
      if (newAccessToken == null) {
        await _tokenStore.clear();
        handler.next(err);
        return;
      }

      final retryOptions = err.requestOptions
        ..headers['Authorization'] = 'Bearer $newAccessToken';
      final response = await _dio.fetch(retryOptions);
      handler.resolve(response);
    } catch (_) {
      await _tokenStore.clear();
      handler.next(err);
    } finally {
      _isRefreshing = false;
    }
  }
}
