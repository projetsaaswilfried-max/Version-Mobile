import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/error/result.dart';
import '../data/datasources/supabase_interests_datasource.dart';
import '../data/repositories/interests_repository_impl.dart';
import '../domain/entities/interest.dart';
import '../domain/repositories/interests_repository.dart';

final interestsRepositoryProvider = Provider<InterestsRepository>((ref) {
  return InterestsRepositoryImpl(
    SupabaseInterestsDataSource(ref.watch(supabaseClientProvider)),
  );
});

/// Table de référence (peu de lignes, change rarement) : pas d'`autoDispose`,
/// on la garde en cache pour la session une fois chargée.
final interestsListProvider = FutureProvider<List<Interest>>((ref) async {
  final result = await ref.watch(interestsRepositoryProvider).fetchAll();
  return switch (result) {
    Ok<List<Interest>>(:final value) => value,
    Err<List<Interest>>() => const [],
  };
});
