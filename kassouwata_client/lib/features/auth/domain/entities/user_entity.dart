import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String idUser;
  final String telephone;
  final String? nom;
  final String? prenom;
  final String? email;
  final String? genre;
  final String? adresse;
  final String? dateNaissance;
  final String? lieuNaissance;
  final String profile;
  final String status;
  final String token;

  const UserEntity({
    required this.idUser,
    required this.telephone,
    this.nom,
    this.prenom,
    this.email,
    this.genre,
    this.adresse,
    this.dateNaissance,
    this.lieuNaissance,
    required this.profile,
    required this.status,
    required this.token,
  });

  String get displayName {
    if (prenom != null && nom != null) return '$prenom $nom';
    if (prenom != null) return prenom!;
    if (nom != null) return nom!;
    return telephone;
  }

  @override
  List<Object?> get props => [idUser, telephone, profile, status];
}
