import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/repositories/order_repository.dart';

part 'order_event.dart';
part 'order_state.dart';

@injectable
class OrderBloc extends Bloc<OrderEvent, OrderState> {
  final OrderRepository _repository;

  OrderBloc(this._repository) : super(OrderInitial()) {
    on<LoadOrders>(_onLoadOrders);
    on<LoadOrderDetail>(_onLoadOrderDetail);
    on<UpdateOrderStatut>(_onUpdateOrderStatut);
  }

  Future<void> _onLoadOrders(LoadOrders event, Emitter<OrderState> emit) async {
    emit(OrderLoading());
    final result = await _repository.getOrdersByShop(event.idBoutique);
    result.fold(
      (f) => emit(OrderFailure(f.message)),
      (orders) => emit(OrdersLoaded(orders)),
    );
  }

  Future<void> _onLoadOrderDetail(
      LoadOrderDetail event, Emitter<OrderState> emit) async {
    emit(OrderLoading());
    final result = await _repository.getOrderById(event.orderId);
    result.fold(
      (f) => emit(OrderFailure(f.message)),
      (order) => emit(OrderDetailLoaded(order, idBoutique: event.idBoutique)),
    );
  }

  Future<void> _onUpdateOrderStatut(
      UpdateOrderStatut event, Emitter<OrderState> emit) async {
    emit(OrderStatusUpdating());
    final result = await _repository.updateOrderStatut(event.orderId, event.statut);
    result.fold(
      (f) => emit(OrderFailure(f.message)),
      (order) => emit(OrderStatusUpdated(order)),
    );
  }
}
