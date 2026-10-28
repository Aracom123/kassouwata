import 'package:json_annotation/json_annotation.dart';
import '../../../../shared/enums/user_status.dart';
import '../../domain/entities/user_entity.dart';
import 'personne_model.dart';
import 'profile_model.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel {
  final String idUser;
  final String telephone;
  @JsonKey(fromJson: _userStatusFromJson, toJson: _userStatusToJson)
  final UserStatus status;
  final ProfileModel? profile;
  final PersonneModel? personne;

  const UserModel({
    required this.idUser,
    required this.telephone,
    required this.status,
    this.profile,
    this.personne,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  UserEntity toEntity() => UserEntity(
        idUser: idUser,
        telephone: telephone,
        status: status,
        profile: profile,
        personne: personne,
      );
}

UserStatus _userStatusFromJson(dynamic value) =>
    UserStatus.fromJson(value?.toString() ?? 'ACTIVE');
String _userStatusToJson(UserStatus status) => status.toJson();