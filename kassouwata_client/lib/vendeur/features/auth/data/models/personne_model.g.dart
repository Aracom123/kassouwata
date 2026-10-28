// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'personne_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PersonneModel _$PersonneModelFromJson(Map<String, dynamic> json) =>
    PersonneModel(
      idPersonne: json['idPersonne'] as String,
      nom: json['nom'] as String,
      prenom: json['prenom'] as String,
      email: json['email'] as String?,
      genre: json['genre'] as String?,
      adresse: json['adresse'] as String?,
      dateNaissance: json['dateNaissance'] == null
          ? null
          : DateTime.parse(json['dateNaissance'] as String),
      lieuNaissance: json['lieuNaissance'] as String?,
      photo: json['photo'] as String?,
    );

Map<String, dynamic> _$PersonneModelToJson(PersonneModel instance) =>
    <String, dynamic>{
      'idPersonne': instance.idPersonne,
      'nom': instance.nom,
      'prenom': instance.prenom,
      'email': instance.email,
      'genre': instance.genre,
      'adresse': instance.adresse,
      'dateNaissance': instance.dateNaissance?.toIso8601String(),
      'lieuNaissance': instance.lieuNaissance,
      'photo': instance.photo,
    };
