part of 'cart_bloc.dart';

abstract class CartEvent extends Equatable {
  const CartEvent();
  @override
  List<Object?> get props => [];
}

class AddToCart extends CartEvent {
  final ProductEntity product;
  const AddToCart(this.product);
  @override
  List<Object?> get props => [product.idProduit];
}

class RemoveFromCart extends CartEvent {
  final int productId;
  const RemoveFromCart(this.productId);
  @override
  List<Object?> get props => [productId];
}

class UpdateCartQuantity extends CartEvent {
  final int productId;
  final int quantity;
  const UpdateCartQuantity(this.productId, this.quantity);
  @override
  List<Object?> get props => [productId, quantity];
}

class ClearCart extends CartEvent {
  const ClearCart();
}
