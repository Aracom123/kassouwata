// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProfileModel _$ProfileModelFromJson(Map<String, dynamic> json) => ProfileModel(
      idProfile: (json['idProfile'] as num).toInt(),
      libelle: json['libelle'] as String,
      description: json['description'] as String?,
    );

Map<String, dynamic> _$ProfileModelToJson(ProfileModel instance) =>
    <String, dynamic>{
      'idProfile': instance.idProfile,
      'libelle': instance.libelle,
      'description': instance.description,
    };
