import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/result.dart';
import '../../../discover/domain/entities/discover_profile_detail.dart';
import '../../../discover/presentation/widgets/discover_profile_content.dart';
import '../../di/profile_providers.dart';
import '../../domain/entities/my_profile_photo.dart';
import '../../domain/entities/public_profile_preview.dart';
import '../account/widgets/account_editor_scaffold.dart';

class PublicProfilePage extends ConsumerStatefulWidget {
  const PublicProfilePage({super.key});

  @override
  ConsumerState<PublicProfilePage> createState() => _PublicProfilePageState();
}

class _PublicProfilePageState extends ConsumerState<PublicProfilePage> {
  PublicProfilePreview? _preview;
  var _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await ref
        .read(profileAccountRepositoryProvider)
        .fetchPublicPreview();
    if (!mounted) return;
    switch (result) {
      case Ok<PublicProfilePreview>(:final value):
        setState(() {
          _preview = value;
          _loading = false;
        });
      case Err<PublicProfilePreview>(:final failure):
        setState(() {
          _error = failure.message;
          _loading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final preview = _preview;
    return AccountEditorScaffold(
      title: 'Mon profil public',
      isLoading: _loading,
      errorMessage: _error,
      onRetry: _load,
      isSaving: false,
      showSave: false,
      onSave: null,
      child: preview == null
          ? const SizedBox.shrink()
          : DiscoverProfileContent(detail: _toDetail(preview)),
    );
  }

  static DiscoverProfileDetail _toDetail(PublicProfilePreview preview) {
    return DiscoverProfileDetail(
      id: preview.id,
      displayName: preview.displayName,
      age: preview.age,
      city: preview.city,
      country: preview.country,
      gender: preview.gender,
      profession: preview.profession,
      bio: preview.bio,
      heightCm: preview.heightCm,
      maritalStatus: preview.maritalStatus,
      photoUrls: _urls(preview.photos),
      isVerified: preview.isVerified,
      confession: preview.denomination,
      spiritualEngagement: preview.spiritualEngagement,
      whyMarriage: preview.whyMarriage,
      verse: preview.verse,
      testimony: preview.testimony,
      values: preview.values,
      hobbies: preview.passions,
      qualities: preview.qualities,
    );
  }

  static List<String> _urls(List<MyProfilePhoto> photos) {
    return [
      for (final photo in photos)
        if (photo.publicUrl != null && photo.publicUrl!.isNotEmpty)
          photo.publicUrl!,
    ];
  }
}
