import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../catalogue/domain/entities/product_entity.dart';
import '../entities/boutique_entity.dart';

abstract class BoutiqueRepository {
  Future<Either<Failure, List<BoutiqueEntity>>> getBoutiques();
  Future<Either<Failure, List<ProductEntity>>> getProductsByBoutique(int id);
}
