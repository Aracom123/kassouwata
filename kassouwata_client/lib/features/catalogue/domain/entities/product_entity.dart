import 'package:equatable/equatable.dart';

class CategoryEntity extends Equatable {
  final int idCategorie;
  final String libelle;

  const CategoryEntity({required this.idCategorie, required this.libelle});

  @override
  List<Object?> get props => [idCategorie];
}

class ProductEntity extends Equatable {
  final int idProduit;
  final String libelle;
  final String? description;
  final double prix;
  final int? quantiteStock;
  final String? imageFilename;
  /// Photos supplémentaires (filenames séparés par des virgules, ex: "a.jpg,b.jpg")
  final String? photos;
  final CategoryEntity? categorie;
  final String? vendeurTelephone;
  final String? vendeurNom;
  /// Identifiant de la boutique — permet de naviguer vers la page boutique.
  final int? idBoutique;
  /// Nom de la boutique affiché sur la page détail.
  final String? boutiqueName;
  /// Nombre de tranches pour le paiement prépayé.
  /// Null = paiement en tranches non disponible pour ce produit.
  final int? nombreTranches;
  /// Date de publication du produit — champ `created_at` côté API (pour tri décroissant).
  final DateTime? createdDate;

  const ProductEntity({
    required this.idProduit,
    required this.libelle,
    this.description,
    required this.prix,
    this.quantiteStock,
    this.imageFilename,
    this.photos,
    this.categorie,
    this.vendeurTelephone,
    this.vendeurNom,
    this.idBoutique,
    this.boutiqueName,
    this.nombreTranches,
    this.createdDate,
  });

  bool get isAvailable => (quantiteStock ?? 1) > 0;

  /// Retourne la liste de tous les filenames d'images :
  /// l'image principale en premier, suivie des photos supplémentaires.
  List<String> get allImageFilenames {
    final list = <String>[];
    if (imageFilename != null && imageFilename!.isNotEmpty) {
      list.add(imageFilename!);
    }
    if (photos != null && photos!.isNotEmpty) {
      list.addAll(photos!.split(',').where((s) => s.trim().isNotEmpty));
    }
    return list;
  }

  @override
  List<Object?> get props => [idProduit, nombreTranches];
}
