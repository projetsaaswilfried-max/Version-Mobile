import '../../../../core/config/debug_flags.dart';

String maskIdentity(String raw) {
  if (raw.isEmpty) return '**';
  final end = raw.length < 2 ? raw.length : 2;
  return '${raw.substring(0, end)}****';
}

bool revealCardIdentity({required bool visitorVerified}) {
  if (kBypassPremiumGatesForTesting) return true;
  return visitorVerified;
}
