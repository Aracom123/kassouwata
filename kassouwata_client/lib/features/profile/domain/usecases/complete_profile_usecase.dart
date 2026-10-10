import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../repositories/profile_repository.dart';

@injectable
class CompleteProfileUseCase {
  final ProfileRepository _repository;
  const CompleteProfileUseCase(this._repository);

  Future<Either<Failure, Unit>> call({
    required String idUser,
    required String nom,
    required String prenom,
    String? email,
    String? genre,
    String? adresse,
    String? dateNaissance,
    String? lieuNaissance,
  }) =>
      _repository.completeProfile(
        idUser: idUser,
        nom: nom,
        prenom: prenom,
        email: email,
        genre: genre,
        adresse: adresse,
        dateNaissance: dateNaissance,
        lieuNaissance: lieuNaissance,
      );
}
