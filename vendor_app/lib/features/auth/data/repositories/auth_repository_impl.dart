import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../shared/enums/user_status.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';
import '../../../shop/data/models/shop_model.dart';
import '../models/personne_model.dart';
import '../models/profile_model.dart';
import '../models/token_model.dart';
import '../models/user_model.dart';

@Injectable(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;
  final SecureStorage _secureStorage;

  const AuthRepositoryImpl(
    this._remoteDataSource,
    this._localDataSource,
    this._secureStorage,
  );

  @override
  Future<Either<Failure, UserEntity>> login({
    required String telephone,
    required String password,
  }) async {
    try {
      final tokenModel = await _remoteDataSource.login(
        telephone: telephone,
        password: password,
      );
      await _secureStorage.saveAccessToken(tokenModel.token);
      final expiry = _jwtExpiry(tokenModel.token);
      if (expiry != null) {
        await _secureStorage.saveExpiresIn(expiry.millisecondsSinceEpoch);
      }

      final user = _buildUserModel(tokenModel, telephone);
      await _localDataSource.cacheUser(user);
      _cacheBoutiqueIfPresent(tokenModel);
      return Right(user.toEntity());
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      // Capture tout TypeError / FormatException survenant dans _buildUserModel
      // ou lors du parsing du TokenModel après un login HTTP 200
      return Left(ServerFailure('Erreur de traitement de la réponse : $e'));
    }
  }

  @override
  Future<Either<Failure, String>> register({
    required String telephone,
    required String password,
    String? nom,
    String? prenom,
  }) async {
    try {
      final tel = await _remoteDataSource.register(
        telephone: telephone,
        password: password,
        prenom: prenom,
      );
      return Right(tel);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Unit>> sendOtp({required String telephone}) async {
    try {
      await _remoteDataSource.sendOtp(telephone: telephone);
      return const Right(unit);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Unit>> verifyOtp({
    required String telephone,
    required String code,
  }) async {
    try {
      await _remoteDataSource.verifyOtp(telephone: telephone, code: code);
      return const Right(unit);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Unit>> logout() async {
    await _secureStorage.clearAll();
    await _localDataSource.clearUser();
    await _localDataSource.clearBoutique();
    return const Right(unit);
  }

  void _cacheBoutiqueIfPresent(TokenModel tokenModel) {
    try {
      final boutiqueMap = tokenModel.boutique;
      if (boutiqueMap != null) {
        final boutique = ShopModel.fromJson(boutiqueMap);
        _localDataSource.cacheBoutique(boutique);
      }
    } catch (_) {}
  }

  @override
  Future<Either<Failure, UserEntity>> getCurrentUser() async {
    try {
      final cached = await _localDataSource.getCachedUser();
      if (cached != null) return Right(cached.toEntity());
      return const Left(UnauthorizedFailure());
    } on UnauthorizedException {
      return const Left(UnauthorizedFailure());
    }
  }

  DateTime? _jwtExpiry(String token) {
    try {
      final payload = token.split('.')[1];
      final decoded = utf8.decode(base64Url.decode(base64Url.normalize(payload)));
      final exp = (jsonDecode(decoded) as Map<String, dynamic>)['exp'] as int?;
      if (exp == null) return null;
      return DateTime.fromMillisecondsSinceEpoch(exp * 1000);
    } catch (_) {
      return null;
    }
  }

  UserModel _buildUserModel(
    TokenModel tokenModel,
    String telephone, {
    String defaultStatus = 'ACTIVE',
    String? nom,
    String? prenom,
  }) {
    // Extraire personne et profile depuis boutique.vendeur (réponse complète du backend)
    PersonneModel? personne;
    ProfileModel? profile;
    try {
      final vendeur =
          tokenModel.boutique?['vendeur'] as Map<String, dynamic>?;
      if (vendeur != null) {
        final personneMap = vendeur['personne'] as Map<String, dynamic>?;
        if (personneMap != null) personne = PersonneModel.fromJson(personneMap);
        final profileMap = vendeur['profile'] as Map<String, dynamic>?;
        if (profileMap != null) profile = ProfileModel.fromJson(profileMap);
      }
    } catch (_) {}

    // Fallback avec les champs de premier niveau du token
    personne ??= (tokenModel.nom != null ||
            tokenModel.prenom != null ||
            nom != null ||
            prenom != null)
        ? PersonneModel(
            idPersonne: '',
            nom: tokenModel.nom ?? nom ?? '',
            prenom: tokenModel.prenom ?? prenom ?? '',
            email: tokenModel.email,
          )
        : null;

    return UserModel(
      idUser: tokenModel.idUser ?? '',
      telephone: tokenModel.login ?? telephone,
      status: UserStatus.fromJson(tokenModel.status ?? defaultStatus),
      personne: personne,
      profile: profile,
    );
  }
}