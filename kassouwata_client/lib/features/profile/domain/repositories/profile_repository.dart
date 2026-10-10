import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../auth/domain/entities/user_entity.dart';

abstract class ProfileRepository {
  Future<Either<Failure, Unit>> completeProfile({
    required String idUser,
    required String nom,
    required String prenom,
    String? email,
    String? genre,
    String? adresse,
    String? dateNaissance,
    String? lieuNaissance,
  });

  /// Rafraîchit le token JWT et retourne un UserEntity avec le statut à jour.
  Future<Either<Failure, UserEntity>> refreshSession();
}
