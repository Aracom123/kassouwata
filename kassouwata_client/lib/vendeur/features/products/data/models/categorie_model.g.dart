// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'categorie_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CategorieModel _$CategorieModelFromJson(Map<String, dynamic> json) =>
    CategorieModel(
      idCategorie: (json['idCategorie'] as num).toInt(),
      libelle: json['libelle'] as String,
      description: json['description'] as String?,
    );

Map<String, dynamic> _$CategorieModelToJson(CategorieModel instance) =>
    <String, dynamic>{
      'idCategorie': instance.idCategorie,
      'libelle': instance.libelle,
      'description': instance.description,
    };
