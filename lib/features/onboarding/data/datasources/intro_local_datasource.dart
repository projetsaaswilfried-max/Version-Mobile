import 'package:shared_preferences/shared_preferences.dart';

class IntroLocalDataSource {
  IntroLocalDataSource(this._prefs);

  static const _key = 'agapeo_intro_seen';

  final SharedPreferences _prefs;

  Future<bool> isSeen() async => _prefs.getBool(_key) ?? false;

  Future<void> markSeen() async => _prefs.setBool(_key, true);
}
