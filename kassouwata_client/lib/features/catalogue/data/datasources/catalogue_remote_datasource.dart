import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../models/product_model.dart';

abstract class CatalogueRemoteDataSource {
  Future<List<ProductModel>> getProducts();
  Future<ProductModel> getProductById(int id);
  Future<List<CategoryModel>> getCategories();
}

class CatalogueRemoteDataSourceImpl implements CatalogueRemoteDataSource {
  final DioClient _dio;
  CatalogueRemoteDataSourceImpl(this._dio);

  @override
  Future<List<ProductModel>> getProducts() async {
    final response = await _dio.dio.get(ApiEndpoints.produits);
    final List<dynamic> data = response.data as List<dynamic>? ?? [];
    return data
        .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ProductModel> getProductById(int id) async {
    final response = await _dio.dio.get(ApiEndpoints.produitById(id));
    return ProductModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<List<CategoryModel>> getCategories() async {
    final response = await _dio.dio.get(ApiEndpoints.categories);
    final page = response.data as Map<String, dynamic>;
    final List<dynamic> data = page['content'] as List<dynamic>? ?? [];
    return data
        .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
