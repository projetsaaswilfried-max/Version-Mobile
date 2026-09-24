import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../data/datasources/supabase_premium_checkout_datasource.dart';
import '../data/repositories/premium_checkout_repository_impl.dart';
import '../domain/repositories/premium_checkout_repository.dart';

final premiumCheckoutRepositoryProvider = Provider<PremiumCheckoutRepository>(
  (ref) {
    return PremiumCheckoutRepositoryImpl(
      SupabasePremiumCheckoutDataSource(ref.watch(supabaseClientProvider)),
    );
  },
);
