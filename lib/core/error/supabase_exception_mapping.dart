import 'dart:developer' as developer;

import 'package:supabase_flutter/supabase_flutter.dart';

import 'exceptions.dart';

Exception mapSupabaseAuthException(AuthException e) {
  final msg = e.message.toLowerCase();
  if (msg.contains('network') || msg.contains('socket')) {
    return NetworkException(e.message);
  }
  if (e.statusCode == '401' || msg.contains('jwt') || msg.contains('session')) {
    return UnauthorizedException(
      e.message.trim().isEmpty ? 'Session expirée.' : e.message,
    );
  }
  return e.message.trim().isEmpty
      ? const ServerException('Une erreur serveur est survenue.')
      : ServerException(e.message);
}

Exception mapPostgrestException(PostgrestException e) {
  final code = e.code;
  if (code == 'PGRST301' || code == '42501') {
    return UnauthorizedException(
      e.message.trim().isEmpty ? 'Session expirée.' : e.message,
    );
  }
  final msg = e.message.toLowerCase();
  if (msg.contains('network') || msg.contains('socket')) {
    return NetworkException(e.message);
  }
  return e.message.trim().isEmpty
      ? const ServerException('Une erreur serveur est survenue.')
      : ServerException(e.message);
}

/// Maps [StorageException] and always logs bucket / path / status for debug.
Exception mapStorageException(
  StorageException e, {
  required String bucket,
  String? objectPath,
  String operation = 'upload',
}) {
  developer.log(
    'Storage $operation failed — bucket="$bucket" path="$objectPath" '
    'statusCode=${e.statusCode} error=${e.error} message=${e.message}',
    name: 'supabase.storage',
    error: e,
  );

  final haystack = '${e.message} ${e.error ?? ''} ${e.statusCode ?? ''}'
      .toLowerCase();
  final bucketMissing =
      haystack.contains('bucket not found') ||
      haystack.contains('no such bucket') ||
      haystack.contains('no bucket') ||
      (haystack.contains('bucket') && haystack.contains('not found'));

  if (bucketMissing) {
    return ServerException(
      'Bucket Storage introuvable : "$bucket". '
      'Ouvre Supabase → Storage et crée ce bucket, '
      'ou aligne le nom (PRD §21 : "avatars"). '
      'Détail: ${e.message}',
    );
  }

  final detail = StringBuffer(e.message.trim());
  if (e.error != null && e.error!.trim().isNotEmpty) {
    detail.write(' (${e.error})');
  }
  if (e.statusCode != null && e.statusCode!.trim().isNotEmpty) {
    detail.write(' [${e.statusCode}]');
  }
  final text = detail.toString().trim();
  return ServerException(
    text.isEmpty ? 'Impossible d\'envoyer le fichier (Storage).' : text,
  );
}

Exception mapUnknownSupabase(Object e) {
  // Déjà mappé par un _guard()/try-catch imbriqué (ex. une méthode de
  // datasource qui en appelle une autre, elle-même déjà gardée) - relancer
  // tel quel, sinon le fallback ci-dessous fait e.toString() sur l'objet
  // et affiche "Instance of 'ServerException'" au lieu du vrai message.
  if (e is ServerException ||
      e is NetworkException ||
      e is ValidationException ||
      e is UnauthorizedException ||
      e is EmailNotConfirmedException ||
      e is CacheException) {
    return e as Exception;
  }
  final msg = e.toString();
  developer.log(
    'Unknown Supabase error: $msg',
    name: 'supabase',
    error: e,
  );
  if (msg.toLowerCase().contains('socket') ||
      msg.toLowerCase().contains('network')) {
    return NetworkException(msg);
  }
  return ServerException(msg);
}
