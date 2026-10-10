import 'package:equatable/equatable.dart';

import '../../../products/domain/entities/product_entity.dart';

class OrderEntity extends Equatable {
  final int idCommande;
  final DateTime? dateCommande;
  final String statut;
  final String? typeVente;
  final String? moyenPaiement;
  final double? montantTotal;
  final String? adresseLivraison;
  final ClientEntity? client;
  final List<OrderItemEntity> lignes;
  final List<ReglementEntity> versements;

  const OrderEntity({
    required this.idCommande,
    this.dateCommande,
    this.statut = 'EN_ATTENTE',
    this.typeVente,
    this.moyenPaiement,
    this.montantTotal,
    this.adresseLivraison,
    this.client,
    this.lignes = const [],
    this.versements = const [],
  });

  /// Montant calculé uniquement pour les lignes de la boutique [idBoutique].
  double montantPourBoutique(int idBoutique) {
    return lignes
        .where((l) => l.produit?.idBoutique == idBoutique)
        .fold(0.0, (sum, l) => sum + l.prixUnitaire * l.quantite);
  }

  /// Lignes filtrées pour la boutique [idBoutique].
  List<OrderItemEntity> lignesPourBoutique(int idBoutique) =>
      lignes.where((l) => l.produit?.idBoutique == idBoutique).toList();

  @override
  List<Object?> get props => [idCommande, statut, dateCommande, versements];
}

class ClientEntity extends Equatable {
  final String idUser;
  final String? nom;
  final String? prenom;
  final String? telephone;

  const ClientEntity({
    required this.idUser,
    this.nom,
    this.prenom,
    this.telephone,
  });

  String get displayName {
    if (nom != null && prenom != null) return '$prenom $nom';
    if (nom != null) return nom!;
    if (prenom != null) return prenom!;
    return telephone ?? idUser;
  }

  @override
  List<Object?> get props => [idUser];
}

class OrderItemEntity extends Equatable {
  final int idProduitCommande;
  final int quantite;
  final double prixUnitaire;
  final ProductEntity? produit;

  const OrderItemEntity({
    required this.idProduitCommande,
    required this.quantite,
    required this.prixUnitaire,
    this.produit,
  });

  double get sousTotal => prixUnitaire * quantite;

  @override
  List<Object?> get props => [idProduitCommande, quantite, prixUnitaire];
}

class ReglementEntity extends Equatable {
  final int idTransaction;
  final DateTime? dateTransaction;
  final String? modePaiement;
  final String? moyenPaiement;
  final double montant;

  const ReglementEntity({
    required this.idTransaction,
    this.dateTransaction,
    this.modePaiement,
    this.moyenPaiement,
    required this.montant,
  });

  @override
  List<Object?> get props => [idTransaction];
}
