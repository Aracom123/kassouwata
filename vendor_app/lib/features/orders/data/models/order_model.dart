import '../../domain/entities/order_entity.dart';
import '../../../products/data/models/product_model.dart';

class OrderModel {
  final int idCommande;
  final DateTime? dateCommande;
  final String statut;
  final String? typeVente;
  final String? moyenPaiement;
  final double? montantTotal;
  final String? adresseLivraison;
  final ClientModel? client;
  final List<OrderItemModel> lignes;
  final List<ReglementModel> versements;

  const OrderModel({
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

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    DateTime? date;
    final raw = json['dateCommande'] ?? json['created_at'];
    if (raw != null) {
      try {
        date = DateTime.parse(raw.toString());
      } catch (_) {}
    }

    final lignesRaw = json['lignes'] as List<dynamic>? ?? [];
    final versementsRaw = json['versements'] as List<dynamic>? ?? [];

    return OrderModel(
      idCommande: (json['idCommande'] as num).toInt(),
      dateCommande: date,
      statut: json['statut'] as String? ?? 'EN_ATTENTE',
      typeVente: json['typeVente'] as String?,
      moyenPaiement: json['moyenPaiement'] as String?,
      montantTotal: (json['montantTotal'] as num?)?.toDouble(),
      adresseLivraison: json['adresseLivraison'] as String?,
      client: json['client'] != null
          ? ClientModel.fromJson(json['client'] as Map<String, dynamic>)
          : null,
      lignes: lignesRaw
          .map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      versements: versementsRaw
          .map((e) => ReglementModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  OrderEntity toEntity() => OrderEntity(
        idCommande: idCommande,
        dateCommande: dateCommande,
        statut: statut,
        typeVente: typeVente,
        moyenPaiement: moyenPaiement,
        montantTotal: montantTotal,
        adresseLivraison: adresseLivraison,
        client: client?.toEntity(),
        lignes: lignes.map((l) => l.toEntity()).toList(),
        versements: versements.map((v) => v.toEntity()).toList(),
      );
}

class ClientModel {
  final String idUser;
  final String? nom;
  final String? prenom;
  final String? telephone;

  const ClientModel({
    required this.idUser,
    this.nom,
    this.prenom,
    this.telephone,
  });

  factory ClientModel.fromJson(Map<String, dynamic> json) {
    final personne = json['personne'] as Map<String, dynamic>?;
    return ClientModel(
      idUser: json['idUser']?.toString() ?? '',
      nom: personne?['nom'] as String?,
      prenom: personne?['prenom'] as String?,
      telephone: json['telephone'] as String?,
    );
  }

  ClientEntity toEntity() => ClientEntity(
        idUser: idUser,
        nom: nom,
        prenom: prenom,
        telephone: telephone,
      );
}

class OrderItemModel {
  final int idProduitCommande;
  final int quantite;
  final double prixUnitaire;
  final ProductModel? produit;

  const OrderItemModel({
    required this.idProduitCommande,
    required this.quantite,
    required this.prixUnitaire,
    this.produit,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    ProductModel? produit;
    if (json['produit'] != null) {
      try {
        produit = ProductModel.fromJson(json['produit'] as Map<String, dynamic>);
      } catch (_) {}
    }
    return OrderItemModel(
      idProduitCommande: (json['idProduitCommande'] as num).toInt(),
      quantite: (json['quantite'] as num).toInt(),
      prixUnitaire: (json['prixUnitaire'] as num?)?.toDouble() ?? 0.0,
      produit: produit,
    );
  }

  OrderItemEntity toEntity() => OrderItemEntity(
        idProduitCommande: idProduitCommande,
        quantite: quantite,
        prixUnitaire: prixUnitaire,
        produit: produit?.toEntity(),
      );
}

class ReglementModel {
  final int idTransaction;
  final DateTime? dateTransaction;
  final String? modePaiement;
  final String? moyenPaiement;
  final double montant;
  final String? statut;

  const ReglementModel({
    required this.idTransaction,
    this.dateTransaction,
    this.modePaiement,
    this.moyenPaiement,
    required this.montant,
    this.statut,
  });

  factory ReglementModel.fromJson(Map<String, dynamic> json) {
    DateTime? date;
    final raw = json['dateTransaction'];
    if (raw != null) {
      try {
        date = DateTime.parse(raw.toString());
      } catch (_) {}
    }
    return ReglementModel(
      idTransaction: (json['idTransaction'] as num).toInt(),
      dateTransaction: date,
      modePaiement: json['modePaiement'] as String?,
      moyenPaiement: json['moyenPaiement'] as String?,
      montant: (json['montant'] as num?)?.toDouble() ?? 0.0,
      statut: (json['statut'] as String?)?.toUpperCase(),
    );
  }

  ReglementEntity toEntity() => ReglementEntity(
        idTransaction: idTransaction,
        dateTransaction: dateTransaction,
        modePaiement: modePaiement,
        moyenPaiement: moyenPaiement,
        montant: montant,
        statut: statut,
      );
}
