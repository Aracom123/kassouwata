// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_boutique_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateBoutiqueRequestModel _$CreateBoutiqueRequestModelFromJson(
        Map<String, dynamic> json) =>
    CreateBoutiqueRequestModel(
      libelle: json['libelle'] as String,
      description: json['description'] as String?,
      adresse: json['adresse'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      vendeur: BoutiqueVendeurModel.fromJson(
          json['vendeur'] as Map<String, dynamic>),
      status: json['status'] as String? ?? 'PENDING',
    );

Map<String, dynamic> _$CreateBoutiqueRequestModelToJson(
        CreateBoutiqueRequestModel instance) =>
    <String, dynamic>{
      'libelle': instance.libelle,
      'description': instance.description,
      'adresse': instance.adresse,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'vendeur': instance.vendeur,
      'status': instance.status,
    };

BoutiqueVendeurModel _$BoutiqueVendeurModelFromJson(
        Map<String, dynamic> json) =>
    BoutiqueVendeurModel(
      idUser: json['idUser'] as String,
    );

Map<String, dynamic> _$BoutiqueVendeurModelToJson(
        BoutiqueVendeurModel instance) =>
    <String, dynamic>{
      'idUser': instance.idUser,
    };
