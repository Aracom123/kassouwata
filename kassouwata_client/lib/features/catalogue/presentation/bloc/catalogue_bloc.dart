import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/product_entity.dart';
import '../../domain/usecases/get_products_usecase.dart';

part 'catalogue_event.dart';
part 'catalogue_state.dart';

class CatalogueBloc extends Bloc<CatalogueEvent, CatalogueState> {
  final GetProductsUseCase _getProducts;
  final GetCategoriesUseCase _getCategories;

  CatalogueBloc(this._getProducts, this._getCategories)
      : super(const CatalogueState()) {
    on<LoadCatalogue>(_onLoad);
    on<SearchCatalogue>(_onSearch);
    on<FilterByCategory>(_onFilterByCategory);
  }

  Future<void> _onLoad(
      LoadCatalogue event, Emitter<CatalogueState> emit) async {
    emit(state.copyWith(status: CatalogueStatus.loading));

    final catResult = await _getCategories();
    catResult.fold((_) {}, (cats) => emit(state.copyWith(categories: cats)));

    final result = await _getProducts(
      search: state.search,
      categorieId: state.selectedCategorieId,
    );
    result.fold(
      (failure) => emit(state.copyWith(
          status: CatalogueStatus.failure, errorMessage: failure.message)),
      (products) =>
          emit(state.copyWith(status: CatalogueStatus.success, products: products)),
    );
  }

  Future<void> _onSearch(
      SearchCatalogue event, Emitter<CatalogueState> emit) async {
    emit(state.copyWith(search: event.query, status: CatalogueStatus.loading));
    final result = await _getProducts(
      search: event.query,
      categorieId: state.selectedCategorieId,
    );
    result.fold(
      (failure) => emit(state.copyWith(
          status: CatalogueStatus.failure, errorMessage: failure.message)),
      (products) =>
          emit(state.copyWith(status: CatalogueStatus.success, products: products)),
    );
  }

  Future<void> _onFilterByCategory(
      FilterByCategory event, Emitter<CatalogueState> emit) async {
    emit(state.copyWith(
        selectedCategorieId: event.categorieId,
        status: CatalogueStatus.loading));
    final result = await _getProducts(
      search: state.search,
      categorieId: event.categorieId,
    );
    result.fold(
      (failure) => emit(state.copyWith(
          status: CatalogueStatus.failure, errorMessage: failure.message)),
      (products) =>
          emit(state.copyWith(status: CatalogueStatus.success, products: products)),
    );
  }
}
