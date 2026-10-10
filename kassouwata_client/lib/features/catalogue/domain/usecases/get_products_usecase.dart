import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/product_entity.dart';
import '../repositories/catalogue_repository.dart';

class GetProductsUseCase {
  final CatalogueRepository repository;
  GetProductsUseCase(this.repository);

  Future<Either<Failure, List<ProductEntity>>> call({
    String? search,
    int? categorieId,
  }) =>
      repository.getProducts(search: search, categorieId: categorieId);
}

class GetProductByIdUseCase {
  final CatalogueRepository repository;
  GetProductByIdUseCase(this.repository);

  Future<Either<Failure, ProductEntity>> call(int id) =>
      repository.getProductById(id);
}

class GetCategoriesUseCase {
  final CatalogueRepository repository;
  GetCategoriesUseCase(this.repository);

  Future<Either<Failure, List<CategoryEntity>>> call() =>
      repository.getCategories();
}
