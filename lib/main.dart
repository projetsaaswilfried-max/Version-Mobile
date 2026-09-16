import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/app_environment.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/datasources/age_gate_local_datasource.dart';
import 'features/auth/data/repositories/age_gate_store_impl.dart';
import 'features/auth/di/auth_providers.dart';
import 'features/onboarding/presentation/splash/splash_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppEnvironment.init();

  final env = AppEnvironment.current;
  if (env.supabaseUrl.isNotEmpty && env.supabaseAnonKey.isNotEmpty) {
    await Supabase.initialize(
      url: env.supabaseUrl,
      publishableKey: env.supabaseAnonKey,
    );
  }

  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [
        ageGateStoreProvider.overrideWithValue(
          AgeGateStoreImpl(AgeGateLocalDataSource(prefs)),
        ),
      ],
      child: const AgapeoApp(),
    ),
  );
}

class AgapeoApp extends StatelessWidget {
  const AgapeoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Agapeo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const SplashPage(),
    );
  }
}
