import 'package:injectable/injectable.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../../auth/data/models/update_user_model.dart';
import '../../../shop/data/models/create_boutique_model.dart';
import '../../../shop/data/models/shop_model.dart';
import '../../../shop/data/models/update_boutique_model.dart';

abstract class OnboardingDataSource {
  Future<void> updateUser({
    required String idUser,
    required UpdateUserRequestModel request,
  });
  Future<ShopModel> createBoutique(CreateBoutiqueRequestModel request);
  Future<void> updateBoutique({
    required int idBoutique,
    required UpdateBoutiqueRequestModel request,
  });
}

@Injectable(as: OnboardingDataSource)
class OnboardingDataSourceImpl implements OnboardingDataSource {
  final DioClient _dioClient;
  const OnboardingDataSourceImpl(this._dioClient);

  @override
  Future<void> updateUser({
    required String idUser,
    required UpdateUserRequestModel request,
  }) async {
    await _dioClient.dio.put(
      ApiEndpoints.updateUser(idUser),
      data: request.toJson(),
    );
  }

  @override
  Future<ShopModel> createBoutique(CreateBoutiqueRequestModel request) async {
    final response = await _dioClient.dio.post(
      ApiEndpoints.saveBoutique,
      data: request.toJson(),
    );
    return ShopModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> updateBoutique({
    required int idBoutique,
    required UpdateBoutiqueRequestModel request,
  }) async {
    await _dioClient.dio.put(
      ApiEndpoints.updateBoutique(idBoutique.toString()),
      data: request.toJson(),
    );
  }
}