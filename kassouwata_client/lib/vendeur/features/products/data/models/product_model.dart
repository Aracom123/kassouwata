import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/product_entity.dart';
import 'categorie_model.dart';

part 'product_model.g.dart';

@JsonSerializable()
class ProductModel {
  final int idProduit;
  final String libelle;
  final String? description;
  final double prixUnitaire;
  final int quantite;
  final String? imagePrincipale;
  final String? photos;
  final bool statut;
  final int? nombreTranches;
  final bool adasheAutorise;
  final CategorieModel? categorie;
  final int? idBoutique;

  const ProductModel({
    required this.idProduit,
    required this.libelle,
    this.description,
    required this.prixUnitaire,
    required this.quantite,
    this.imagePrincipale,
    this.photos,
    this.statut = false,
    this.nombreTranches,
    this.adasheAutorise = false,
    this.categorie,
    this.idBoutique,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) =>
      _$ProductModelFromJson(json);
  Map<String, dynamic> toJson() => _$ProductModelToJson(this);

  ProductEntity toEntity() => ProductEntity(
        idProduit: idProduit,
        libelle: libelle,
        description: description,
        prixUnitaire: prixUnitaire,
        quantite: quantite,
        imagePrincipale: imagePrincipale,
        photos: photos,
        statut: statut,
        nombreTranches: nombreTranches,
        adasheAutorise: adasheAutorise,
        categorie: categorie,
        idBoutique: idBoutique,
      );
}