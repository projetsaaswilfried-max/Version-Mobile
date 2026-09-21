import 'package:equatable/equatable.dart';

class VerificationInfo extends Equatable {
  const VerificationInfo({
    required this.status,
    required this.isComplete,
    this.rejectionReason,
    this.email = '',
  });

  final String status;
  final bool isComplete;
  final String? rejectionReason;
  final String email;

  bool get isVerified => status.toUpperCase() == 'VERIFIED';
  bool get isPending => status.toUpperCase() == 'PENDING';
  bool get isRejected => status.toUpperCase() == 'REJECTED';
  bool get canSubmit => isComplete && !isPending && !isVerified;

  String get statusLabel {
    switch (status.toUpperCase()) {
      case 'VERIFIED':
        return 'Profil vérifié';
      case 'PENDING':
        return 'Vérification en cours';
      case 'REJECTED':
        return 'Vérification refusée';
      default:
        return 'Non vérifié';
    }
  }

  @override
  List<Object?> get props => [status, isComplete, rejectionReason, email];
}
