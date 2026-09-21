import 'package:equatable/equatable.dart';

class SupportTicket extends Equatable {
  const SupportTicket({
    required this.id,
    required this.subject,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String subject;
  final String status;
  final DateTime createdAt;

  bool get isOpen => status.toUpperCase() == 'OPEN';

  @override
  List<Object?> get props => [id, subject, status, createdAt];
}

class SupportMessage extends Equatable {
  const SupportMessage({
    required this.id,
    required this.body,
    required this.createdAt,
    required this.isMine,
  });

  final String id;
  final String body;
  final DateTime createdAt;
  final bool isMine;

  @override
  List<Object?> get props => [id, body, createdAt, isMine];
}
