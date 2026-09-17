import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_environment.dart';
import '../../../core/di/providers.dart';
import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../data/datasources/supabase_profile_gate_datasource.dart';
import '../data/repositories/profile_gate_repository_impl.dart';
import '../domain/entities/member_gate_snapshot.dart';
import '../domain/repositories/profile_gate_repository.dart';
import '../domain/usecases/resolve_post_login_route.dart';

final profileGateRepositoryProvider = Provider<ProfileGateRepository>((ref) {
  final env = AppEnvironment.current;
  if (env.supabaseUrl.isEmpty || env.supabaseAnonKey.isEmpty) {
    return const _UnconfiguredProfileGateRepository();
  }
  return ProfileGateRepositoryImpl(
    SupabaseProfileGateDataSource(ref.watch(supabaseClientProvider)),
  );
});

final resolvePostLoginRouteProvider = Provider(
  (_) => const ResolvePostLoginRoute(),
);

/// Used when [main] skips [Supabase.initialize] (missing dart-defines).
///
/// Returns [Err] rather than throwing: a thrown exception here would escape
/// uncaught past callers that only handle [Result].
class _UnconfiguredProfileGateRepository implements ProfileGateRepository {
  const _UnconfiguredProfileGateRepository();

  static const _failure = ServerFailure(
    'Supabase non configuré : lance avec --dart-define=SUPABASE_URL=... '
    '--dart-define=SUPABASE_ANON_KEY=...',
  );

  @override
  Future<Result<MemberGateSnapshot>> fetchGate() async => const Err(_failure);
}
