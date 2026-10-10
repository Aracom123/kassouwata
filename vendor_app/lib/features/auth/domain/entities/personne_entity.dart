import 'package:equatable/equatable.dart';

class PersonneEntity extends Equatable {
  final String idPersonne;
  final String nom;
  final String prenom;
  final String? email;
  final String? genre;
  final String? adresse;
  final DateTime? dateNaissance;
  final String? lieuNaissance;
  final String? photo;

  const PersonneEntity({
    required this.idPersonne,
    required this.nom,
    required this.prenom,
    this.email,
    this.genre,
    this.adresse,
    this.dateNaissance,
    this.lieuNaissance,
    this.photo,
  });

  String get fullName => '$prenom $nom';

  @override
  List<Object?> get props => [idPersonne, nom, prenom, email];
}