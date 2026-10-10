import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../../catalogue/data/models/product_model.dart';
import '../models/boutique_model.dart';

abstract class BoutiqueRemoteDataSource {
  Future<List<BoutiqueModel>> getBoutiques();
  Future<List<ProductModel>> getProductsByBoutique(int id);
}

class BoutiqueRemoteDataSourceImpl implements BoutiqueRemoteDataSource {
  final DioClient _dio;
  BoutiqueRemoteDataSourceImpl(this._dio);

  @override
  Future<List<BoutiqueModel>> getBoutiques() async {
    final response = await _dio.dio.get(ApiEndpoints.boutiques);
    final page = response.data as Map<String, dynamic>;
    final List<dynamic> data = page['content'] as List<dynamic>? ?? [];
    return data
        .map((e) => BoutiqueModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<ProductModel>> getProductsByBoutique(int id) async {
    final response =
        await _dio.dio.get(ApiEndpoints.produitsByBoutique(id));
    final List<dynamic> data = response.data as List<dynamic>? ?? [];
    return data
        .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
