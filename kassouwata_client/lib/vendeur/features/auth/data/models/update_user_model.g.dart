// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateUserRequestModel _$UpdateUserRequestModelFromJson(
        Map<String, dynamic> json) =>
    UpdateUserRequestModel(
      status: json['status'] as String,
      profile:
          UpdateProfileModel.fromJson(json['profile'] as Map<String, dynamic>),
      personne: UpdatePersonneModel.fromJson(
          json['personne'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$UpdateUserRequestModelToJson(
        UpdateUserRequestModel instance) =>
    <String, dynamic>{
      'status': instance.status,
      'profile': instance.profile,
      'personne': instance.personne,
    };

UpdateProfileModel _$UpdateProfileModelFromJson(Map<String, dynamic> json) =>
    UpdateProfileModel(
      idProfile: (json['idProfile'] as num).toInt(),
    );

Map<String, dynamic> _$UpdateProfileModelToJson(UpdateProfileModel instance) =>
    <String, dynamic>{
      'idProfile': instance.idProfile,
    };

UpdatePersonneModel _$UpdatePersonneModelFromJson(Map<String, dynamic> json) =>
    UpdatePersonneModel(
      nom: json['nom'] as String?,
      prenom: json['prenom'] as String?,
      genre: json['genre'] as String?,
      adresse: json['adresse'] as String?,
      lieuNaissance: json['lieuNaissance'] as String?,
      email: json['email'] as String?,
      dateNaissance: _dateFromJson(json['dateNaissance'] as String?),
    );

Map<String, dynamic> _$UpdatePersonneModelToJson(
        UpdatePersonneModel instance) =>
    <String, dynamic>{
      'nom': instance.nom,
      'prenom': instance.prenom,
      'genre': instance.genre,
      'adresse': instance.adresse,
      'lieuNaissance': instance.lieuNaissance,
      'email': instance.email,
      'dateNaissance': _dateToJson(instance.dateNaissance),
    };
