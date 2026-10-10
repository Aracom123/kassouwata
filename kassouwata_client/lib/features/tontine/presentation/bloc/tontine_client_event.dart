part of 'tontine_client_bloc.dart';

abstract class TontineClientEvent extends Equatable {
  const TontineClientEvent();
  @override
  List<Object?> get props => [];
}

class LoadMyInvitations extends TontineClientEvent {
  final String telephone;
  const LoadMyInvitations(this.telephone);
  @override
  List<Object?> get props => [telephone];
}

class RespondToInvitation extends TontineClientEvent {
  final int idDemande;
  final DemandeStatus response;
  const RespondToInvitation(
      {required this.idDemande, required this.response});
  @override
  List<Object?> get props => [idDemande, response];
}

class LoadPeriodes extends TontineClientEvent {
  final int idTontine;
  const LoadPeriodes(this.idTontine);
  @override
  List<Object?> get props => [idTontine];
}

class SendVersement extends TontineClientEvent {
  final int idPeriode;
  final double montant;
  final String membreTelephone;
  final String membreIdUser;
  const SendVersement({
    required this.idPeriode,
    required this.montant,
    required this.membreTelephone,
    required this.membreIdUser,
  });
  @override
  List<Object?> get props => [idPeriode, montant];
}

class LoadMyTontines extends TontineClientEvent {
  final String idUser;
  const LoadMyTontines(this.idUser);
  @override
  List<Object?> get props => [idUser];
}

class LoadCurrentTontine extends TontineClientEvent {
  final int idTontine;
  const LoadCurrentTontine(this.idTontine);
  @override
  List<Object?> get props => [idTontine];
}

class LoadAllVersements extends TontineClientEvent {
  const LoadAllVersements();
}

class LoadTontineDemandes extends TontineClientEvent {
  final int idTontine;
  const LoadTontineDemandes(this.idTontine);
  @override
  List<Object?> get props => [idTontine];
}

class AddPeriode extends TontineClientEvent {
  final String libelle;
  final int idTontine;
  final DateTime? dateDebut;
  final DateTime? dateFin;
  final String? beneficiaireIdUser;

  const AddPeriode({
    required this.libelle,
    required this.idTontine,
    this.dateDebut,
    this.dateFin,
    this.beneficiaireIdUser,
  });

  @override
  List<Object?> get props => [libelle, idTontine];
}

class LoadUsers extends TontineClientEvent {
  const LoadUsers();
}

class CreateTontine extends TontineClientEvent {
  final String libelle;
  final double montant;
  final String? periodicite;
  final String? description;
  final DateTime? dateDebut;
  final DateTime? dateFin;
  final String idUser;

  const CreateTontine({
    required this.libelle,
    required this.montant,
    this.periodicite,
    this.description,
    this.dateDebut,
    this.dateFin,
    required this.idUser,
  });

  @override
  List<Object?> get props => [libelle, montant, idUser];
}

class InviteMembre extends TontineClientEvent {
  final int idTontine;
  final String telephone;

  const InviteMembre({required this.idTontine, required this.telephone});

  @override
  List<Object?> get props => [idTontine, telephone];
}
