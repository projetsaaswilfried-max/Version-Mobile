/// Build-time configuration, injected via `--dart-define` (see flavors below).
///
/// No staging Supabase project is confirmed yet (docs/decisions.md Q4) —
/// [dev] and [prod] currently point at the same project until one exists.
enum AppFlavor { dev, prod }

class AppEnvironment {
  const AppEnvironment._({
    required this.flavor,
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.apiBaseUrl,
  });

  final AppFlavor flavor;
  final String supabaseUrl;
  final String supabaseAnonKey;
  final String apiBaseUrl;

  static late final AppEnvironment current;

  static void init() {
    const flavorName = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
    current = AppEnvironment._(
      flavor: AppFlavor.values.firstWhere(
        (f) => f.name == flavorName,
        orElse: () => AppFlavor.dev,
      ),
      supabaseUrl: const String.fromEnvironment('SUPABASE_URL'),
      supabaseAnonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
      apiBaseUrl: const String.fromEnvironment('API_BASE_URL'),
    );
  }

  bool get isProd => flavor == AppFlavor.prod;

  /// False when dart-defines are missing (local UI without backend).
  bool get hasSupabase =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
