import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../models/categorie_model.dart';
import '../models/product_model.dart';
import '../models/save_product_model.dart';

abstract class ProductRemoteDataSource {
  Future<String> uploadImage(String filePath);
  Future<List<String>> uploadImages(List<String> filePaths);
  Future<void> deleteFile(String filename);
  Future<List<CategorieModel>> getCategories();
  Future<List<ProductModel>> getProductsByBoutique(int idBoutique);
  Future<void> saveProduct(SaveProductRequestModel request);
  Future<void> updateProduct(int id, SaveProductRequestModel request);
  Future<void> deleteProduct(int id);
}

@Injectable(as: ProductRemoteDataSource)
class ProductRemoteDataSourceImpl implements ProductRemoteDataSource {
  final DioClient _dioClient;
  const ProductRemoteDataSourceImpl(this._dioClient);

  Future<List<int>> _compress(String path) async {
    try {
      final result = await FlutterImageCompress.compressWithFile(
        path,
        quality: 75,
        minWidth: 1024,
        minHeight: 1024,
      );
      if (result != null) return result;
    } catch (_) {}
    return await File(path).readAsBytes();
  }

  @override
  Future<String> uploadImage(String filePath) async {
    final bytes = await _compress(filePath);
    final filename = filePath.split(Platform.pathSeparator).last;
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: filename),
    });
    final response = await _dioClient.dio.post(
      ApiEndpoints.uploadImage,
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
        responseType: ResponseType.plain,
      ),
    );
    return (response.data as String).trim();
  }

  @override
  Future<List<String>> uploadImages(List<String> filePaths) async {
    if (filePaths.isEmpty) return [];
    final files = <MultipartFile>[];
    for (final path in filePaths) {
      final bytes = await _compress(path);
      final filename = path.split(Platform.pathSeparator).last;
      files.add(MultipartFile.fromBytes(bytes, filename: filename));
    }
    final formData = FormData.fromMap({'files': files});
    final response = await _dioClient.dio.post(
      ApiEndpoints.uploadImages,
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
        responseType: ResponseType.json,
      ),
    );
    return List<String>.from(response.data as List);
  }

  @override
  Future<void> deleteFile(String filename) async {
    await _dioClient.dio.delete(ApiEndpoints.deleteFile(filename));
  }

  @override
  Future<List<CategorieModel>> getCategories() async {
    final response = await _dioClient.dio.get(
      ApiEndpoints.categories,
      queryParameters: {'size': 100},
    );
    // Spring Page response: {"content": [...], ...}
    final data = response.data;
    final list = (data is Map ? data['content'] : data) as List;
    return list.map((e) => CategorieModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<ProductModel>> getProductsByBoutique(int idBoutique) async {
    final response = await _dioClient.dio.get(
      ApiEndpoints.produitsByBoutique(idBoutique),
    );
    return (response.data as List)
        .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> saveProduct(SaveProductRequestModel request) async {
    await _dioClient.dio.post(
      ApiEndpoints.saveProduit,
      data: request.toJson(),
    );
  }

  @override
  Future<void> updateProduct(int id, SaveProductRequestModel request) async {
    await _dioClient.dio.put(
      ApiEndpoints.updateProduit(id),
      data: request.toJson(),
    );
  }

  @override
  Future<void> deleteProduct(int id) async {
    await _dioClient.dio.delete(ApiEndpoints.deleteProduit(id));
  }
}
