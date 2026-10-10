part of 'catalogue_bloc.dart';

enum CatalogueStatus { initial, loading, success, failure }

class CatalogueState extends Equatable {
  final CatalogueStatus status;
  final List<ProductEntity> products;
  final List<CategoryEntity> categories;
  final String search;
  final int? selectedCategorieId;
  final String? errorMessage;

  const CatalogueState({
    this.status = CatalogueStatus.initial,
    this.products = const [],
    this.categories = const [],
    this.search = '',
    this.selectedCategorieId,
    this.errorMessage,
  });

  CatalogueState copyWith({
    CatalogueStatus? status,
    List<ProductEntity>? products,
    List<CategoryEntity>? categories,
    String? search,
    int? selectedCategorieId,
    String? errorMessage,
    bool clearCategory = false,
  }) {
    return CatalogueState(
      status: status ?? this.status,
      products: products ?? this.products,
      categories: categories ?? this.categories,
      search: search ?? this.search,
      selectedCategorieId:
          clearCategory ? null : (selectedCategorieId ?? this.selectedCategorieId),
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [status, products, categories, search, selectedCategorieId, errorMessage];
}
