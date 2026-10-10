part of 'complete_profile_bloc.dart';

abstract class CompleteProfileState extends Equatable {
  const CompleteProfileState();
  @override
  List<Object?> get props => [];
}

class CompleteProfileInitial extends CompleteProfileState {}

class CompleteProfileLoading extends CompleteProfileState {}

/// Profil soumis avec succès ET session rafraîchie — l'utilisateur peut
/// être redirigé directement vers /home sans repasser par /login.
class CompleteProfileSuccess extends CompleteProfileState {
  final UserEntity user;
  const CompleteProfileSuccess(this.user);
  @override
  List<Object?> get props => [user];
}

/// Le profil a été soumis mais le refresh de session a échoué.
/// On redirige quand même vers /login pour une reconnexion manuelle.
class CompleteProfileSuccessNoRefresh extends CompleteProfileState {}

/// Mise à jour du profil depuis la page Mon Profil (pas la première complétion KYC).
/// La session est déjà active — on reste sur la page profil et on rafraîchit l'AuthBloc.
class UpdateProfileSuccess extends CompleteProfileState {
  final UserEntity user;
  const UpdateProfileSuccess(this.user);
  @override
  List<Object?> get props => [user];
}

class CompleteProfileFailure extends CompleteProfileState {
  final String message;
  const CompleteProfileFailure(this.message);
  @override
  List<Object?> get props => [message];
}
