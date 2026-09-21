import 'package:equatable/equatable.dart';

import 'profile_fields_snapshot.dart';

class ProfileHub extends Equatable {
  const ProfileHub({
    required this.displayName,
    required this.isVerified,
    this.photoUrl,
  });

  final String displayName;
  final String? photoUrl;
  final bool isVerified;

  factory ProfileHub.fromFields(
    ProfileFieldsSnapshot fields, {
    required String fallbackEmail,
  }) {
    final parts = [fields.firstName, fields.lastName]
        .map((value) => value?.trim() ?? '')
        .where((value) => value.isNotEmpty)
        .toList();
    final name = parts.join(' ');
    final email = fallbackEmail.trim();
    final url = fields.primaryPhotoUrl?.trim();
    return ProfileHub(
      displayName: name.isNotEmpty ? name : email,
      photoUrl: (url == null || url.isEmpty) ? null : url,
      isVerified:
          (fields.photoVerificationStatus ?? '').toUpperCase() == 'VERIFIED',
    );
  }

  @override
  List<Object?> get props => [displayName, photoUrl, isVerified];
}
