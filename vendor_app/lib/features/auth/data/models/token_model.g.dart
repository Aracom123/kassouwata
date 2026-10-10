// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'token_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TokenModel _$TokenModelFromJson(Map<String, dynamic> json) => TokenModel(
      token: json['token'] as String,
      expiresIn: _toNullableString(json['expiresIn']),
      isExpired: json['isExpired'] as bool?,
      idUser: _toNullableString(json['idUser']),
      status: json['status'] as String?,
      login: json['login'] as String?,
      profile: json['profile'] as String?,
      email: json['email'] as String?,
      nom: json['nom'] as String?,
      prenom: json['prenom'] as String?,
      boutique: json['boutique'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$TokenModelToJson(TokenModel instance) =>
    <String, dynamic>{
      'token': instance.token,
      'expiresIn': instance.expiresIn,
      'isExpired': instance.isExpired,
      'idUser': instance.idUser,
      'status': instance.status,
      'login': instance.login,
      'profile': instance.profile,
      'email': instance.email,
      'nom': instance.nom,
      'prenom': instance.prenom,
    };
