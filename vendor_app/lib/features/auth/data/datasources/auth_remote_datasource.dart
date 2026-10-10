import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../models/token_model.dart';
import '../models/update_user_model.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<TokenModel> login({required String telephone, required String password});
  /// Inscription : crée l'utilisateur et déclenche l'envoi d'OTP.
  /// Retourne le numéro de téléphone confirmé par le serveur.
  Future<String> register({
    required String telephone,
    required String password,
    String? prenom,
    int profileId,
  });
  Future<void> sendOtp({required String telephone});
  Future<void> verifyOtp({required String telephone, required String code});
  Future<void> updateUser({
    required String idUser,
    required UpdateUserRequestModel request,
  });
  Future<void> logout();
  Future<UserModel> getCurrentUser();
}

@Injectable(as: AuthRemoteDataSource)
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final DioClient _dioClient;
  const AuthRemoteDataSourceImpl(this._dioClient);

  @override
  Future<TokenModel> login({required String telephone, required String password}) async {
    try {
      final response = await _dioClient.dio.post(
        ApiEndpoints.login,
        data: {'login': telephone, 'password': password},
      );
      return TokenModel.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<String> register({
    required String telephone,
    required String password,
    String? prenom,
    int profileId = 2,
  }) async {
    try {
      await _dioClient.dio.post(
        ApiEndpoints.register,
        data: {
          'telephone': telephone,
          'password': password,
          if (prenom != null) 'prenom': prenom,
          'profile': {'idProfile': profileId},
        },
      );
      // Le serveur a créé le compte et envoyé l'OTP — on retourne le numéro
      return telephone;
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<void> sendOtp({required String telephone}) async {
    try {
      await _dioClient.dio.post(
        ApiEndpoints.sendOtp,
        data: {'telephone': telephone},
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<void> verifyOtp({required String telephone, required String code}) async {
    try {
      await _dioClient.dio.post(
        ApiEndpoints.verifyOtp,
        data: {'telephone': telephone, 'code': code},
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<void> updateUser({
    required String idUser,
    required UpdateUserRequestModel request,
  }) async {
    try {
      await _dioClient.dio.put(
        ApiEndpoints.updateUser(idUser),
        data: request.toJson(),
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<void> logout() async {}

  @override
  Future<UserModel> getCurrentUser() async {
    try {
      final response = await _dioClient.dio.get(ApiEndpoints.me);
      return UserModel.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(dynamic e) {
    if (e is DioException) {
      // Pas de connexion réseau
      if (e.response == null) {
        return const NetworkException();
      }

      final statusCode = e.response?.statusCode ?? 0;
      final data = e.response?.data;

      // Extraire le message d'erreur depuis le corps JSON {"error": "..."}
      String? serverMessage;
      if (data is Map) {
        serverMessage = data['error'] as String? ?? data['message'] as String?;
      } else if (data is String && data.isNotEmpty) {
        serverMessage = data;
      }

      // 401 → identifiants incorrects
      if (statusCode == 401) {
        return const UnauthorizedException(
          message: 'Numéro de téléphone ou mot de passe incorrect.',
        );
      }

      // 403 → compte non vérifié (OTP en attente)
      if (statusCode == 403) {
        return ServerException(
          message: serverMessage ??
              'Numéro de téléphone non vérifié. Veuillez valider votre code OTP.',
          statusCode: 403,
        );
      }

      // 409 → conflit (doublon téléphone ou email)
      if (statusCode == 409) {
        final msg = _localizeConflict(serverMessage);
        return ServerException(message: msg, statusCode: 409);
      }

      // Autres erreurs : afficher le message serveur s'il existe
      return ServerException(
        message: serverMessage ?? 'Erreur serveur ($statusCode)',
        statusCode: statusCode,
      );
    }

    if (e is Exception) {
      final message = e.toString();
      if (message.contains('SocketException') ||
          message.contains('Connection refused')) {
        return const NetworkException();
      }
      // FormatException ou TypeError lors du parsing JSON
      if (message.contains('FormatException') ||
          message.contains('type ') ||
          message.contains('is not a subtype')) {
        return ServerException(
          message: 'Réponse du serveur invalide. Veuillez réessayer.',
        );
      }
      return ServerException(message: message);
    }

    // Capture les Error Dart (TypeError, NoSuchMethodError…) avec détail
    if (e is Error) {
      final detail = e.toString();
      return ServerException(
        message: 'Erreur inattendue : $detail',
      );
    }

    return ServerException(message: 'Une erreur inattendue est survenue');
  }

  /// Traduit les messages de conflit bruts en messages lisibles.
  String _localizeConflict(String? raw) {
    if (raw == null) return 'Cette information est déjà utilisée.';
    final lower = raw.toLowerCase();
    if (lower.contains('téléphone') ||
        lower.contains('telephone') ||
        lower.contains('numéro') ||
        lower.contains('numero')) {
      return 'Ce numéro de téléphone est déjà associé à un compte.';
    }
    if (lower.contains('email') || lower.contains('mail')) {
      return 'Cette adresse e-mail est déjà associée à un compte.';
    }
    return raw;
  }
}