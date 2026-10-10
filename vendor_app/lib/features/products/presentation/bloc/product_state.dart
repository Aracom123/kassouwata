part of 'product_bloc.dart';

abstract class ProductState extends Equatable {
  const ProductState();
  @override
  List<Object?> get props => [];
}

class ProductInitial extends ProductState {}
class ProductLoading extends ProductState {}

class ProductsLoaded extends ProductState {
  final List<ProductEntity> products;
  const ProductsLoaded(this.products);
  @override
  List<Object?> get props => [products];
}

class ProductOperationSuccess extends ProductState {
  final String message;
  const ProductOperationSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

class ProductFailure extends ProductState {
  final String message;
  const ProductFailure(this.message);
  @override
  List<Object?> get props => [message];
}
