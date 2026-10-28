part of 'onboarding_bloc.dart';

abstract class OnboardingEvent extends Equatable {
  const OnboardingEvent();
  @override
  List<Object?> get props => [];
}

class CompleteProfileRequested extends OnboardingEvent {
  final String idUser;
  final String nom;
  final String prenom;
  final String genre;
  final String adresse;
  final String lieuNaissance;
  final DateTime? dateNaissance;
  final String? email;

  const CompleteProfileRequested({
    required this.idUser,
    required this.nom,
    required this.prenom,
    required this.genre,
    required this.adresse,
    required this.lieuNaissance,
    this.dateNaissance,
    this.email,
  });

  @override
  List<Object?> get props =>
      [idUser, nom, prenom, genre, adresse, lieuNaissance, dateNaissance, email];
}

class EditProfileRequested extends OnboardingEvent {
  final String idUser;
  final String currentStatus;
  final String nom;
  final String prenom;
  final String? genre;
  final String? adresse;
  final String? lieuNaissance;
  final DateTime? dateNaissance;
  final String? email;

  const EditProfileRequested({
    required this.idUser,
    required this.currentStatus,
    required this.nom,
    required this.prenom,
    this.genre,
    this.adresse,
    this.lieuNaissance,
    this.dateNaissance,
    this.email,
  });

  @override
  List<Object?> get props =>
      [idUser, currentStatus, nom, prenom, genre, adresse, lieuNaissance, dateNaissance, email];
}

class EditBoutiqueRequested extends OnboardingEvent {
  final int idBoutique;
  final String idUser;
  final String libelle;
  final String? description;
  final String? adresse;
  final double? latitude;
  final double? longitude;
  final String currentStatus;
  final double currentCommission;

  const EditBoutiqueRequested({
    required this.idBoutique,
    required this.idUser,
    required this.libelle,
    this.description,
    this.adresse,
    this.latitude,
    this.longitude,
    required this.currentStatus,
    required this.currentCommission,
  });

  @override
  List<Object?> get props => [idBoutique, idUser, libelle, description, adresse, latitude, longitude];
}

class CreateBoutiqueRequested extends OnboardingEvent {
  final String idUser;
  final String libelle;
  final String? description;
  final String? adresse;
  final double? latitude;
  final double? longitude;

  const CreateBoutiqueRequested({
    required this.idUser,
    required this.libelle,
    this.description,
    this.adresse,
    this.latitude,
    this.longitude,
  });

  @override
  List<Object?> get props => [idUser, libelle, description, adresse, latitude, longitude];
}