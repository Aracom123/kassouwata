import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/catalogue_repository.dart';
import '../datasources/catalogue_remote_datasource.dart';

class CatalogueRepositoryImpl implements CatalogueRepository {
  final CatalogueRemoteDataSource _remote;
  CatalogueRepositoryImpl(this._remote);

  @override
  Future<Either<Failure, List<ProductEntity>>> getProducts({
    String? search,
    int? categorieId,
  }) async {
    try {
      var products = await _remote.getProducts();

      // Tri décroissant par date de publication (plus récents en premier).
      // Le paramètre sort=createdDate,desc est déjà envoyé à l'API ;
      // ce tri côté client sert de filet de sécurité.
      products.sort((a, b) {
        if (a.createdDate == null && b.createdDate == null) return 0;
        if (a.createdDate == null) return 1;
        if (b.createdDate == null) return -1;
        return b.createdDate!.compareTo(a.createdDate!);
      });

      if (search != null && search.isNotEmpty) {
        final q = search.toLowerCase();
        products = products
            .where((p) =>
                p.libelle.toLowerCase().contains(q) ||
                (p.description?.toLowerCase().contains(q) ?? false))
            .toList();
      }
      if (categorieId != null) {
        products = products
            .where((p) => p.categorie?.idCategorie == categorieId)
            .toList();
      }
      return Right(products);
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Erreur réseau'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ProductEntity>> getProductById(int id) async {
    try {
      final product = await _remote.getProductById(id);
      return Right(product);
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Erreur réseau'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<CategoryEntity>>> getCategories() async {
    try {
      final categories = await _remote.getCategories();
      return Right(categories);
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Erreur réseau'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
