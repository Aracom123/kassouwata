// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductModel _$ProductModelFromJson(Map<String, dynamic> json) => ProductModel(
      idProduit: (json['idProduit'] as num).toInt(),
      libelle: json['libelle'] as String,
      description: json['description'] as String?,
      prixUnitaire: (json['prixUnitaire'] as num).toDouble(),
      quantite: (json['quantite'] as num).toInt(),
      imagePrincipale: json['imagePrincipale'] as String?,
      photos: json['photos'] as String?,
      statut: json['statut'] as bool? ?? false,
      nombreTranches: (json['nombreTranches'] as num?)?.toInt(),
      adasheAutorise: json['adasheAutorise'] as bool? ?? false,
      categorie: json['categorie'] == null
          ? null
          : CategorieModel.fromJson(json['categorie'] as Map<String, dynamic>),
      idBoutique: (json['idBoutique'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ProductModelToJson(ProductModel instance) =>
    <String, dynamic>{
      'idProduit': instance.idProduit,
      'libelle': instance.libelle,
      'description': instance.description,
      'prixUnitaire': instance.prixUnitaire,
      'quantite': instance.quantite,
      'imagePrincipale': instance.imagePrincipale,
      'photos': instance.photos,
      'statut': instance.statut,
      'nombreTranches': instance.nombreTranches,
      'adasheAutorise': instance.adasheAutorise,
      'categorie': instance.categorie,
      'idBoutique': instance.idBoutique,
    };
