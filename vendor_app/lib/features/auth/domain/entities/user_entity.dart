import 'package:equatable/equatable.dart';
import '../../../../shared/enums/user_status.dart';
import 'personne_entity.dart';
import 'profile_entity.dart';

class UserEntity extends Equatable {
  final String idUser;
  final String telephone;
  final UserStatus status;
  final ProfileEntity? profile;
  final PersonneEntity? personne;

  const UserEntity({
    required this.idUser,
    required this.telephone,
    required this.status,
    this.profile,
    this.personne,
  });

  String get displayName => personne?.fullName ?? telephone;

  @override
  List<Object?> get props => [idUser, telephone, status];
}