import 'package:equatable/equatable.dart';
import 'categorie_entity.dart';

class ProductEntity extends Equatable {
  final int idProduit;
  final String libelle;
  final String? description;
  final double prixUnitaire;
  final int quantite;
  final String? imagePrincipale;
  final String? photos;
  final bool statut;
  /// Nombre de tranches pour le paiement prépayé.
  /// Null = paiement en tranches non disponible pour ce produit.
  final int? nombreTranches;
  /// Le produit peut être acheté en groupe (Adashé Produit)
  final bool adasheAutorise;
  final CategorieEntity? categorie;
  final int? idBoutique;

  const ProductEntity({
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

  @override
  List<Object?> get props => [idProduit, libelle, prixUnitaire, quantite, nombreTranches];
}