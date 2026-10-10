import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<Either<Failure, UserEntity>> login({
    required String telephone,
    required String password,
  });

  /// Retourne le numéro de téléphone pour la suite du flux OTP.
  Future<Either<Failure, String>> register({
    required String telephone,
    required String password,
    required String nom,
    required String prenom,
  });

  Future<Either<Failure, Unit>> sendOtp({required String telephone});

  Future<Either<Failure, Unit>> verifyOtp({
    required String telephone,
    required String code,
  });

  Future<bool> isLoggedIn();
  Future<void> logout();
}
