import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../catalogue/domain/entities/product_entity.dart';
import '../../domain/entities/cart_item_entity.dart';

part 'cart_event.dart';
part 'cart_state.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc() : super(const CartState()) {
    on<AddToCart>(_onAdd);
    on<RemoveFromCart>(_onRemove);
    on<UpdateCartQuantity>(_onUpdate);
    on<ClearCart>(_onClear);
  }

  void _onAdd(AddToCart event, Emitter<CartState> emit) {
    final items = List<CartItemEntity>.from(state.items);
    final index =
        items.indexWhere((i) => i.product.idProduit == event.product.idProduit);
    if (index >= 0) {
      items[index] = items[index].copyWith(quantity: items[index].quantity + 1);
    } else {
      items.add(CartItemEntity(product: event.product, quantity: 1));
    }
    emit(CartState(items: items));
  }

  void _onRemove(RemoveFromCart event, Emitter<CartState> emit) {
    final items = state.items
        .where((i) => i.product.idProduit != event.productId)
        .toList();
    emit(CartState(items: items));
  }

  void _onUpdate(UpdateCartQuantity event, Emitter<CartState> emit) {
    if (event.quantity <= 0) {
      add(RemoveFromCart(event.productId));
      return;
    }
    final items = state.items.map((i) {
      if (i.product.idProduit == event.productId) {
        return i.copyWith(quantity: event.quantity);
      }
      return i;
    }).toList();
    emit(CartState(items: items));
  }

  void _onClear(ClearCart event, Emitter<CartState> emit) {
    emit(const CartState());
  }
}
