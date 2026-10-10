import 'dart:io';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Kill-switch Premium iOS piloté par Firebase Remote Config (Apple a
/// rejeté l'app pour vente de contenu payant hors In-App Purchase -
/// guideline 3.1.3b - en attendant une vraie intégration StoreKit/
/// RevenueCat, ce flag permet de masquer tout ce qui concerne le Premium
/// côté iOS sans redéployer).
///
/// Deux paramètres distincts :
/// - [_enabledKey] : interrupteur métier global (actif/inactif pour tous
///   les users iOS).
/// - [_reviewPinKey] : numéro de version (`CFBundleShortVersionString`,
///   ex. "1.1.2") actuellement en review chez Apple - si la version de
///   l'app en cours d'exécution correspond, le Premium est **forcé off**,
///   même si [_enabledKey] est à true. Permet de garder le Premium actif
///   pour les users déjà publiés pendant qu'une nouvelle version est en
///   cours de revue avec le flag désactivé.
class PremiumRemoteConfig {
  const PremiumRemoteConfig._();

  static const _enabledKey = 'premium_ios_enabled';
  static const _reviewPinKey = 'premium_ios_review_pin';

  /// Initialise Remote Config et calcule si les paiements Premium doivent
  /// être affichés sur cet appareil. Ne bloque jamais le démarrage -
  /// retombe sur `true` (Android toujours `true`) si Remote Config est
  /// injoignable.
  static Future<bool> resolvePremiumPaymentsEnabled() async {
    if (!Platform.isIOS) return true;
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: const Duration(minutes: 15),
        ),
      );
      await remoteConfig.setDefaults(const {_enabledKey: true, _reviewPinKey: ''});
      await remoteConfig.fetchAndActivate();

      final reviewPin = remoteConfig.getString(_reviewPinKey).trim();
      if (reviewPin.isNotEmpty) {
        final packageInfo = await PackageInfo.fromPlatform();
        if (reviewPin == packageInfo.version) return false;
      }
      return remoteConfig.getBool(_enabledKey);
    } catch (_) {
      // Pas de réseau / config indisponible au démarrage - ne jamais
      // bloquer l'app, on retombe sur le comportement normal (Premium
      // affiché) plutôt que de risquer un faux-négatif permanent.
      return true;
    }
  }
}
