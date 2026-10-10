part of 'order_bloc.dart';

abstract class OrderEvent extends Equatable {
  const OrderEvent();
  @override
  List<Object?> get props => [];
}

class LoadOrders extends OrderEvent {
  const LoadOrders();
}

class PlaceOrder extends OrderEvent {
  final List<CartItemEntity> items;
  final PaymentMethod modePaiement;
  final TypeVente typeVente;
  final String? adresseLivraison;

  const PlaceOrder({
    required this.items,
    required this.modePaiement,
    required this.typeVente,
    this.adresseLivraison,
  });

  @override
  List<Object?> get props => [items, modePaiement, typeVente];
}

class CancelOrder extends OrderEvent {
  final int idCommande;
  const CancelOrder(this.idCommande);

  @override
  List<Object?> get props => [idCommande];
}

class LoadVersements extends OrderEvent {
  final int commandeId;
  const LoadVersements(this.commandeId);

  @override
  List<Object?> get props => [commandeId];
}

class AddVersement extends OrderEvent {
  final int commandeId;
  final double montant;
  final String modePaiement;
  final String? moyenPaiement;

  const AddVersement({
    required this.commandeId,
    required this.montant,
    required this.modePaiement,
    this.moyenPaiement,
  });

  @override
  List<Object?> get props => [commandeId, montant, modePaiement];
}
