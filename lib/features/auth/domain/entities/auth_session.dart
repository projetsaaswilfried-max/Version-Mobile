import 'package:equatable/equatable.dart';

class AuthSession extends Equatable {
  const AuthSession({required this.id, required this.email});

  final String id;
  final String email;

  @override
  List<Object?> get props => [id, email];
}
