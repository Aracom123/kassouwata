import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/product_entity.dart';

abstract class CatalogueRepository {
  Future<Either<Failure, List<ProductEntity>>> getProducts({
    String? search,
    int? categorieId,
  });

  Future<Either<Failure, ProductEntity>> getProductById(int id);

  Future<Either<Failure, List<CategoryEntity>>> getCategories();
}
