part of 'order_bloc.dart';

enum OrderStatus2 {
  initial,
  loading,
  success,
  placing,
  placed,
  cancelling,
  cancelled,
  versementsLoading,
  versementsLoaded,
  versementSaving,
  versementSaved,
  failure,
}

class OrderState extends Equatable {
  final OrderStatus2 status;
  final List<OrderEntity> orders;
  /// Toutes les commandes créées lors du dernier appel placeOrder.
  /// POSTPAYE → 1 élément, PREPAYE → N éléments (une par produit).
  final List<OrderEntity> placedOrders;
  final List<VersementEntity> versements;
  /// Id de la commande pour laquelle [versements] a été chargé depuis l'API
  final int? versementsCommandeId;
  final String? errorMessage;

  const OrderState({
    this.status = OrderStatus2.initial,
    this.orders = const [],
    this.placedOrders = const [],
    this.versements = const [],
    this.versementsCommandeId,
    this.errorMessage,
  });

  /// Commodité : première commande placée (compatibilité ancienne UI).
  OrderEntity? get placedOrder =>
      placedOrders.isNotEmpty ? placedOrders.first : null;

  OrderState copyWith({
    OrderStatus2? status,
    List<OrderEntity>? orders,
    List<OrderEntity>? placedOrders,
    List<VersementEntity>? versements,
    int? versementsCommandeId,
    String? errorMessage,
  }) =>
      OrderState(
        status: status ?? this.status,
        orders: orders ?? this.orders,
        placedOrders: placedOrders ?? this.placedOrders,
        versements: versements ?? this.versements,
        versementsCommandeId: versementsCommandeId ?? this.versementsCommandeId,
        errorMessage: errorMessage ?? this.errorMessage,
      );

  @override
  List<Object?> get props =>
      [status, orders, placedOrders, versements, versementsCommandeId, errorMessage];
}
