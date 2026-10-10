import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../models/order_model.dart';

abstract class OrderRemoteDataSource {
  Future<List<OrderModel>> getMyOrders(String userId);
  /// Crée la commande (avec ses lignes incluses dans [body]).
  /// Retourne la liste des commandes créées (1 pour POSTPAYE, N pour PREPAYE).
  Future<List<OrderModel>> saveCommande(Map<String, dynamic> body);
  Future<void> saveProduitCommande(Map<String, dynamic> body);
  Future<OrderModel> cancelCommande(int id);
  Future<List<VersementModel>> getVersements(int commandeId);
  Future<VersementModel> saveVersement(Map<String, dynamic> body);
}

class OrderRemoteDataSourceImpl implements OrderRemoteDataSource {
  final DioClient _dio;
  OrderRemoteDataSourceImpl(this._dio);

  @override
  Future<List<OrderModel>> getMyOrders(String userId) async {
    final response = await _dio.dio.get(ApiEndpoints.commandesByClient(userId));
    final List<dynamic> data = response.data as List<dynamic>? ?? [];
    final orders = data
        .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
        .toList();
    // Tri défensif : les plus récentes en premier
    orders.sort((a, b) => b.dateCommande.compareTo(a.dateCommande));
    return orders;
  }

  @override
  Future<List<OrderModel>> saveCommande(Map<String, dynamic> body) async {
    final response =
        await _dio.dio.post(ApiEndpoints.saveCommande, data: body);
    // Le backend retourne toujours une List<Commande> (1 pour POSTPAYE, N pour PREPAYE)
    final List<dynamic> data = response.data as List<dynamic>;
    return data
        .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> saveProduitCommande(Map<String, dynamic> body) async {
    await _dio.dio.post(ApiEndpoints.saveProduitCommande, data: body);
  }

  @override
  Future<OrderModel> cancelCommande(int id) async {
    final response = await _dio.dio.patch(ApiEndpoints.cancelCommande(id));
    return OrderModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<List<VersementModel>> getVersements(int commandeId) async {
    final response =
        await _dio.dio.get(ApiEndpoints.versementsByCommande(commandeId));
    final List<dynamic> data = response.data as List<dynamic>? ?? [];
    return data
        .map((e) => VersementModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<VersementModel> saveVersement(Map<String, dynamic> body) async {
    final response =
        await _dio.dio.post(ApiEndpoints.saveVersementCommande, data: body);
    return VersementModel.fromJson(response.data as Map<String, dynamic>);
  }
}
