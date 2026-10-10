import '../../domain/entities/order_entity.dart';

class VersementModel extends VersementEntity {
  const VersementModel({
    required super.idTransaction,
    required super.montant,
    required super.dateTransaction,
    super.modePaiement,
    super.moyenPaiement,
    super.statut,
  });

  factory VersementModel.fromJson(Map<String, dynamic> json) {
    return VersementModel(
      idTransaction: (json['idTransaction'] as num).toInt(),
      montant: (json['montant'] as num?)?.toDouble() ?? 0,
      dateTransaction: json['dateTransaction'] != null
          ? DateTime.tryParse(json['dateTransaction'].toString()) ??
              DateTime.now()
          : DateTime.now(),
      modePaiement: json['modePaiement'] as String?,
      moyenPaiement: json['moyenPaiement'] as String?,
      statut: (json['statut'] as String?)?.toUpperCase(),
    );
  }

  Map<String, dynamic> toJson({required int idCommande}) => {
        'commande': {'idCommande': idCommande},
        'montant': montant,
        'dateTransaction': dateTransaction.toIso8601String(),
        if (modePaiement != null) 'modePaiement': modePaiement,
        if (moyenPaiement != null) 'moyenPaiement': moyenPaiement,
      };
}

class OrderLineModel extends OrderLineEntity {
  const OrderLineModel({
    required super.idProduitCommande,
    required super.idProduit,
    required super.libelleProduit,
    required super.prixUnitaire,
    required super.quantite,
  });

  factory OrderLineModel.fromJson(Map<String, dynamic> json) {
    final produit = json['produit'] as Map<String, dynamic>?;
    return OrderLineModel(
      idProduitCommande: (json['idProduitCommande'] as num).toInt(),
      idProduit: (produit?['idProduit'] as num?)?.toInt() ?? 0,
      libelleProduit: produit?['libelle'] as String? ?? '',
      prixUnitaire: (json['prixUnitaire'] as num?)?.toDouble() ?? 0,
      quantite: (json['quantite'] as num?)?.toInt() ?? 1,
    );
  }

  /// Sérialise la ligne pour l'envoi au backend.
  /// [idCommande] est optionnel : null lorsque la ligne est incluse dans
  /// le corps de la commande initiale (avant que la commande ait un ID).
  Map<String, dynamic> toJson({int? idCommande}) => {
        if (idCommande != null) 'commande': {'idCommande': idCommande},
        'produit': {'idProduit': idProduit},
        'prixUnitaire': prixUnitaire,
        'quantite': quantite,
      };
}

class OrderModel extends OrderEntity {
  const OrderModel({
    required super.idCommande,
    required super.dateCommande,
    required super.statut,
    required super.modePaiement,
    required super.montantTotal,
    super.typeVente,
    super.lignes,
    super.versements,
    super.adresseLivraison,
    super.nombreTranches,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final statutStr =
        (json['statut'] as String? ?? 'EN_ATTENTE').toUpperCase();
    final paiementStr =
        (json['moyenPaiement'] as String? ?? 'ESPECES').toUpperCase();
    final typeVenteStr =
        (json['typeVente'] as String? ?? 'PREPAYE').toUpperCase();

    OrderStatus statut;
    switch (statutStr) {
      case 'CONFIRMEE':
        statut = OrderStatus.confirmee;
      case 'LIVREE':
        statut = OrderStatus.livree;
      case 'ANNULEE':
        statut = OrderStatus.annulee;
      default:
        statut = OrderStatus.enAttente;
    }

    PaymentMethod paiement;
    switch (paiementStr) {
      case 'MOBILE_MONEY':
        paiement = PaymentMethod.mobileMoney;
      case 'CARTE':
        paiement = PaymentMethod.carte;
      case 'EN_LIGNE':
        paiement = PaymentMethod.enLigne;
      default:
        paiement = PaymentMethod.especes;
    }

    final typeVente = typeVenteStr == 'POSTPAYE'
        ? TypeVente.postpaye
        : TypeVente.prepaye;

    final lignesJson = json['lignes'] as List<dynamic>? ?? [];
    final versementsJson = json['versements'] as List<dynamic>? ?? [];

    // Récupère nombreTranches depuis le premier produit de la commande
    int? nombreTranches;
    if (lignesJson.isNotEmpty) {
      final firstLigne = lignesJson.first as Map<String, dynamic>;
      final produit = firstLigne['produit'] as Map<String, dynamic>?;
      nombreTranches = (produit?['nombreTranches'] as num?)?.toInt();
    }

    final rawDate = json['dateCommande'] ?? json['created_at'];
    final dateCommande = rawDate != null
        ? DateTime.tryParse(rawDate.toString())?.toLocal() ?? DateTime.now()
        : DateTime.now();

    return OrderModel(
      idCommande: (json['idCommande'] as num).toInt(),
      dateCommande: dateCommande,
      statut: statut,
      modePaiement: paiement,
      typeVente: typeVente,
      montantTotal: (json['montantTotal'] as num?)?.toDouble() ?? 0,
      nombreTranches: nombreTranches,
      lignes: lignesJson
          .map((e) => OrderLineModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      versements: versementsJson
          .map((e) => VersementModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      adresseLivraison: json['adresseLivraison'] as String?,
    );
  }

  /// Sérialise la commande pour l'envoi au backend.
  /// [lignes] est la liste des articles du panier à inclure dans le corps
  /// (obligatoire en mode PREPAYE, le backend éclate en N commandes côté serveur).
  Map<String, dynamic> toJson(String userId, {List<Map<String, dynamic>> lignes = const []}) => {
        'client': {'idUser': userId},
        'statut': 'EN_ATTENTE',
        'moyenPaiement': _paiementToString(modePaiement),
        'typeVente': typeVente == TypeVente.postpaye ? 'POSTPAYE' : 'PREPAYE',
        'montantTotal': montantTotal,
        if (adresseLivraison != null) 'adresseLivraison': adresseLivraison,
        if (lignes.isNotEmpty) 'lignes': lignes,
      };

  static String _paiementToString(PaymentMethod m) {
    switch (m) {
      case PaymentMethod.mobileMoney:
        return 'MOBILE_MONEY';
      case PaymentMethod.carte:
        return 'CARTE';
      case PaymentMethod.enLigne:
        return 'EN_LIGNE';
      default:
        return 'ESPECES';
    }
  }
}
