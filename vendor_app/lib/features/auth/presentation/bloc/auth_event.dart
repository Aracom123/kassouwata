part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AppStarted extends AuthEvent {
  const AppStarted();
}

class LoginRequested extends AuthEvent {
  final String telephone;
  final String password;
  const LoginRequested({required this.telephone, required this.password});

  @override
  List<Object?> get props => [telephone, password];
}

class RegisterRequested extends AuthEvent {
  final String telephone;
  final String password;
  final String? nom;
  final String? prenom;

  const RegisterRequested({
    required this.telephone,
    required this.password,
    this.nom,
    this.prenom,
  });

  @override
  List<Object?> get props => [telephone, password, nom, prenom];
}

class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}

class OtpVerifyRequested extends AuthEvent {
  final String telephone;
  final String code;
  const OtpVerifyRequested({required this.telephone, required this.code});

  @override
  List<Object?> get props => [telephone, code];
}

class ResendOtpRequested extends AuthEvent {
  final String telephone;
  const ResendOtpRequested({required this.telephone});

  @override
  List<Object?> get props => [telephone];
}