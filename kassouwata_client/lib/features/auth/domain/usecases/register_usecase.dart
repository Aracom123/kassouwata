import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../repositories/auth_repository.dart';

@injectable
class RegisterUseCase {
  final AuthRepository _repository;
  const RegisterUseCase(this._repository);

  Future<Either<Failure, String>> call({
    required String telephone,
    required String password,
    required String nom,
    required String prenom,
  }) =>
      _repository.register(telephone: telephone, password: password, nom: nom, prenom: prenom);
}
