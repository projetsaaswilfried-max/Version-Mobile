import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_environment.dart';
import '../network/api_service.dart';
import '../network/dio_client.dart';
import '../security/secure_token_store.dart';

/// Global, app-wide providers. Feature-scoped providers live inside their
/// own feature folder instead.

final secureTokenStoreProvider = Provider<SecureTokenStore>((ref) {
  return SecureTokenStore();
});

/// Supabase's own client — session persistence/refresh is handled by the
/// SDK itself (see `Supabase.initialize` in main.dart), independent of
/// [secureTokenStoreProvider].
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final dioProvider = Provider<Dio>((ref) {
  final tokenStore = ref.watch(secureTokenStoreProvider);
  return DioClient.build(
    baseUrl: AppEnvironment.current.apiBaseUrl,
    tokenStore: tokenStore,
    onRefresh: (refreshToken) => _refreshAccessToken(tokenStore, refreshToken),
  );
});

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService(ref.watch(dioProvider));
});

/// Performs the refresh call on a bare Dio instance (no interceptors, to
/// avoid recursing back into [AuthInterceptor]) and persists the new pair
/// of tokens. Returns null on failure so the caller can fall back to a
/// logout.
Future<String?> _refreshAccessToken(SecureTokenStore tokenStore, String refreshToken) async {
  try {
    final response = await Dio(BaseOptions(baseUrl: AppEnvironment.current.apiBaseUrl)).post(
      '/auth/refresh',
      data: {'refresh_token': refreshToken},
    );
    final data = response.data as Map<String, dynamic>;
    final accessToken = data['access_token'] as String;
    final newRefreshToken = data['refresh_token'] as String;
    await tokenStore.saveTokens(accessToken: accessToken, refreshToken: newRefreshToken);
    return accessToken;
  } catch (_) {
    return null;
  }
}
