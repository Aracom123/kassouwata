part of 'complete_profile_bloc.dart';

abstract class CompleteProfileEvent extends Equatable {
  const CompleteProfileEvent();
  @override
  List<Object?> get props => [];
}

/// Mise à jour depuis la page Mon Profil (utilisateur déjà ACTIVE).
class UpdateProfile extends CompleteProfileEvent {
  final String idUser;
  final String nom;
  final String prenom;
  final String? email;
  final String? genre;
  final String? adresse;
  final String? dateNaissance;
  final String? lieuNaissance;

  const UpdateProfile({
    required this.idUser,
    required this.nom,
    required this.prenom,
    this.email,
    this.genre,
    this.adresse,
    this.dateNaissance,
    this.lieuNaissance,
  });

  @override
  List<Object?> get props => [idUser, nom, prenom, email, genre, adresse, dateNaissance, lieuNaissance];
}

class SubmitProfile extends CompleteProfileEvent {
  final String idUser;
  final String nom;
  final String prenom;
  final String? email;
  final String? genre;
  final String? adresse;
  final String? dateNaissance;
  final String? lieuNaissance;

  const SubmitProfile({
    required this.idUser,
    required this.nom,
    required this.prenom,
    this.email,
    this.genre,
    this.adresse,
    this.dateNaissance,
    this.lieuNaissance,
  });

  @override
  List<Object?> get props => [idUser, nom, prenom, email, genre, adresse, dateNaissance, lieuNaissance];
}
