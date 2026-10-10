import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

class ServerFailure extends Failure {
  final int? statusCode;
  const ServerFailure(super.message, {this.statusCode});
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Pas de connexion internet']);
}

class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([super.message = 'Session expirée, veuillez vous reconnecter']);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}
