import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/app_environment.dart';
import 'core/theme/app_theme.dart';
import 'features/onboarding/presentation/splash/splash_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppEnvironment.init();

  final env = AppEnvironment.current;
  if (env.supabaseUrl.isNotEmpty && env.supabaseAnonKey.isNotEmpty) {
    await Supabase.initialize(url: env.supabaseUrl, publishableKey: env.supabaseAnonKey);
  }

  runApp(const ProviderScope(child: AgapeoApp()));
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
