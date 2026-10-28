part of 'order_bloc.dart';

abstract class OrderEvent extends Equatable {
  const OrderEvent();
  @override
  List<Object?> get props => [];
}

class LoadOrders extends OrderEvent {
  final int idBoutique;
  const LoadOrders(this.idBoutique);
  @override
  List<Object?> get props => [idBoutique];
}

class LoadOrderDetail extends OrderEvent {
  final int orderId;
  final int idBoutique;
  const LoadOrderDetail(this.orderId, {required this.idBoutique});
  @override
  List<Object?> get props => [orderId, idBoutique];
}

class UpdateOrderStatut extends OrderEvent {
  final int orderId;
  final String statut;
  const UpdateOrderStatut(this.orderId, this.statut);
  @override
  List<Object?> get props => [orderId, statut];
}
