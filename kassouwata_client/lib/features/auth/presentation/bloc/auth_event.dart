part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class CheckAuthStatus extends AuthEvent {
  const CheckAuthStatus();
}

class LoginRequested extends AuthEvent {
  final String telephone;
  final String password;
  const LoginRequested({required this.telephone, required this.password});
  @override
  List<Object?> get props => [telephone];
}

class RegisterRequested extends AuthEvent {
  final String telephone;
  final String password;
  final String nom;
  final String prenom;
  /// true : inscription en tant que vendeur (profil VENDEUR)
  final bool vendeur;
  const RegisterRequested({
    required this.telephone,
    required this.password,
    required this.nom,
    required this.prenom,
    this.vendeur = false,
  });
  @override
  List<Object?> get props => [telephone];
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

/// Met à jour l'état Authenticated avec un UserEntity déjà construit
/// (évite de relire le SecureStorage qui ne contient pas tous les champs).
class UserUpdated extends AuthEvent {
  final UserEntity user;
  const UserUpdated(this.user);
  @override
  List<Object?> get props => [user];
}
