import 'package:equatable/equatable.dart';

class MyProfilePhoto extends Equatable {
  const MyProfilePhoto({this.id, this.publicUrl, this.localPath});

  final String? id;
  final String? publicUrl;
  final String? localPath;

  @override
  List<Object?> get props => [id, publicUrl, localPath];
}
