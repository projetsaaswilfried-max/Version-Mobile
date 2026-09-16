import 'package:shared_preferences/shared_preferences.dart';

class AgeGateLocalDataSource {
  AgeGateLocalDataSource(this._prefs);

  static const _key = 'agapeo_age_gate_accepted';

  final SharedPreferences _prefs;

  Future<bool> isAccepted() async => (_prefs.getBool(_key)) ?? false;

  Future<void> accept() async => _prefs.setBool(_key, true);
}
