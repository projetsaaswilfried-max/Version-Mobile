import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../data/datasources/supabase_support_datasource.dart';
import '../data/repositories/support_repository_impl.dart';
import '../domain/repositories/support_repository.dart';

final supportRepositoryProvider = Provider<SupportRepository>((ref) {
  return SupportRepositoryImpl(
    SupabaseSupportDataSource(ref.watch(supabaseClientProvider)),
  );
});
