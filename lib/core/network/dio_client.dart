import 'package:dio/dio.dart';

import '../security/secure_token_store.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/logging_interceptor.dart';
import 'interceptors/retry_interceptor.dart';

/// Builds the configured Dio instance for the Agapeo API client.
///
/// [onRefresh] performs the token refresh network call — passed in
/// rather than owned here so this stays free of any feature-specific
/// (auth repository) dependency.
class DioClient {
  const DioClient._();

  static Dio build({
    required String baseUrl,
    required SecureTokenStore tokenStore,
    required Future<String?> Function(String refreshToken) onRefresh,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ),
    );

    dio.interceptors.addAll([
      AuthInterceptor(dio: dio, tokenStore: tokenStore, onRefresh: onRefresh),
      RetryInterceptor(dio: dio),
      LoggingInterceptor(),
    ]);

    return dio;
  }
}
