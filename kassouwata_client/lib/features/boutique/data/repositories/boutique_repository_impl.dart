import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../core/error/failures.dart';
import '../../../catalogue/domain/entities/product_entity.dart';
import '../../domain/entities/boutique_entity.dart';
import '../../domain/repositories/boutique_repository.dart';
import '../datasources/boutique_remote_datasource.dart';

class BoutiqueRepositoryImpl implements BoutiqueRepository {
  final BoutiqueRemoteDataSource _remote;
  BoutiqueRepositoryImpl(this._remote);

  @override
  Future<Either<Failure, List<BoutiqueEntity>>> getBoutiques() async {
    try {
      final boutiques = await _remote.getBoutiques();
      return Right(boutiques);
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Erreur réseau'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ProductEntity>>> getProductsByBoutique(
      int id) async {
    try {
      final products = await _remote.getProductsByBoutique(id);
      return Right(products);
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Erreur réseau'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
