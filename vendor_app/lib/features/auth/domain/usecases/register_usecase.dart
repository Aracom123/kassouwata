import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

@injectable
class RegisterUseCase {
  final AuthRepository _repository;
  const RegisterUseCase(this._repository);

  Future<Either<Failure, String>> call(RegisterParams params) =>
      _repository.register(
        telephone: params.telephone,
        password: params.password,
        nom: params.nom,
        prenom: params.prenom,
      );
}

class RegisterParams extends Equatable {
  final String telephone;
  final String password;
  final String? nom;
  final String? prenom;

  const RegisterParams({
    required this.telephone,
    required this.password,
    this.nom,
    this.prenom,
  });

  @override
  List<Object?> get props => [telephone, password, nom, prenom];
}