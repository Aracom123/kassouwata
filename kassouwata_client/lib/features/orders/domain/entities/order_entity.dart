import 'package:equatable/equatable.dart';

enum OrderStatus { enAttente, confirmee, livree, annulee }

/// [enLigne] : paiement via l'agrégateur (Mobile Money, STA ou carte),
/// le moyen exact est choisi sur l'écran de paiement.
enum PaymentMethod { especes, mobileMoney, carte, enLigne }

enum TypeVente { prepaye, postpaye }

/// Opérateurs Mobile Money disponibles pour les versements.
enum OperateurVersement { airtel, nita, amanata, moov, wave }

class VersementEntity extends Equatable {
  final int idTransaction;
  final double montant;
  final DateTime dateTransaction;
  /// Catégorie : CASH_LIVRAISON | MOBILE_MONEY | CARTE
  final String? modePaiement;
  /// Opérateur/réseau : AIRTEL_MONEY | NITA | AMANA | VISA | MASTERCARD...
  final String? moyenPaiement;
  /// Paiement en ligne : EN_ATTENTE | REUSSIE | ECHOUEE.
  /// null pour les anciens versements saisis manuellement (considérés payés).
  final String? statut;

  const VersementEntity({
    required this.idTransaction,
    required this.montant,
    required this.dateTransaction,
    this.modePaiement,
    this.moyenPaiement,
    this.statut,
  });

  bool get estReussi => statut == null || statut == 'REUSSIE';
  bool get estEnAttente => statut == 'EN_ATTENTE';
  bool get estEchoue => statut == 'ECHOUEE';

  @override
  List<Object?> get props => [idTransaction];
}

class OrderLineEntity extends Equatable {
  final int idProduitCommande;
  final int idProduit;
  final String libelleProduit;
  final double prixUnitaire;
  final int quantite;

  const OrderLineEntity({
    required this.idProduitCommande,
    required this.idProduit,
    required this.libelleProduit,
    required this.prixUnitaire,
    required this.quantite,
  });

  double get subtotal => prixUnitaire * quantite;

  @override
  List<Object?> get props => [idProduitCommande];
}

class OrderEntity extends Equatable {
  final int idCommande;
  final DateTime dateCommande;
  final OrderStatus statut;
  final PaymentMethod modePaiement;
  final TypeVente typeVente;
  final double montantTotal;
  final List<OrderLineEntity> lignes;
  final List<VersementEntity> versements;
  final String? adresseLivraison;
  /// Nombre de tranches du produit concerné (pour les commandes PREPAYE).
  /// Récupéré depuis `lignes[0].produit.nombreTranches` côté API.
  final int? nombreTranches;

  const OrderEntity({
    required this.idCommande,
    required this.dateCommande,
    required this.statut,
    required this.modePaiement,
    required this.montantTotal,
    this.typeVente = TypeVente.prepaye,
    this.lignes = const [],
    this.versements = const [],
    this.adresseLivraison,
    this.nombreTranches,
  });

  /// Seuls les versements réussis (ou manuels) sont comptés.
  double get montantPaye => versements
      .where((v) => v.estReussi)
      .fold(0, (sum, v) => sum + v.montant);

  double get montantRestant => (montantTotal - montantPaye).clamp(0, montantTotal);

  bool get estSolde => montantRestant <= 0;

  String get statutLabel {
    switch (statut) {
      case OrderStatus.enAttente:
        return 'En attente';
      case OrderStatus.confirmee:
        return 'Confirmée';
      case OrderStatus.livree:
        return 'Livrée';
      case OrderStatus.annulee:
        return 'Annulée';
    }
  }

  String get typeVenteLabel =>
      typeVente == TypeVente.postpaye ? 'Post-payé' : 'Pré-payé';

  /// Montant fixe par tranche (null si nombreTranches est nul ou zéro).
  double? get montantParTranche =>
      (nombreTranches != null && nombreTranches! > 0)
          ? montantTotal / nombreTranches!
          : null;

  @override
  List<Object?> get props => [idCommande];
}
