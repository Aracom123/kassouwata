import 'package:injectable/injectable.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../models/create_boutique_model.dart';
import '../models/shop_model.dart';

abstract class ShopRemoteDataSource {
  Future<ShopModel> createBoutique(CreateBoutiqueRequestModel request);
  Future<ShopModel> getBoutiqueByVendeur(String idUser);
}

@Injectable(as: ShopRemoteDataSource)
class ShopRemoteDataSourceImpl implements ShopRemoteDataSource {
  final DioClient _dioClient;
  const ShopRemoteDataSourceImpl(this._dioClient);

  @override
  Future<ShopModel> createBoutique(CreateBoutiqueRequestModel request) async {
    try {
      final response = await _dioClient.dio.post(
        ApiEndpoints.saveBoutique,
        data: request.toJson(),
      );
      return ShopModel.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<ShopModel> getBoutiqueByVendeur(String idUser) async {
    try {
      final response = await _dioClient.dio.get(
        ApiEndpoints.boutiqueByVendeur(idUser),
      );
      return ShopModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(dynamic e) {
    if (e is Exception) {
      final message = e.toString();
      if (message.contains('401')) return const UnauthorizedException();
      if (message.contains('SocketException') || message.contains('Connection refused')) {
        return const NetworkException();
      }
      return ServerException(message: message);
    }
    return const ServerException(message: 'Erreur inattendue');
  }
}