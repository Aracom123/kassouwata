import 'package:injectable/injectable.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../models/auth_model.dart';

abstract class AuthRemoteDataSource {
  Future<AuthResponseModel> login({
    required String telephone,
    required String password,
  });

  /// Inscription : retourne le numéro de téléphone (l'OTP est envoyé par le backend).
  Future<String> register({
    required String telephone,
    required String password,
    required String nom,
    required String prenom,
  });

  Future<void> sendOtp({required String telephone});
  Future<void> verifyOtp({required String telephone, required String code});
}

@Injectable(as: AuthRemoteDataSource)
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final DioClient _dioClient;
  const AuthRemoteDataSourceImpl(this._dioClient);

  @override
  Future<AuthResponseModel> login({
    required String telephone,
    required String password,
  }) async {
    final response = await _dioClient.dio.post(
      ApiEndpoints.login,
      data: {'login': telephone, 'password': password},
    );
    return AuthResponseModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<String> register({
    required String telephone,
    required String password,
    required String nom,
    required String prenom,
  }) async {
    await _dioClient.dio.post(
      ApiEndpoints.register,
      data: {
        'telephone': telephone,
        'password': password,
        'nom': nom,
        'prenom': prenom,
        'profile': {'idProfile': AppConfig.clientProfileId},
      },
    );
    // L'OTP est envoyé automatiquement par le backend
    return telephone;
  }

  @override
  Future<void> sendOtp({required String telephone}) async {
    await _dioClient.dio.post(
      ApiEndpoints.sendOtp,
      data: {'telephone': telephone},
    );
  }

  @override
  Future<void> verifyOtp({required String telephone, required String code}) async {
    await _dioClient.dio.post(
      ApiEndpoints.verifyOtp,
      data: {'telephone': telephone, 'code': code},
    );
  }
}
