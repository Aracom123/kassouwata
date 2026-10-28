import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/product_repository.dart';

part 'product_event.dart';
part 'product_state.dart';

@injectable
class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final ProductRepository _repository;

  ProductBloc(this._repository) : super(ProductInitial()) {
    on<LoadProducts>(_onLoadProducts);
    on<CreateProduct>(_onCreateProduct);
    on<UpdateProduct>(_onUpdateProduct);
    on<DeleteProduct>(_onDeleteProduct);
  }

  Future<void> _onLoadProducts(LoadProducts event, Emitter<ProductState> emit) async {
    emit(ProductLoading());
    final result = await _repository.getProductsByShop(event.idBoutique);
    result.fold(
      (f) => emit(ProductFailure(f.message)),
      (products) => emit(ProductsLoaded(products)),
    );
  }

  Future<void> _onCreateProduct(CreateProduct event, Emitter<ProductState> emit) async {
    emit(ProductLoading());
    final result = await _repository.createProduct(
      idBoutique: event.idBoutique,
      libelle: event.libelle,
      description: event.description,
      prixUnitaire: event.prixUnitaire,
      quantite: event.quantite,
      nombreTranches: event.nombreTranches,
      idCategorie: event.idCategorie,
      imagePrincipalePath: event.imagePrincipalePath,
      photosPaths: event.photosPaths,
    );
    result.fold(
      (f) => emit(ProductFailure(f.message)),
      (_) => emit(const ProductOperationSuccess('Produit publié avec succès')),
    );
  }

  Future<void> _onUpdateProduct(UpdateProduct event, Emitter<ProductState> emit) async {
    emit(ProductLoading());
    final result = await _repository.updateProduct(
      idProduit: event.idProduit,
      idBoutique: event.idBoutique,
      libelle: event.libelle,
      description: event.description,
      prixUnitaire: event.prixUnitaire,
      quantite: event.quantite,
      statut: event.statut,
      nombreTranches: event.nombreTranches,
      idCategorie: event.idCategorie,
      imagePrincipalePath: event.imagePrincipalePath,
      photosPaths: event.photosPaths,
      existingImagePrincipale: event.existingImagePrincipale,
      existingPhotos: event.existingPhotos,
    );
    result.fold(
      (f) => emit(ProductFailure(f.message)),
      (_) => emit(const ProductOperationSuccess('Produit mis à jour avec succès')),
    );
  }

  Future<void> _onDeleteProduct(DeleteProduct event, Emitter<ProductState> emit) async {
    emit(ProductLoading());
    final result = await _repository.deleteProduct(event.idProduit);
    result.fold(
      (f) => emit(ProductFailure(f.message)),
      (_) => emit(const ProductOperationSuccess('Produit supprimé')),
    );
  }
}
