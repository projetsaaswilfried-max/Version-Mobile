import 'package:equatable/equatable.dart';

class MyProfilePhoto extends Equatable {
  const MyProfilePhoto({
    this.id,
    this.publicUrl,
    this.localPath,
    this.moderationStatus,
  });

  final String? id;
  final String? publicUrl;
  final String? localPath;

  /// DRAFT / PENDING / APPROVED / REJECTED - `null` pour une photo pas
  /// encore enregistrée côté serveur (choisie localement).
  final String? moderationStatus;

  @override
  List<Object?> get props => [id, publicUrl, localPath, moderationStatus];
}
