// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'livraison_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LivraisonModel _$LivraisonModelFromJson(Map<String, dynamic> json) =>
    LivraisonModel(
      idLivraison: (json['idLivraison'] as num).toInt(),
      dateLivraison: json['dateLivraison'] == null
          ? null
          : DateTime.parse(json['dateLivraison'] as String),
      adresseLivraison: json['adresseLivraison'] as String?,
      idCommande: (json['idCommande'] as num?)?.toInt(),
    );

Map<String, dynamic> _$LivraisonModelToJson(LivraisonModel instance) =>
    <String, dynamic>{
      'idLivraison': instance.idLivraison,
      'dateLivraison': instance.dateLivraison?.toIso8601String(),
      'adresseLivraison': instance.adresseLivraison,
      'idCommande': instance.idCommande,
    };
