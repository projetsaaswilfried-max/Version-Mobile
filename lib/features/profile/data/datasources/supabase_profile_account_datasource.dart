import 'dart:convert';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/supabase_exception_mapping.dart';
import '../../../../core/parsing/json.dart';
import '../../domain/entities/account_person.dart';
import '../../domain/entities/faith_details.dart';
import '../../domain/entities/more_info_details.dart';
import '../../domain/entities/my_profile_photo.dart';
import '../../domain/entities/privacy_settings.dart';
import '../../domain/entities/public_profile_preview.dart';
import '../../domain/entities/verification_info.dart';
import '../../domain/mapping/resolve_verification_status.dart';
import '../account_relation_probe.dart';
import '../blocked_profiles_rpc.dart';
import 'profile_account_remote_datasource.dart';

class SupabaseProfileAccountDataSource
    implements ProfileAccountRemoteDataSource {
  SupabaseProfileAccountDataSource(this._client);

  static const _photosBucket = 'avatars';
  // Bucket dédié et privé - jamais 'avatars' (public), le selfie n'est
  // jamais destiné à être vu par d'autres membres.
  static const _selfiesBucket = 'verification-selfies';
  static const _faithRequired = ['church_denomination', 'why_marriage'];
  static const _faithOptional = [
    'spiritual_engagement',
    'ministry',
    'ministry_description',
    'years_converted',
    'conversion_years',
    'faith_years',
    'years_in_christ',
    'favorite_verse',
    'bible_verse',
    'preferred_verse',
    'verse',
    'testimony',
    'faith_testimony',
    'god_work',
    'what_god_doing',
    'god_in_my_life',
    'baptized',
    'is_baptized',
  ];
  static const _moreOptional = [
    'qualities',
    'personal_qualities',
    'hobbies',
    'passions',
    'leisure',
    'values',
    'core_values',
    'family_vision',
    'family_vision_text',
    'children_wanted',
    'desired_children',
    'marriage_horizon',
    'marriage_timeline',
    'likes',
    'dislikes',
  ];
  static const _privacyCandidates = [
    ('show_online_status', 'Statut en ligne', false),
    ('online_status_visible', 'Statut en ligne', false),
    ('read_receipts', 'Accusés de lecture', false),
    ('send_read_receipts', 'Accusés de lecture', false),
    ('hide_read_receipts', 'Masquer les accusés de lecture', false),
    ('is_invisible', 'Profil invisible', false),
    ('hide_profile', 'Profil invisible', false),
    ('profile_invisible', 'Profil invisible', false),
    ('notify_messages', 'Notifications messages', false),
    ('notify_profile', 'Notifications profil', false),
    ('notify_posts', 'Notifications publications', false),
  ];
  static const _publicOptional = [
    'city',
    'country',
    'profession',
    'bio',
    'photo_verification_status',
    'first_name',
    'last_name',
    'birth_date',
    'gender',
    'height_cm',
    'height',
    'size_cm',
    'marital_status',
    'church_denomination',
    'spiritual_engagement',
    'why_marriage',
    'favorite_verse',
    'bible_verse',
    'preferred_verse',
    'verse',
    'testimony',
    'faith_testimony',
    'values',
    'core_values',
    'hobbies',
    'passions',
    'leisure',
    'qualities',
    'personal_qualities',
  ];

  final SupabaseClient _client;
  final Set<String> _knownColumns = {};
  final Map<String, (String, String)> _relationPairs = {};

  @override
  Future<FaithDetails> fetchFaith() {
    return _guard(() async {
      final row = await _selectProfile(_faithRequired, _faithOptional);
      final json = Json(row);
      return FaithDetails(
        denomination: json.string('church_denomination'),
        whyMarriage: json.string('why_marriage'),
        spiritualEngagement: json.string('spiritual_engagement'),
        ministry: _firstString(json, const [
          'ministry',
          'ministry_description',
        ]),
        yearsConverted: _firstString(json, const [
          'years_converted',
          'conversion_years',
          'faith_years',
          'years_in_christ',
        ]),
        verse: _firstString(json, const [
          'favorite_verse',
          'bible_verse',
          'preferred_verse',
          'verse',
        ]),
        testimony: _firstString(json, const ['testimony', 'faith_testimony']),
        godWork: _firstString(json, const [
          'god_work',
          'what_god_doing',
          'god_in_my_life',
        ]),
        baptized: json.boolValue('baptized') || json.boolValue('is_baptized'),
        denominationAvailable: row.containsKey('church_denomination'),
        whyMarriageAvailable: row.containsKey('why_marriage'),
        spiritualEngagementAvailable: row.containsKey('spiritual_engagement'),
        ministryAvailable:
            row.containsKey('ministry') ||
            row.containsKey('ministry_description'),
        yearsConvertedAvailable: [
          'years_converted',
          'conversion_years',
          'faith_years',
          'years_in_christ',
        ].any(row.containsKey),
        verseAvailable: [
          'favorite_verse',
          'bible_verse',
          'preferred_verse',
          'verse',
        ].any(row.containsKey),
        testimonyAvailable:
            row.containsKey('testimony') || row.containsKey('faith_testimony'),
        godWorkAvailable: [
          'god_work',
          'what_god_doing',
          'god_in_my_life',
        ].any(row.containsKey),
        baptizedAvailable:
            row.containsKey('baptized') || row.containsKey('is_baptized'),
      );
    });
  }

  @override
  Future<void> saveFaith(FaithDetails details) {
    return _guard(() async {
      final patch = <String, Object?>{};
      if (details.denominationAvailable) {
        patch['church_denomination'] = details.denomination.trim();
      }
      if (details.whyMarriageAvailable) {
        patch['why_marriage'] = details.whyMarriage.trim();
      }
      _putIfKnown(patch, 'spiritual_engagement', details.spiritualEngagement);
      _putIfKnown(patch, 'ministry', details.ministry);
      _putIfKnown(patch, 'ministry_description', details.ministry);
      _putIfKnown(patch, 'years_converted', details.yearsConverted);
      _putIfKnown(patch, 'conversion_years', details.yearsConverted);
      _putIfKnown(patch, 'faith_years', details.yearsConverted);
      _putIfKnown(patch, 'years_in_christ', details.yearsConverted);
      _putIfKnown(patch, 'favorite_verse', details.verse);
      _putIfKnown(patch, 'bible_verse', details.verse);
      _putIfKnown(patch, 'preferred_verse', details.verse);
      _putIfKnown(patch, 'verse', details.verse);
      _putIfKnown(patch, 'testimony', details.testimony);
      _putIfKnown(patch, 'faith_testimony', details.testimony);
      _putIfKnown(patch, 'god_work', details.godWork);
      _putIfKnown(patch, 'what_god_doing', details.godWork);
      _putIfKnown(patch, 'god_in_my_life', details.godWork);
      if (_knownColumns.contains('baptized')) {
        patch['baptized'] = details.baptized;
      }
      if (_knownColumns.contains('is_baptized')) {
        patch['is_baptized'] = details.baptized;
      }
      if (patch.isEmpty) return;
      await _client.from('profiles').update(patch).eq('id', _requireUserId());
    });
  }

  @override
  Future<MoreInfoDetails> fetchMoreInfo() {
    return _guard(() async {
      final row = await _selectProfile(const [], _moreOptional);
      final json = Json(row);
      return MoreInfoDetails(
        qualities: _stringList(json, const ['qualities', 'personal_qualities']),
        passions: _stringList(json, const ['hobbies', 'passions', 'leisure']),
        values: _stringList(json, const ['values', 'core_values']),
        familyVision: _firstString(json, const [
          'family_vision',
          'family_vision_text',
        ]),
        childrenWanted: _firstString(json, const [
          'children_wanted',
          'desired_children',
        ]),
        marriageHorizon: _firstString(json, const [
          'marriage_horizon',
          'marriage_timeline',
        ]),
        // `likes`/`dislikes` sont des colonnes tableau (`text[]`, confirmé
        // via information_schema 2026-09-22) alors que le champ est du
        // texte libre côté UI : on aplatit en une seule chaîne à l'affichage.
        likes: json.stringList('likes').join(', '),
        dislikes: json.stringList('dislikes').join(', '),
        qualitiesAvailable: [
          'qualities',
          'personal_qualities',
        ].any(row.containsKey),
        passionsAvailable: [
          'hobbies',
          'passions',
          'leisure',
        ].any(row.containsKey),
        valuesAvailable: ['values', 'core_values'].any(row.containsKey),
        familyVisionAvailable: [
          'family_vision',
          'family_vision_text',
        ].any(row.containsKey),
        childrenWantedAvailable: [
          'children_wanted',
          'desired_children',
        ].any(row.containsKey),
        marriageHorizonAvailable: [
          'marriage_horizon',
          'marriage_timeline',
        ].any(row.containsKey),
        likesAvailable: row.containsKey('likes'),
        dislikesAvailable: row.containsKey('dislikes'),
      );
    });
  }

  @override
  Future<void> saveMoreInfo(MoreInfoDetails details) {
    return _guard(() async {
      final patch = <String, Object?>{};
      _putList(patch, const [
        'qualities',
        'personal_qualities',
      ], details.qualities);
      _putList(patch, const [
        'hobbies',
        'passions',
        'leisure',
      ], details.passions);
      _putList(patch, const ['values', 'core_values'], details.values);
      _putIfKnown(patch, 'family_vision', details.familyVision);
      _putIfKnown(patch, 'family_vision_text', details.familyVision);
      _putIfKnown(patch, 'children_wanted', details.childrenWanted);
      _putIfKnown(patch, 'desired_children', details.childrenWanted);
      _putIfKnown(patch, 'marriage_horizon', details.marriageHorizon);
      _putIfKnown(patch, 'marriage_timeline', details.marriageHorizon);
      // Colonnes tableau (`text[]`) : on renvoie le texte libre comme un
      // seul élément (ou tableau vide), pas une string brute — sinon
      // Postgres rejette avec "malformed array literal".
      _putList(
        patch,
        const ['likes'],
        details.likes.trim().isEmpty ? const [] : [details.likes.trim()],
      );
      _putList(
        patch,
        const ['dislikes'],
        details.dislikes.trim().isEmpty ? const [] : [details.dislikes.trim()],
      );
      if (patch.isEmpty) return;
      await _client.from('profiles').update(patch).eq('id', _requireUserId());
    });
  }

  @override
  Future<PrivacySettings> fetchPrivacy() {
    return _guard(() async {
      final cols = _privacyCandidates.map((e) => e.$1).toList();
      final row = await _selectProfile(const [], cols);
      final json = Json(row);
      final switches = <PrivacySwitch>[];
      final seenLabels = <String>{};
      for (final candidate in _privacyCandidates) {
        if (!row.containsKey(candidate.$1)) continue;
        if (!seenLabels.add(candidate.$2)) continue;
        switches.add(
          PrivacySwitch(
            id: candidate.$1,
            label: candidate.$2,
            value: json.boolValue(candidate.$1),
          ),
        );
      }
      return PrivacySettings(switches: switches);
    });
  }

  @override
  Future<void> savePrivacy(PrivacySettings settings) {
    return _guard(() async {
      final patch = <String, Object?>{
        for (final item in settings.switches)
          if (_knownColumns.contains(item.id)) item.id: item.value,
      };
      if (patch.isEmpty) return;
      await _client.from('profiles').update(patch).eq('id', _requireUserId());
    });
  }

  @override
  Future<List<AccountPerson>> fetchFavorites() {
    return _guard(() async {
      final userId = _requireUserId();
      final ids = await _idColumn(
        table: 'favorites',
        pairs: AccountRelationPairs.favorites,
        ownerId: userId,
      );
      return _peopleByIds(ids, reveal: true);
    });
  }

  @override
  Future<void> removeFavorite(String profileId) {
    return _guard(() async {
      final userId = _requireUserId();
      await _deletePair(
        table: 'favorites',
        pairs: AccountRelationPairs.favorites,
        ownerId: userId,
        targetId: profileId,
      );
    });
  }

  @override
  Future<InterestedPeople> fetchInterested() {
    return _guard(() async {
      final userId = _requireUserId();
      final ids = await _idColumn(
        table: 'profile_likes',
        pairs: AccountRelationPairs.likesReceived,
        ownerId: userId,
      );
      final reveal = await _revealIdentities(userId);
      final people = await _peopleByIds(ids, reveal: reveal);
      return InterestedPeople(
        count: ids.length,
        revealIdentities: reveal,
        people: people,
      );
    });
  }

  @override
  Future<List<AccountPerson>> fetchBlocked() {
    return _guard(() async {
      final viaRpc = await _fetchBlockedViaRpc();
      if (viaRpc != null) return viaRpc;

      final userId = _requireUserId();
      final ids = await _idColumn(
        table: 'blocks',
        pairs: AccountRelationPairs.blocks,
        ownerId: userId,
      );
      // Après un blocage, la RLS masque souvent le profil cible : on garde
      // quand même une ligne par id pour permettre le déblocage (PRD §10).
      final hydrated = await _peopleByIds(ids, reveal: true);
      return mergeBlockedPeople(ids: ids, hydrated: hydrated);
    });
  }

  /// PRD §21 : `get_my_blocked_profiles` est le chemin prévu (bypass RLS).
  Future<List<AccountPerson>?> _fetchBlockedViaRpc() async {
    try {
      final raw = await _client.rpc('get_my_blocked_profiles');
      return parseBlockedProfilesRpc(raw);
    } on PostgrestException catch (e) {
      if (_looksLikeMissingRpc(e)) return null;
      rethrow;
    }
  }

  @override
  Future<void> unblock(String profileId) {
    return _guard(() async {
      final userId = _requireUserId();
      await _deletePair(
        table: 'blocks',
        pairs: AccountRelationPairs.blocks,
        ownerId: userId,
        targetId: profileId,
      );
    });
  }

  @override
  Future<VerificationInfo> fetchVerification() {
    return _guard(() async {
      final userId = _requireUserId();
      final profile = await _client
          .from('profiles')
          .select(
            'photo_verification_status, gender, birth_date, country, '
            'church_denomination, why_marriage, marital_status, hobbies',
          )
          .eq('id', userId)
          .maybeSingle();
      final json = Json(profile ?? const <String, dynamic>{});
      final photos = await _client
          .from('profile_photos')
          .select('id')
          .eq('profile_id', userId);
      final hasPhoto = photos.isNotEmpty;
      final complete =
          json.stringOrNull('gender') != null &&
          json.stringOrNull('birth_date') != null &&
          json.stringOrNull('country') != null &&
          json.stringOrNull('church_denomination') != null &&
          json.stringOrNull('why_marriage') != null &&
          json.stringOrNull('marital_status') != null &&
          json.stringList('hobbies').isNotEmpty &&
          hasPhoto;
      // `profiles.photo_verification_status` n'est pas synchronisé au rejet
      // (reste bloqué à UNVERIFIED, confirmé par SQL direct) - la dernière
      // ligne de `verification_requests` fait foi tant qu'elle existe.
      String? rejection;
      String? requestStatus;
      try {
        final request = await _client
            .from('verification_requests')
            .select('status, rejection_reason')
            .eq('user_id', userId)
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();
        final requestJson = Json(request ?? const {});
        rejection = requestJson.stringOrNull('rejection_reason');
        requestStatus = requestJson.stringOrNull('status');
      } on PostgrestException {
        rejection = null;
        requestStatus = null;
      }
      return VerificationInfo(
        status:
            resolveVerificationStatus(
              requestStatus: requestStatus,
              profileStatus: json.string(
                'photo_verification_status',
                fallback: 'UNVERIFIED',
              ),
            ) ??
            'UNVERIFIED',
        isComplete: complete,
        rejectionReason: rejection,
        email: _client.auth.currentUser?.email ?? '',
      );
    });
  }

  @override
  Future<void> submitVerification({
    required String selfiePath,
    bool forceNew = false,
  }) {
    return _guard(() async {
      final info = await fetchVerification();
      if (!forceNew && !info.isComplete) {
        throw const ValidationException(
          'Complète ton profil (photo, confession, pourquoi le mariage) avant de soumettre.',
        );
      }
      if (!forceNew && (info.isPending || info.isVerified)) return;
      if (forceNew && !info.isComplete) {
        throw const ValidationException(
          'Complète ton profil avant d\'ajouter une photo.',
        );
      }
      final userId = _requireUserId();
      // Chemin unique par soumission - pas de policy storage UPDATE sur
      // verification-selfies (uniquement SELECT/INSERT, confirmé par SQL),
      // réutiliser toujours le même chemin ferait échouer l'upsert d'une
      // resoumission avec "new row violates row-level security policy".
      final objectPath =
          '$userId/selfie_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await _uploadJpeg(objectPath, selfiePath, bucket: _selfiesBucket);
      // protect_photo_moderation_status() autorise désormais explicitement
      // cette transition précise (DRAFT -> PENDING, par le propriétaire de
      // la photo) - toute autre modification de moderation_status reste
      // réservée aux admins/modérateurs (Q6, docs/decisions.md). En
      // try/catch : si jamais bloqué (photo pas en DRAFT, trigger pas
      // encore déployé, etc.), la soumission continue quand même -
      // verification_requests ci-dessous reste la source de vérité lue par
      // l'app pour afficher le statut.
      try {
        await _client
            .from('profile_photos')
            .update({'moderation_status': 'PENDING'})
            .eq('profile_id', userId)
            .eq('moderation_status', 'DRAFT');
      } on PostgrestException {
        // le dashboard admin ne verra pas cette photo tant que le backend
        // n'a pas confirmé le déploiement du trigger mis à jour.
      }
      try {
        await _client.from('verification_requests').insert({
          'user_id': userId,
          'status': 'PENDING',
          'selfie_storage_path': objectPath,
        });
      } on PostgrestException catch (e) {
        if (!_looksLikeMissingColumn(e)) rethrow;
        await _client.from('verification_requests').insert({
          'user_id': userId,
          'status': 'PENDING',
        });
      }
      try {
        await _client
            .from('profiles')
            .update({'photo_verification_status': 'PENDING'})
            .eq('id', userId);
      } on PostgrestException {
        // derived from verification_requests
      }
    });
  }

  @override
  Future<void> changeEmail(String email) {
    return _guard(() async {
      final res = await _client.auth.updateUser(UserAttributes(email: email));
      if (res.user == null) {
        throw const ValidationException('Impossible de changer l\'email.');
      }
    });
  }

  @override
  Future<String> exportJson() {
    return _guard(() async {
      final userId = _requireUserId();
      final profile = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      final photos = await _client
          .from('profile_photos')
          .select('id, storage_path, is_primary, moderation_status')
          .eq('profile_id', userId);
      return const JsonEncoder.withIndent('  ').convert({
        'exported_at': DateTime.now().toUtc().toIso8601String(),
        'email': _client.auth.currentUser?.email,
        'profile': profile,
        'photos': photos,
      });
    });
  }

  @override
  Future<void> deleteAccount() {
    return _guard(() async {
      final userId = _requireUserId();
      for (final fn in const [
        'delete_own_account',
        'delete_my_account',
        'delete_account',
      ]) {
        try {
          await _client.rpc(fn);
          return;
        } on PostgrestException catch (e) {
          if (!_looksLikeMissingRpc(e)) rethrow;
        }
      }
      await _client.from('profiles').delete().eq('id', userId);
      await _client.auth.signOut();
    });
  }

  @override
  Future<PublicProfilePreview> fetchPublicPreview() {
    return _guard(() async {
      final userId = _requireUserId();
      final row = await _selectProfile(const [
        'id',
        'first_name',
        'last_name',
      ], _publicOptional);
      final json = Json(row);
      final first = json.stringOrNull('first_name');
      final last = json.stringOrNull('last_name');
      final name = [
        if (first != null) first,
        if (last != null) last,
      ].join(' ').trim();
      final photos = await _fetchPhotos(userId);
      final birth =
          json.dateTime('birth_date') ??
          DateTime.tryParse(json.stringOrNull('birth_date') ?? '');
      return PublicProfilePreview(
        id: userId,
        displayName: name.isEmpty
            ? (_client.auth.currentUser?.email ?? 'Moi')
            : name,
        age: _ageFromBirth(birth),
        city: json.stringOrNull('city'),
        country: json.stringOrNull('country'),
        gender: json.stringOrNull('gender'),
        profession: json.stringOrNull('profession'),
        bio: json.stringOrNull('bio'),
        heightCm:
            json.intOrNull('height_cm') ??
            json.intOrNull('height') ??
            json.intOrNull('size_cm'),
        maritalStatus: json.stringOrNull('marital_status'),
        isVerified:
            json.string('photo_verification_status').toUpperCase() ==
            'VERIFIED',
        photos: photos,
        denomination: json.stringOrNull('church_denomination'),
        spiritualEngagement: json.stringOrNull('spiritual_engagement'),
        whyMarriage: json.stringOrNull('why_marriage'),
        verse: _firstString(json, const [
          'favorite_verse',
          'bible_verse',
          'preferred_verse',
          'verse',
        ]),
        testimony: _firstString(json, const ['testimony', 'faith_testimony']),
        values: _stringList(json, const ['values', 'core_values']),
        passions: _stringList(json, const ['hobbies', 'passions', 'leisure']),
        qualities: _stringList(json, const ['qualities', 'personal_qualities']),
      );
    });
  }

  @override
  Future<void> addVerifiedPhoto({
    required String photoPath,
    required String selfiePath,
  }) {
    return _guard(() async {
      final userId = _requireUserId();
      final existing = await _client
          .from('profile_photos')
          .select('id, moderation_status')
          .eq('profile_id', userId);
      // Un seul lot à la fois dans la file de revue (PRD interne §6) -
      // l'ajout est bloqué tant qu'une photo précédente n'est pas traitée.
      final hasPending = existing.any(
        (row) => row['moderation_status'] == 'PENDING',
      );
      if (hasPending) {
        throw const ValidationException(
          'Une photo est déjà en cours d\'examen - attends la décision de '
          'notre équipe avant d\'en ajouter une nouvelle.',
        );
      }
      final premium = await _isPremium(userId);
      final max = premium ? 10 : 2;
      if (existing.length >= max) {
        throw ValidationException(
          premium
              ? 'Limite de photos atteinte.'
              : 'Passe Premium pour ajouter plus de photos.',
        );
      }
      final slot = existing.length;
      final objectPath = '$userId/slot_$slot.jpg';
      await _uploadJpeg(objectPath, photoPath);
      final url = _client.storage.from(_photosBucket).getPublicUrl(objectPath);
      // Selfie propre à cette photo (profile_photos.selfie_storage_path) -
      // jamais réutilisé, jamais modifiable après coup (un trigger bloque
      // toute UPDATE de cette colonne) : il doit être écrit dans le même
      // INSERT que la photo, pas via un appel séparé à
      // verification_requests (PRD interne §6/§7 - cet ajout est examiné
      // individuellement sur /admin/photos, indépendamment de toute
      // demande de vérification de profil).
      final selfieObjectPath =
          '$userId/${DateTime.now().millisecondsSinceEpoch}-selfie.jpg';
      await _uploadJpeg(
        selfieObjectPath,
        selfiePath,
        bucket: _selfiesBucket,
      );
      await _client.from('profile_photos').insert({
        'profile_id': userId,
        'storage_path': objectPath,
        'url': url,
        'is_primary': existing.isEmpty,
        'moderation_status': 'PENDING',
        'selfie_storage_path': selfieObjectPath,
      });
    });
  }

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on AuthException catch (e) {
      throw mapSupabaseAuthException(e);
    } on PostgrestException catch (e) {
      throw mapPostgrestException(e);
    } on StorageException catch (e) {
      throw ServerException(
        e.message.trim().isEmpty
            ? 'Impossible d\'envoyer le fichier.'
            : e.message,
      );
    } on SocketException catch (e) {
      throw NetworkException(e.message);
    } on ValidationException {
      rethrow;
    } on UnauthorizedException {
      rethrow;
    } on ServerException {
      // Déjà mappé par un _guard() imbriqué (ex. addVerifiedPhoto ->
      // submitVerification, qui a son propre _guard()) - relancer tel
      // quel, sinon mapUnknownSupabase() fait e.toString() sur l'objet
      // et affiche "Instance of 'ServerException'" au lieu du vrai message.
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw mapUnknownSupabase(e);
    }
  }

  Future<Map<String, dynamic>> _selectProfile(
    List<String> requiredCols,
    List<String> optionalCols,
  ) async {
    final userId = _requireUserId();
    var optional = [...optionalCols];
    while (true) {
      final select = [...requiredCols, ...optional].join(', ');
      try {
        final row = await _client
            .from('profiles')
            .select(select.isEmpty ? '*' : select)
            .eq('id', userId)
            .maybeSingle();
        final map = Map<String, dynamic>.from(row ?? const <String, dynamic>{});
        _knownColumns.addAll(map.keys);
        return map;
      } on PostgrestException catch (e) {
        if (!_looksLikeMissingColumn(e)) rethrow;
        final name = _columnNameFromError(e);
        if (name != null && optional.contains(name)) {
          optional.remove(name);
          continue;
        }
        if (optional.isNotEmpty) {
          optional.removeLast();
          continue;
        }
        rethrow;
      }
    }
  }

  Future<List<String>> _idColumn({
    required String table,
    required List<(String, String)> pairs,
    required String ownerId,
  }) async {
    final cached = _relationPairs[table];
    final ordered = [
      if (cached != null) cached,
      ...pairs.where((pair) => pair != cached),
    ];
    for (final pair in ordered) {
      final owner = pair.$1;
      final target = pair.$2;
      try {
        final rows = await _client
            .from(table)
            .select(target)
            .eq(owner, ownerId);
        _relationPairs[table] = pair;
        return [
          for (final row in rows)
            if (row[target] != null) row[target].toString(),
        ];
      } on PostgrestException catch (e) {
        if (!_looksLikeMissingColumn(e)) rethrow;
      }
    }

    final owners = {for (final pair in pairs) pair.$1};
    for (final owner in owners) {
      try {
        final rows = await _client.from(table).select().eq(owner, ownerId);
        if (rows.isEmpty) return const [];
        final first = Map<String, dynamic>.from(rows.first as Map);
        final target = inferRelationTargetColumn(first, ownerCol: owner);
        if (target == null) return const [];
        _relationPairs[table] = (owner, target);
        return [
          for (final row in rows)
            if (row[target] != null) row[target].toString(),
        ];
      } on PostgrestException catch (e) {
        if (!_looksLikeMissingColumn(e)) rethrow;
      }
    }
    return const [];
  }

  Future<void> _deletePair({
    required String table,
    required List<(String, String)> pairs,
    required String ownerId,
    required String targetId,
  }) async {
    final cached = _relationPairs[table];
    final ordered = [
      if (cached != null) cached,
      ...pairs.where((pair) => pair != cached),
    ];
    for (final pair in ordered) {
      try {
        await _client
            .from(table)
            .delete()
            .eq(pair.$1, ownerId)
            .eq(pair.$2, targetId);
        _relationPairs[table] = pair;
        return;
      } on PostgrestException catch (e) {
        if (!_looksLikeMissingColumn(e)) rethrow;
      }
    }
  }

  Future<List<AccountPerson>> _peopleByIds(
    List<String> ids, {
    required bool reveal,
  }) async {
    if (ids.isEmpty) return const [];
    List<dynamic> rows;
    try {
      rows = await _client
          .from('profiles')
          .select(
            'id, first_name, last_name, city, profile_photos(storage_path, url, is_primary)',
          )
          .inFilter('id', ids);
    } on PostgrestException {
      rows = await _client
          .from('profiles')
          .select('id, first_name, last_name, city')
          .inFilter('id', ids);
    }

    // L'embed imbriqué profiles→profile_photos ne remonte pas toujours de
    // résultat (même constat que Découvrir, cf. SupabaseDiscoverDataSource
    //._hydratePhotos) : on complète par une requête directe pour les
    // profils sans photo dans l'embed.
    final missingIds = [
      for (final row in rows)
        if (!_hasEmbeddedPhoto(Map<String, dynamic>.from(row)))
          Json(Map<String, dynamic>.from(row)).string('id'),
    ];
    final fallbackPhotos = missingIds.isEmpty
        ? const <String, Map<String, dynamic>>{}
        : await _fetchPrimaryPhotosByProfileId(missingIds);

    return [
      for (final row in rows)
        _personFrom(
          Map<String, dynamic>.from(row),
          reveal: reveal,
          fallbackPhoto: fallbackPhotos[Json(Map<String, dynamic>.from(row)).string('id')],
        ),
    ];
  }

  bool _hasEmbeddedPhoto(Map<String, dynamic> row) {
    final photos = row['profile_photos'];
    return photos is List && photos.isNotEmpty;
  }

  Future<Map<String, Map<String, dynamic>>> _fetchPrimaryPhotosByProfileId(
    List<String> profileIds,
  ) async {
    try {
      final rows = await _client
          .from('profile_photos')
          .select('profile_id, storage_path, url, is_primary')
          .inFilter('profile_id', profileIds);
      final byProfile = <String, Map<String, dynamic>>{};
      for (final row in rows) {
        final map = Map<String, dynamic>.from(row);
        final profileId = Json(map).stringOrNull('profile_id');
        if (profileId == null) continue;
        final isPrimary = Json(map).boolValue('is_primary');
        if (isPrimary || !byProfile.containsKey(profileId)) {
          byProfile[profileId] = map;
        }
      }
      return byProfile;
    } on PostgrestException {
      return const {};
    }
  }

  AccountPerson _personFrom(
    Map<String, dynamic> map, {
    required bool reveal,
    Map<String, dynamic>? fallbackPhoto,
  }) {
    final json = Json(map);
    final first = json.stringOrNull('first_name') ?? '';
    final last = json.stringOrNull('last_name') ?? '';
    final raw = '$first $last'.trim();
    final name = raw.isEmpty ? 'Membre' : raw;
    final masked = name.length <= 2 ? '$name***' : '${name.substring(0, 2)}***';
    String? photo;
    final photos = map['profile_photos'];
    if (photos is List && photos.isNotEmpty) {
      Map<String, dynamic>? primary;
      for (final item in photos) {
        if (item is! Map) continue;
        final p = Map<String, dynamic>.from(item);
        primary ??= p;
        if (p['is_primary'] == true) primary = p;
      }
      if (primary != null) photo = _photoUrl(primary);
    } else if (fallbackPhoto != null) {
      photo = _photoUrl(fallbackPhoto);
    }
    return AccountPerson(
      id: json.string('id'),
      displayName: reveal ? name : masked,
      photoUrl: reveal ? photo : null,
      city: reveal ? json.stringOrNull('city') : null,
      identityRevealed: reveal,
    );
  }

  Future<bool> _revealIdentities(String userId) async {
    try {
      final restricted = await _client
          .from('profile_restricted')
          .select('subscription_status')
          .eq('id', userId)
          .maybeSingle();
      final status = Json(
        restricted ?? const {},
      ).string('subscription_status').toUpperCase();
      if (status == 'ACTIVE') return true;
    } on PostgrestException {
      // fall through
    }
    try {
      final profile = await _client
          .from('profiles')
          .select('is_staff')
          .eq('id', userId)
          .maybeSingle();
      return Json(profile ?? const {}).boolValue('is_staff');
    } on PostgrestException {
      return false;
    }
  }

  Future<bool> _isPremium(String userId) async {
    try {
      final restricted = await _client
          .from('profile_restricted')
          .select('subscription_status')
          .eq('id', userId)
          .maybeSingle();
      return Json(
            restricted ?? const {},
          ).string('subscription_status').toUpperCase() ==
          'ACTIVE';
    } on PostgrestException {
      return false;
    }
  }

  Future<List<MyProfilePhoto>> _fetchPhotos(String userId) async {
    final rows = await _client
        .from('profile_photos')
        .select('id, storage_path, url, is_primary, moderation_status')
        .eq('profile_id', userId);
    final photos = <MyProfilePhoto>[];
    final rest = <MyProfilePhoto>[];
    for (final row in rows) {
      final map = Map<String, dynamic>.from(row);
      final json = Json(map);
      final photo = MyProfilePhoto(
        id: json.stringOrNull('id') ?? map['id']?.toString(),
        publicUrl: _photoUrl(map),
        moderationStatus: json.stringOrNull('moderation_status'),
      );
      if (json.boolValue('is_primary')) {
        photos.add(photo);
      } else {
        rest.add(photo);
      }
    }
    return [...photos, ...rest];
  }

  Future<void> _uploadJpeg(
    String objectPath,
    String localPath, {
    String bucket = _photosBucket,
  }) async {
    final file = File(localPath);
    if (!file.existsSync()) {
      throw const ValidationException('Fichier photo introuvable.');
    }
    await _client.storage
        .from(bucket)
        .upload(
          objectPath,
          file,
          fileOptions: const FileOptions(
            upsert: true,
            contentType: 'image/jpeg',
          ),
        );
  }

  String? _photoUrl(Map<String, dynamic> photo) {
    for (final key in ['url', 'public_url', 'storage_path', 'path']) {
      final value = photo[key];
      if (value is String && value.isNotEmpty) {
        if (value.startsWith('http://') || value.startsWith('https://')) {
          return value;
        }
        return _client.storage.from(_photosBucket).getPublicUrl(value);
      }
    }
    return null;
  }

  void _putIfKnown(Map<String, Object?> patch, String key, String value) {
    if (_knownColumns.contains(key)) patch[key] = value.trim();
  }

  void _putList(
    Map<String, Object?> patch,
    List<String> keys,
    List<String> values,
  ) {
    for (final key in keys) {
      if (_knownColumns.contains(key)) patch[key] = values;
    }
  }

  int? _ageFromBirth(DateTime? birth) {
    if (birth == null) return null;
    final today = DateTime.now().toUtc();
    var age = today.year - birth.year;
    final hadBirthday =
        today.month > birth.month ||
        (today.month == birth.month && today.day >= birth.day);
    if (!hadBirthday) age -= 1;
    return age < 0 ? 0 : age;
  }

  String _firstString(Json json, List<String> keys) {
    for (final key in keys) {
      final value = json.stringOrNull(key);
      if (value != null) return value;
    }
    return '';
  }

  List<String> _stringList(Json json, List<String> keys) {
    for (final key in keys) {
      final fromList = json.stringList(key);
      if (fromList.isNotEmpty) return fromList;
      final raw = json.stringOrNull(key);
      if (raw != null && raw.contains(',')) {
        return [
          for (final part in raw.split(','))
            if (part.trim().isNotEmpty) part.trim(),
        ];
      }
    }
    return const [];
  }

  bool _looksLikeMissingColumn(PostgrestException e) {
    final all = '${e.message} ${e.details} ${e.hint}'.toLowerCase();
    return (all.contains('column') && all.contains('does not exist')) ||
        all.contains('could not find') ||
        all.contains('relationship') ||
        all.contains('embedding');
  }

  bool _looksLikeMissingRpc(PostgrestException e) {
    final all = '${e.message} ${e.details} ${e.hint}'.toLowerCase();
    return all.contains('could not find') ||
        all.contains('does not exist') ||
        all.contains('function');
  }

  String? _columnNameFromError(PostgrestException e) {
    final all = '${e.message} ${e.details} ${e.hint}';
    final postgres = RegExp(
      r'column (?:[\w.]+\.)?(\w+) does not exist',
      caseSensitive: false,
    ).firstMatch(all);
    if (postgres != null) return postgres.group(1);
    final postgrest = RegExp(
      r"find the '(\w+)' column",
      caseSensitive: false,
    ).firstMatch(all);
    return postgrest?.group(1);
  }

  String _requireUserId() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const UnauthorizedException('Session expirée.');
    }
    return userId;
  }
}
