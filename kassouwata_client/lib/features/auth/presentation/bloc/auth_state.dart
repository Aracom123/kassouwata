part of 'auth_bloc.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final UserEntity user;
  const Authenticated(this.user);
  @override
  List<Object?> get props => [user];
}

/// L'inscription a réussi — l'utilisateur doit saisir son OTP.
class OtpRequired extends AuthState {
  final String telephone;
  const OtpRequired(this.telephone);
  @override
  List<Object?> get props => [telephone];
}

/// L'OTP a été vérifié avec succès.
class OtpVerified extends AuthState {
  final String telephone;
  const OtpVerified(this.telephone);
  @override
  List<Object?> get props => [telephone];
}

/// L'utilisateur est authentifié mais son profil est incomplet (KYC_PENDING).
/// Il doit être redirigé vers la page de complétion du profil.
class KycPending extends AuthState {
  final String idUser;
  final String token;
  final String? prenom;
  final String? nom;
  const KycPending({required this.idUser, required this.token, this.prenom, this.nom});
  @override
  List<Object?> get props => [idUser, token, prenom, nom];
}

class Unauthenticated extends AuthState {}

class AuthFailure extends AuthState {
  final String message;
  const AuthFailure(this.message);
  @override
  List<Object?> get props => [message];
}
