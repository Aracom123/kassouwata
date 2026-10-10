part of 'tontine_bloc.dart';

abstract class TontineEvent extends Equatable {
  const TontineEvent();
  @override
  List<Object?> get props => [];
}

// ── Tontines ──────────────────────────────────────────────────────────────────

class LoadTontines extends TontineEvent {
  const LoadTontines();
}

/// Charge tontines + demandes, puis sépare "mes tontines" et "tontines rejointes".
class LoadTontinesFull extends TontineEvent {
  final String userTelephone;
  const LoadTontinesFull(this.userTelephone);
  @override
  List<Object?> get props => [userTelephone];
}

class CreateTontine extends TontineEvent {
  final String libelle;
  final String? description;
  final DateTime? dateDebut;
  final DateTime? dateFin;
  final double montant;
  final String? periodicite;
  final String? ownerIdUser;

  const CreateTontine({
    required this.libelle,
    this.description,
    this.dateDebut,
    this.dateFin,
    required this.montant,
    this.periodicite,
    this.ownerIdUser,
  });

  @override
  List<Object?> get props => [libelle, montant];
}

class UpdateTontine extends TontineEvent {
  final int idTontine;
  final String libelle;
  final String? description;
  final DateTime? dateDebut;
  final DateTime? dateFin;
  final double montant;
  final String? periodicite;

  const UpdateTontine({
    required this.idTontine,
    required this.libelle,
    this.description,
    this.dateDebut,
    this.dateFin,
    required this.montant,
    this.periodicite,
  });

  @override
  List<Object?> get props => [idTontine];
}

class DeleteTontine extends TontineEvent {
  final int idTontine;
  const DeleteTontine(this.idTontine);
  @override
  List<Object?> get props => [idTontine];
}

// ── Périodes ──────────────────────────────────────────────────────────────────

class LoadPeriodes extends TontineEvent {
  final int idTontine;
  const LoadPeriodes(this.idTontine);
  @override
  List<Object?> get props => [idTontine];
}

class CreatePeriode extends TontineEvent {
  final int idTontine;
  final String libelle;
  final DateTime? dateDebut;
  final DateTime? dateFin;
  final String? beneficiaireUserId;

  const CreatePeriode({
    required this.idTontine,
    required this.libelle,
    this.dateDebut,
    this.dateFin,
    this.beneficiaireUserId,
  });

  @override
  List<Object?> get props => [idTontine, libelle];
}

class UpdatePeriode extends TontineEvent {
  final int idTontinePeriodeVersement;
  final int idTontine;
  final String libelle;
  final DateTime? dateDebut;
  final DateTime? dateFin;
  final String? beneficiaireUserId;

  const UpdatePeriode({
    required this.idTontinePeriodeVersement,
    required this.idTontine,
    required this.libelle,
    this.dateDebut,
    this.dateFin,
    this.beneficiaireUserId,
  });

  @override
  List<Object?> get props => [idTontinePeriodeVersement];
}

class DeletePeriode extends TontineEvent {
  final int idTontinePeriodeVersement;
  const DeletePeriode(this.idTontinePeriodeVersement);
  @override
  List<Object?> get props => [idTontinePeriodeVersement];
}

// ── Versements ────────────────────────────────────────────────────────────────

class LoadVersements extends TontineEvent {
  final int idTontinePeriodeVersement;
  const LoadVersements(this.idTontinePeriodeVersement);
  @override
  List<Object?> get props => [idTontinePeriodeVersement];
}

class CreateVersement extends TontineEvent {
  final int idPeriode;
  final double montant;
  final String telephone;
  final String? idUser;
  final TontineTypePaiement typePaiement;
  final TontineFournisseur fournisseur;
  final String? numeroCompte;
  final String? numeroCarte;
  final String? nomPorteur;

  const CreateVersement({
    required this.idPeriode,
    required this.montant,
    required this.telephone,
    this.idUser,
    required this.typePaiement,
    required this.fournisseur,
    this.numeroCompte,
    this.numeroCarte,
    this.nomPorteur,
  });

  @override
  List<Object?> get props => [idPeriode, montant, telephone];
}

// ── Demandes d'adhésion ───────────────────────────────────────────────────────

class LoadDemandesAdhesion extends TontineEvent {
  final int idTontine;
  const LoadDemandesAdhesion(this.idTontine);
  @override
  List<Object?> get props => [idTontine];
}

class CreateDemandeAdhesion extends TontineEvent {
  final int idTontine;
  final String telephone;
  const CreateDemandeAdhesion({
    required this.idTontine,
    required this.telephone,
  });
  @override
  List<Object?> get props => [idTontine, telephone];
}

class UpdateStatutDemande extends TontineEvent {
  final int idDemandeAdhesion;
  final DemandeAdhesionStatus statut;
  const UpdateStatutDemande({
    required this.idDemandeAdhesion,
    required this.statut,
  });
  @override
  List<Object?> get props => [idDemandeAdhesion, statut];
}

class DeleteDemandeAdhesion extends TontineEvent {
  final int idDemandeAdhesion;
  const DeleteDemandeAdhesion(this.idDemandeAdhesion);
  @override
  List<Object?> get props => [idDemandeAdhesion];
}
