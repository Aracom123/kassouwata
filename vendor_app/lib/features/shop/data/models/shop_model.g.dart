// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shop_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ShopModel _$ShopModelFromJson(Map<String, dynamic> json) => ShopModel(
      idBoutique: (json['idBoutique'] as num).toInt(),
      libelle: json['libelle'] as String,
      description: json['description'] as String?,
      adresse: json['adresse'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      commission: (json['commission'] as num?)?.toDouble() ?? 5.0,
      status: json['status'] == null
          ? BoutiqueStatus.pending
          : _boutiqueStatusFromJson(json['status'] as String),
    );

Map<String, dynamic> _$ShopModelToJson(ShopModel instance) => <String, dynamic>{
      'idBoutique': instance.idBoutique,
      'libelle': instance.libelle,
      'description': instance.description,
      'adresse': instance.adresse,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'commission': instance.commission,
      'status': _boutiqueStatusToJson(instance.status),
    };
