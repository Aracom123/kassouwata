part of 'order_bloc.dart';

abstract class OrderState extends Equatable {
  const OrderState();
  @override
  List<Object?> get props => [];
}

class OrderInitial extends OrderState {}
class OrderLoading extends OrderState {}

class OrdersLoaded extends OrderState {
  final List<OrderEntity> orders;
  const OrdersLoaded(this.orders);
  @override
  List<Object?> get props => [orders];
}

class OrderDetailLoaded extends OrderState {
  final OrderEntity order;
  final int idBoutique;
  const OrderDetailLoaded(this.order, {required this.idBoutique});
  @override
  List<Object?> get props => [order, idBoutique];
}

class OrderStatusUpdating extends OrderState {}

class OrderStatusUpdated extends OrderState {
  final OrderEntity order;
  const OrderStatusUpdated(this.order);
  @override
  List<Object?> get props => [order];
}

class OrderFailure extends OrderState {
  final String message;
  const OrderFailure(this.message);
  @override
  List<Object?> get props => [message];
}
