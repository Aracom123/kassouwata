import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../cart/domain/entities/cart_item_entity.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/repositories/order_repository.dart';

part 'order_event.dart';
part 'order_state.dart';

class OrderBloc extends Bloc<OrderEvent, OrderState> {
  final OrderRepository _repository;

  OrderBloc(this._repository) : super(const OrderState()) {
    on<LoadOrders>(_onLoad);
    on<PlaceOrder>(_onPlace);
    on<CancelOrder>(_onCancel);
    on<LoadVersements>(_onLoadVersements);
    on<AddVersement>(_onAddVersement);
  }

  Future<void> _onLoad(LoadOrders event, Emitter<OrderState> emit) async {
    emit(state.copyWith(status: OrderStatus2.loading));
    final result = await _repository.getMyOrders();
    result.fold(
      (f) => emit(state.copyWith(
          status: OrderStatus2.failure, errorMessage: f.message)),
      (orders) =>
          emit(state.copyWith(status: OrderStatus2.success, orders: orders)),
    );
  }

  Future<void> _onPlace(PlaceOrder event, Emitter<OrderState> emit) async {
    emit(state.copyWith(status: OrderStatus2.placing));
    final result = await _repository.placeOrder(
      items: event.items,
      modePaiement: event.modePaiement,
      typeVente: event.typeVente,
      adresseLivraison: event.adresseLivraison,
    );
    result.fold(
      (f) => emit(state.copyWith(
          status: OrderStatus2.failure, errorMessage: f.message)),
      (placedList) => emit(state.copyWith(
          status: OrderStatus2.placed, placedOrders: placedList)),
    );
  }

  Future<void> _onCancel(CancelOrder event, Emitter<OrderState> emit) async {
    emit(state.copyWith(status: OrderStatus2.cancelling));
    final result = await _repository.cancelOrder(event.idCommande);
    result.fold(
      (f) => emit(state.copyWith(
          status: OrderStatus2.failure, errorMessage: f.message)),
      (updated) {
        final updatedList = state.orders
            .map((o) => o.idCommande == updated.idCommande ? updated : o)
            .toList();
        emit(state.copyWith(
            status: OrderStatus2.cancelled, orders: updatedList));
      },
    );
  }

  Future<void> _onLoadVersements(
      LoadVersements event, Emitter<OrderState> emit) async {
    emit(state.copyWith(status: OrderStatus2.versementsLoading));
    final result = await _repository.getVersements(event.commandeId);
    result.fold(
      (f) => emit(state.copyWith(
          status: OrderStatus2.failure, errorMessage: f.message)),
      (versements) => emit(state.copyWith(
          status: OrderStatus2.versementsLoaded,
          versements: versements,
          versementsCommandeId: event.commandeId)),
    );
  }

  Future<void> _onAddVersement(
      AddVersement event, Emitter<OrderState> emit) async {
    emit(state.copyWith(status: OrderStatus2.versementSaving));
    final result = await _repository.addVersement(
      commandeId: event.commandeId,
      montant: event.montant,
      modePaiement: event.modePaiement,
      moyenPaiement: event.moyenPaiement,
    );
    result.fold(
      (f) => emit(state.copyWith(
          status: OrderStatus2.failure, errorMessage: f.message)),
      (versement) {
        final updated = [...state.versements, versement];
        emit(state.copyWith(
            status: OrderStatus2.versementSaved, versements: updated));
      },
    );
  }
}
