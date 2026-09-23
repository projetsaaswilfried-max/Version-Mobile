import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../data/datasources/supabase_device_tokens_datasource.dart';
import '../data/repositories/device_tokens_repository_impl.dart';
import '../domain/repositories/device_tokens_repository.dart';

final deviceTokensRepositoryProvider = Provider<DeviceTokensRepository>((
  ref,
) {
  return DeviceTokensRepositoryImpl(
    SupabaseDeviceTokensDataSource(ref.watch(supabaseClientProvider)),
  );
});
