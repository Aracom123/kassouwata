import '../../domain/entities/product_entity.dart';

class CategoryModel extends CategoryEntity {
  const CategoryModel({required super.idCategorie, required super.libelle});

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
        idCategorie: (json['idCategorie'] as num).toInt(),
        libelle: json['libelle'] as String? ?? '',
      );
}

class ProductModel extends ProductEntity {
  const ProductModel({
    required super.idProduit,
    required super.libelle,
    super.description,
    required super.prix,
    super.quantiteStock,
    super.imageFilename,
    super.photos,
    super.categorie,
    super.vendeurTelephone,
    super.vendeurNom,
    super.idBoutique,
    super.boutiqueName,
    super.nombreTranches,
    super.createdDate,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final cat = json['categorie'] as Map<String, dynamic>?;
    final boutique = json['boutique'] as Map<String, dynamic>?;
    final vendeur = boutique?['vendeur'] as Map<String, dynamic>?;
    final vendeurPersonne = vendeur?['personne'] as Map<String, dynamic>?;
    return ProductModel(
      idProduit: (json['idProduit'] as num).toInt(),
      libelle: json['libelle'] as String? ?? '',
      description: json['description'] as String?,
      prix: (json['prixUnitaire'] as num?)?.toDouble() ?? 0.0,
      quantiteStock: (json['quantite'] as num?)?.toInt(),
      imageFilename: json['imagePrincipale'] as String?,
      photos: json['photos'] as String?,
      categorie: cat != null ? CategoryModel.fromJson(cat) : null,
      vendeurTelephone: vendeur?['telephone'] as String?,
      vendeurNom: vendeur != null
          ? ((vendeurPersonne?['prenom'] as String?) ??
              (vendeur['telephone'] as String?) ??
              '')
          : null,
      idBoutique: (boutique?['idBoutique'] as num?)?.toInt(),
      boutiqueName: boutique?['libelle'] as String?,
      nombreTranches: (json['nombreTranches'] as num?)?.toInt(),
      createdDate: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }
}
