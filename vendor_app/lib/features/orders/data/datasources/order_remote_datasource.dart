import 'package:injectable/injectable.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../models/order_model.dart';

abstract class OrderRemoteDataSource {
  Future<List<OrderModel>> getOrdersByBoutique(int idBoutique);
  Future<OrderModel> getOrderById(int id);
  Future<OrderModel> updateOrderStatut(int id, String statut);
}

@Injectable(as: OrderRemoteDataSource)
class OrderRemoteDataSourceImpl implements OrderRemoteDataSource {
  final DioClient _dioClient;
  const OrderRemoteDataSourceImpl(this._dioClient);

  @override
  Future<List<OrderModel>> getOrdersByBoutique(int idBoutique) async {
    final response = await _dioClient.dio.get(
      ApiEndpoints.commandesByBoutique(idBoutique),
    );
    final list = response.data as List<dynamic>;
    final orders = list
        .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
        .toList();
    // Tri défensif : les plus récentes en premier
    orders.sort((a, b) {
      final da = a.dateCommande;
      final db = b.dateCommande;
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return db.compareTo(da);
    });
    return orders;
  }

  @override
  Future<OrderModel> getOrderById(int id) async {
    final response = await _dioClient.dio.get(ApiEndpoints.commandeById(id));
    return OrderModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<OrderModel> updateOrderStatut(int id, String statut) async {
    final response = await _dioClient.dio.patch(
      ApiEndpoints.updateCommandeStatut(id),
      data: {'statut': statut},
    );
    return OrderModel.fromJson(response.data as Map<String, dynamic>);
  }
}
