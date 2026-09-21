import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../data/datasources/supabase_safety_datasource.dart';
import '../data/repositories/safety_repository_impl.dart';
import '../domain/repositories/safety_repository.dart';

final safetyRepositoryProvider = Provider<SafetyRepository>((ref) {
  return SafetyRepositoryImpl(
    SupabaseSafetyDataSource(ref.watch(supabaseClientProvider)),
  );
});
