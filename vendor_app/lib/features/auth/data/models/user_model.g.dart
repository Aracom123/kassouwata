// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
      idUser: json['idUser'] as String,
      telephone: json['telephone'] as String,
      status: _userStatusFromJson(json['status']),
      profile: json['profile'] == null
          ? null
          : ProfileModel.fromJson(json['profile'] as Map<String, dynamic>),
      personne: json['personne'] == null
          ? null
          : PersonneModel.fromJson(json['personne'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
      'idUser': instance.idUser,
      'telephone': instance.telephone,
      'status': _userStatusToJson(instance.status),
      'profile': instance.profile,
      'personne': instance.personne,
    };
