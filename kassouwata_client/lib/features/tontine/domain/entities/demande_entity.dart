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

  // Adashé Produit (achat groupé d'un produit) — vides pour un Adashé classique
  final String? typeAdashe;
  /// EN_ATTENTE_VENDEUR, ACTIF, REFUSE, OBJECTIF_ATTEINT
  final String? statutAdashe;
  final int? produitId;
  final String? produitLibelle;
  final String? produitImage;
  final double? montantCible;
  final int? nombreMembres;
  final int? nombrePeriodes;
  final bool ouverte;
  final String? motifRefus;

  bool get estProduit => typeAdashe == 'PRODUIT';
  String get statut => statutAdashe ?? 'ACTIF';

  /// Libellé lisible du statut d'un Adashé Produit
  String get statutLibelle {
    switch (statut) {
      case 'EN_ATTENTE_VENDEUR':
        return 'En attente du vendeur';
      case 'REFUSE':
        return 'Refusé par le vendeur';
      case 'OBJECTIF_ATTEINT':
        return 'Objectif atteint';
      default:
        return 'Actif';
    }
  }

  const TontineEntity({
    required this.idTontine,
    required this.libelle,
    this.description,
    this.dateDebut,
    this.dateFin,
    required this.montant,
    this.periodicite,
    this.ownerIdUser,
    this.typeAdashe,
    this.statutAdashe,
    this.produitId,
    this.produitLibelle,
    this.produitImage,
    this.montantCible,
    this.nombreMembres,
    this.nombrePeriodes,
    this.ouverte = false,
    this.motifRefus,
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
