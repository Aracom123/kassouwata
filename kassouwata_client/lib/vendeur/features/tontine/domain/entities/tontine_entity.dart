import 'package:equatable/equatable.dart';

class TontineEntity extends Equatable {
  final int idTontine;
  final String libelle;
  final String? description;
  final DateTime? dateDebut;
  final DateTime? dateFin;
  final double montant;
  final String? periodicite;
  final String? tontineOwnerTelephone;

  const TontineEntity({
    required this.idTontine,
    required this.libelle,
    this.description,
    this.dateDebut,
    this.dateFin,
    required this.montant,
    this.periodicite,
    this.tontineOwnerTelephone,
  });

  @override
  List<Object?> get props => [idTontine, libelle, montant];
}

class PeriodeVersementEntity extends Equatable {
  final int idTontinePeriodeVersement;
  final String libelle;
  final DateTime? dateDebut;
  final DateTime? dateFin;
  /// Téléphone du bénéficiaire (extrait de l'objet User imbriqué)
  final String? beneficiaireTelephone;
  /// ID utilisateur du bénéficiaire (UUID)
  final String? beneficiaireUserId;
  /// ID de la tontine parente (extrait de l'objet Tontine imbriqué)
  final int? idTontine;

  const PeriodeVersementEntity({
    required this.idTontinePeriodeVersement,
    required this.libelle,
    this.dateDebut,
    this.dateFin,
    this.beneficiaireTelephone,
    this.beneficiaireUserId,
    this.idTontine,
  });

  @override
  List<Object?> get props => [idTontinePeriodeVersement, libelle];
}

// ─────────────────────────────────────────────────────────────────────────────
// DemandeAdhesionEntity
// Représente une invitation à rejoindre une tontine.
// ─────────────────────────────────────────────────────────────────────────────

enum DemandeAdhesionStatus { envoyee, acceptee, refusee }

class DemandeAdhesionEntity extends Equatable {
  final int idDemandeAdhesion;
  final String telephone;
  final DateTime? dateEnvoi;
  final DemandeAdhesionStatus statut;
  final int? idTontine;

  const DemandeAdhesionEntity({
    required this.idDemandeAdhesion,
    required this.telephone,
    this.dateEnvoi,
    this.statut = DemandeAdhesionStatus.envoyee,
    this.idTontine,
  });

  @override
  List<Object?> get props => [idDemandeAdhesion, telephone];
}

enum TontineTypePaiement { mobileMoney, cartePaiement }

enum TontineFournisseur { nita, amana, airtelMoney, moovMoney, visa, mastercard }

extension TontineTypePaiementX on TontineTypePaiement {
  String get label =>
      this == TontineTypePaiement.mobileMoney ? 'Mobile Money' : 'Carte de paiement';
}

extension TontineFournisseurX on TontineFournisseur {
  String get label => switch (this) {
        TontineFournisseur.nita => 'Nita',
        TontineFournisseur.amana => 'Amana',
        TontineFournisseur.airtelMoney => 'Airtel Money',
        TontineFournisseur.moovMoney => 'Moov Money',
        TontineFournisseur.visa => 'VISA',
        TontineFournisseur.mastercard => 'MasterCard',
      };

  String get apiValue => switch (this) {
        TontineFournisseur.nita => 'NITA',
        TontineFournisseur.amana => 'AMANA',
        TontineFournisseur.airtelMoney => 'AIRTEL_MONEY',
        TontineFournisseur.moovMoney => 'MOOV_MONEY',
        TontineFournisseur.visa => 'VISA',
        TontineFournisseur.mastercard => 'MASTERCARD',
      };

  bool get isMobileMoney => [
        TontineFournisseur.nita,
        TontineFournisseur.amana,
        TontineFournisseur.airtelMoney,
        TontineFournisseur.moovMoney,
      ].contains(this);
}

List<TontineFournisseur> fournisseursFor(TontineTypePaiement type) =>
    type == TontineTypePaiement.mobileMoney
        ? [
            TontineFournisseur.nita,
            TontineFournisseur.amana,
            TontineFournisseur.airtelMoney,
            TontineFournisseur.moovMoney,
          ]
        : [TontineFournisseur.visa, TontineFournisseur.mastercard];

class TontineVersementEntity extends Equatable {
  final String idTontineVersement;
  final DateTime? dateVersement;
  final double montant;
  final String? telephone;
  final String? membreTelephone;
  final String? membreNom;
  final String? membrePrenom;
  final int? idTontinePeriodeVersement;
  final TontineTypePaiement? typePaiement;
  final TontineFournisseur? fournisseur;
  final String? numeroCompte;
  final String? numeroCarte;
  final String? nomPorteur;

  const TontineVersementEntity({
    required this.idTontineVersement,
    this.dateVersement,
    required this.montant,
    this.telephone,
    this.membreTelephone,
    this.membreNom,
    this.membrePrenom,
    this.idTontinePeriodeVersement,
    this.typePaiement,
    this.fournisseur,
    this.numeroCompte,
    this.numeroCarte,
    this.nomPorteur,
  });

  String get displayPhone => telephone ?? membreTelephone ?? 'Membre inconnu';

  String get displayName {
    final parts = [membrePrenom, membreNom].where((s) => s != null && s.isNotEmpty);
    if (parts.isNotEmpty) return parts.join(' ');
    return displayPhone;
  }

  @override
  List<Object?> get props => [idTontineVersement, montant, dateVersement];
}
