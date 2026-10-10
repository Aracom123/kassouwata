import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../auth/data/models/auth_model.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_datasource.dart';

@Injectable(as: ProfileRepository)
class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource _remote;
  final SecureStorage _storage;

  const ProfileRepositoryImpl(this._remote, this._storage);

  @override
  Future<Either<Failure, Unit>> completeProfile({
    required String idUser,
    required String nom,
    required String prenom,
    String? email,
    String? genre,
    String? adresse,
    String? dateNaissance,
    String? lieuNaissance,
  }) async {
    try {
      await _remote.completeProfile(
        idUser: idUser,
        nom: nom,
        prenom: prenom,
        email: email,
        genre: genre,
        adresse: adresse,
        dateNaissance: dateNaissance,
        lieuNaissance: lieuNaissance,
      );
      return const Right(unit);
    } catch (e) {
      if (e is DioException) {
        final data = e.response?.data;
        String? msg;
        if (data is Map) {
          msg = data['error'] as String? ?? data['message'] as String?;
        }
        return Left(ServerFailure(
          msg ?? 'Erreur lors de la mise à jour du profil',
          statusCode: e.response?.statusCode ?? 0,
        ));
      }
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> refreshSession() async {
    try {
      final data = await _remote.refreshToken();
      final model = AuthResponseModel.fromJson(data);
      final user = model.toEntity();

      // Persister le nouveau token et le statut mis à jour
      await _storage.saveToken(user.token);
      await _storage.saveUserId(user.idUser);
      await _storage.saveProfile(user.profile);
      await _storage.saveTelephone(user.telephone);
      await _storage.saveStatus(user.status);
      if (model.expiresIn != null) {
        await _storage.saveExpiresIn(model.expiresIn!);
      }

      return Right(user);
    } catch (e) {
      if (e is DioException) {
        final data = e.response?.data;
        String? msg;
        if (data is Map) {
          msg = data['error'] as String? ?? data['message'] as String?;
        }
        return Left(ServerFailure(
          msg ?? 'Impossible de rafraîchir la session',
          statusCode: e.response?.statusCode ?? 0,
        ));
      }
      return Left(ServerFailure(e.toString()));
    }
  }
}
