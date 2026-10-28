import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/repositories/order_repository.dart';
import '../datasources/order_remote_datasource.dart';

@Injectable(as: OrderRepository)
class OrderRepositoryImpl implements OrderRepository {
  final OrderRemoteDataSource _remoteDataSource;
  const OrderRepositoryImpl(this._remoteDataSource);

  Failure _handleError(Object e) {
    if (e is DioException) {
      if (e.response != null) {
        final msg = e.response?.data?.toString() ?? 'Erreur serveur';
        return ServerFailure(msg, statusCode: e.response?.statusCode);
      }
      return NetworkFailure(e.message ?? 'Erreur réseau');
    }
    return ServerFailure(e.toString());
  }

  @override
  Future<Either<Failure, List<OrderEntity>>> getOrdersByShop(int idBoutique) async {
    try {
      final models = await _remoteDataSource.getOrdersByBoutique(idBoutique);
      return Right(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  @override
  Future<Either<Failure, OrderEntity>> getOrderById(int id) async {
    try {
      final model = await _remoteDataSource.getOrderById(id);
      return Right(model.toEntity());
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  @override
  Future<Either<Failure, OrderEntity>> updateOrderStatut(int id, String statut) async {
    try {
      final model = await _remoteDataSource.updateOrderStatut(id, statut);
      return Right(model.toEntity());
    } catch (e) {
      return Left(_handleError(e));
    }
  }
}
