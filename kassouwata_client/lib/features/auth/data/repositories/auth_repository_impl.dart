import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../../vendeur/vendeur_session.dart';
import '../datasources/auth_remote_datasource.dart';

@Injectable(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remote;
  final SecureStorage _storage;
  final VendeurSession _vendeur;

  const AuthRepositoryImpl(this._remote, this._storage, this._vendeur);

  Failure _handleError(Object e) {
    if (e is DioException) {
      if (e.response == null) {
        return NetworkFailure(e.message ?? 'Erreur réseau');
      }

      final statusCode = e.response!.statusCode ?? 0;
      final data = e.response!.data;

      // Extraire le message d'erreur depuis le corps JSON {"error": "..."}
      String? serverMessage;
      if (data is Map) {
        serverMessage = data['error'] as String? ?? data['message'] as String?;
      } else if (data is String && data.isNotEmpty) {
        serverMessage = data;
      }

      // 401 → identifiants incorrects
      if (statusCode == 401) {
        return const ServerFailure(
          'Numéro de téléphone ou mot de passe incorrect.',
          statusCode: 401,
        );
      }

      // 403 → compte non vérifié (OTP en attente)
      if (statusCode == 403) {
        return ServerFailure(
          serverMessage ??
              'Numéro de téléphone non vérifié. Veuillez valider votre code OTP.',
          statusCode: 403,
        );
      }

      // 409 → conflit (doublon téléphone ou email)
      if (statusCode == 409) {
        return ServerFailure(
          _localizeConflict(serverMessage),
          statusCode: 409,
        );
      }

      return ServerFailure(
        serverMessage ?? 'Erreur serveur ($statusCode)',
        statusCode: statusCode,
      );
    }
    return ServerFailure(e.toString());
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

  @override
  Future<Either<Failure, UserEntity>> login({
    required String telephone,
    required String password,
  }) async {
    try {
      final model = await _remote.login(telephone: telephone, password: password);
      final user = model.toEntity();
      await _storage.saveToken(user.token);
      await _storage.saveUserId(user.idUser);
      await _storage.saveProfile(user.profile);
      await _storage.saveTelephone(user.telephone);
      await _storage.saveStatus(user.status);
      if (user.prenom != null) await _storage.savePrenom(user.prenom!);
      if (user.nom != null) await _storage.saveNom(user.nom!);
      if (model.expiresIn != null) {
        await _storage.saveExpiresIn(model.expiresIn!);
      }
      // Espace vendeur : cache de l'utilisateur et de sa boutique
      await _vendeur.enregistrerConnexion(
        idUser: user.idUser,
        telephone: user.telephone,
        profile: user.profile,
        status: user.status,
        nom: user.nom,
        prenom: user.prenom,
        email: user.email,
        boutique: model.boutique,
      );
      return Right(user);
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  @override
  Future<Either<Failure, String>> register({
    required String telephone,
    required String password,
    required String nom,
    required String prenom,
    bool vendeur = false,
  }) async {
    try {
      final tel = await _remote.register(
          telephone: telephone,
          password: password,
          nom: nom,
          prenom: prenom,
          profileId: vendeur
              ? AppConfig.vendeurProfileId
              : AppConfig.clientProfileId);
      return Right(tel);
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> sendOtp({required String telephone}) async {
    try {
      await _remote.sendOtp(telephone: telephone);
      return const Right(unit);
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> verifyOtp({
    required String telephone,
    required String code,
  }) async {
    try {
      await _remote.verifyOtp(telephone: telephone, code: code);
      return const Right(unit);
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  @override
  Future<bool> isLoggedIn() async {
    final token = await _storage.getToken();
    return token != null && token.isNotEmpty;
  }

  @override
  Future<void> logout() async {
    await _storage.clearAll();
    await _vendeur.effacer();
  }
}
