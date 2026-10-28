part of 'product_bloc.dart';

abstract class ProductEvent extends Equatable {
  const ProductEvent();
  @override
  List<Object?> get props => [];
}

class LoadProducts extends ProductEvent {
  final int idBoutique;
  const LoadProducts(this.idBoutique);
  @override
  List<Object?> get props => [idBoutique];
}

class CreateProduct extends ProductEvent {
  final int idBoutique;
  final String libelle;
  final String? description;
  final double prixUnitaire;
  final int quantite;
  final int? nombreTranches;
  final int? idCategorie;
  final String? imagePrincipalePath;
  final List<String>? photosPaths;

  const CreateProduct({
    required this.idBoutique,
    required this.libelle,
    this.description,
    required this.prixUnitaire,
    required this.quantite,
    this.nombreTranches,
    this.idCategorie,
    this.imagePrincipalePath,
    this.photosPaths,
  });

  @override
  List<Object?> get props => [idBoutique, libelle, prixUnitaire, nombreTranches];
}

class UpdateProduct extends ProductEvent {
  final int idProduit;
  final int idBoutique;
  final String libelle;
  final String? description;
  final double prixUnitaire;
  final int quantite;
  final bool statut;
  final int? nombreTranches;
  final int? idCategorie;
  final String? imagePrincipalePath;
  final List<String>? photosPaths;
  final String? existingImagePrincipale;
  final List<String>? existingPhotos;

  const UpdateProduct({
    required this.idProduit,
    required this.idBoutique,
    required this.libelle,
    this.description,
    required this.prixUnitaire,
    required this.quantite,
    required this.statut,
    this.nombreTranches,
    this.idCategorie,
    this.imagePrincipalePath,
    this.photosPaths,
    this.existingImagePrincipale,
    this.existingPhotos,
  });

  @override
  List<Object?> get props => [idProduit, nombreTranches];
}

class DeleteProduct extends ProductEvent {
  final int idProduit;
  const DeleteProduct(this.idProduit);
  @override
  List<Object?> get props => [idProduit];
}
