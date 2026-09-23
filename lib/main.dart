import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/app_environment.dart';
import 'core/navigation/root_navigator.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/datasources/age_gate_local_datasource.dart';
import 'features/auth/data/repositories/age_gate_store_impl.dart';
import 'features/auth/di/auth_providers.dart';
import 'features/auth/presentation/deep_link/auth_deep_link_listener.dart';
import 'features/onboarding/data/datasources/intro_local_datasource.dart';
import 'features/onboarding/data/repositories/intro_store_impl.dart';
import 'features/onboarding/di/onboarding_providers.dart';
import 'features/onboarding/presentation/splash/splash_page.dart';
import 'features/push_notifications/presentation/push_notifications_listener.dart';
import 'firebase_options.dart';

/// Isolate séparé (arrière-plan) - ne fait rien de plus qu'initialiser
/// Firebase pour que le plugin puisse traiter le message sans planter.
/// Pas de bannière locale (décision produit : premier plan sans popup,
/// même logique en arrière-plan).
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppEnvironment.init();

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (_) {
    // Config native absente (ex. build sans google-services.json) - ne
    // doit jamais empêcher le reste de l'app de démarrer.
  }

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
        introStoreProvider.overrideWithValue(
          IntroStoreImpl(IntroLocalDataSource(prefs)),
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
      locale: const Locale('fr'),
      supportedLocales: const [Locale('fr')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      navigatorKey: rootNavigatorKey,
      builder: (context, child) {
        return PushNotificationsListener(
          child: AuthDeepLinkListener(child: child ?? const SizedBox.shrink()),
        );
      },
      home: const SplashPage(),
    );
  }
}
