import 'package:equatable/equatable.dart';

enum DemandeStatus { envoyee, acceptee, refusee }

class UserSummaryEntity extends Equatable {
  final String idUser;
  final String telephone;
  final String? nom;
  final String? prenom;

  const UserSummaryEntity({
    required this.idUser,
    required this.telephone,
    this.nom,
    this.prenom,
  });

  String get displayName {
    if (prenom != null && nom != null) return '$prenom $nom';
    if (prenom != null) return prenom!;
    if (nom != null) return nom!;
    return telephone;
  }

  @override
  List<Object?> get props => [idUser];
}

class TontineEntity extends Equatable {
  final int idTontine;
  final String libelle;
  final String? description;
  final DateTime? dateDebut;
  final DateTime? dateFin;
  final double montant;
  final String? periodicite;
  final String? ownerIdUser;

  const TontineEntity({
    required this.idTontine,
    required this.libelle,
    this.description,
    this.dateDebut,
    this.dateFin,
    required this.montant,
    this.periodicite,
    this.ownerIdUser,
  });

  @override
  List<Object?> get props => [idTontine];
}

class DemandeAdhesionEntity extends Equatable {
  final int idDemandeAdhesion;
  final String telephone;
  final DateTime? dateEnvoi;
  final DemandeStatus statut;
  final int? idTontine;
  final String? tontineLibelle;

  const DemandeAdhesionEntity({
    required this.idDemandeAdhesion,
    required this.telephone,
    this.dateEnvoi,
    required this.statut,
    this.idTontine,
    this.tontineLibelle,
  });

  @override
  List<Object?> get props => [idDemandeAdhesion];
}

class PeriodeVersementEntity extends Equatable {
  final int idTontinePeriodeVersement;
  final String? libelle;
  final DateTime? dateDebut;
  final DateTime? dateFin;
  final int? idTontine;
  final String? beneficiaireTelephone;

  const PeriodeVersementEntity({
    required this.idTontinePeriodeVersement,
    this.libelle,
    this.dateDebut,
    this.dateFin,
    this.idTontine,
    this.beneficiaireTelephone,
  });

  @override
  List<Object?> get props => [idTontinePeriodeVersement];
}

class TontineVersementEntity extends Equatable {
  final String idTontineVersement;
  final int? idTontinePeriodeVersement;
  final double? montant;
  final DateTime? dateVersement;
  final String? membreTelephone;
  final String? membreIdUser;

  const TontineVersementEntity({
    required this.idTontineVersement,
    this.idTontinePeriodeVersement,
    this.montant,
    this.dateVersement,
    this.membreTelephone,
    this.membreIdUser,
  });

  @override
  List<Object?> get props => [idTontineVersement];
}
