import '../../domain/entities/tontine_entity.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TontineModel
// Correspond à l'entité Tontine.java du backend.
// tontineOwner est un objet User imbriqué ; on en extrait le téléphone.
// ─────────────────────────────────────────────────────────────────────────────

class TontineModel {
  final int idTontine;
  final String libelle;
  final String? description;
  final DateTime? dateDebut;
  final DateTime? dateFin;
  final double montant;
  final String? periodicite;
  final String? tontineOwnerTelephone;

  const TontineModel({
    required this.idTontine,
    required this.libelle,
    this.description,
    this.dateDebut,
    this.dateFin,
    required this.montant,
    this.periodicite,
    this.tontineOwnerTelephone,
  });

  factory TontineModel.fromJson(Map<String, dynamic> json) {
    final owner = json['tontineOwner'] as Map<String, dynamic>?;
    return TontineModel(
      idTontine: (json['idTontine'] as num).toInt(),
      libelle: json['libelle'] as String,
      description: json['description'] as String?,
      dateDebut: _parseDate(json['dateDebut']),
      dateFin: _parseDate(json['dateFin']),
      montant: (json['montant'] as num).toDouble(),
      periodicite: json['periodicite'] as String?,
      tontineOwnerTelephone: owner?['telephone'] as String?,
    );
  }

  TontineEntity toEntity() => TontineEntity(
        idTontine: idTontine,
        libelle: libelle,
        description: description,
        dateDebut: dateDebut,
        dateFin: dateFin,
        montant: montant,
        periodicite: periodicite,
        tontineOwnerTelephone: tontineOwnerTelephone,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// PeriodeVersementModel
// Correspond à TontinePeriodeVersement.java.
// beneficiaire et tontine sont des objets imbriqués.
// ─────────────────────────────────────────────────────────────────────────────

class PeriodeVersementModel {
  final int idTontinePeriodeVersement;
  final String libelle;
  final DateTime? dateDebut;
  final DateTime? dateFin;
  final String? beneficiaireTelephone;
  final String? beneficiaireUserId;
  final int? idTontine;

  const PeriodeVersementModel({
    required this.idTontinePeriodeVersement,
    required this.libelle,
    this.dateDebut,
    this.dateFin,
    this.beneficiaireTelephone,
    this.beneficiaireUserId,
    this.idTontine,
  });

  factory PeriodeVersementModel.fromJson(Map<String, dynamic> json) {
    final beneficiaire = json['beneficiaire'] as Map<String, dynamic>?;
    final tontine = json['tontine'] as Map<String, dynamic>?;
    return PeriodeVersementModel(
      idTontinePeriodeVersement:
          (json['idTontinePeriodeVersement'] as num).toInt(),
      libelle: json['libelle'] as String,
      dateDebut: _parseDate(json['dateDebut']),
      dateFin: _parseDate(json['dateFin']),
      beneficiaireTelephone: beneficiaire?['telephone'] as String?,
      beneficiaireUserId: beneficiaire?['idUser'] as String?,
      idTontine: (tontine?['idTontine'] as num?)?.toInt(),
    );
  }

  PeriodeVersementEntity toEntity() => PeriodeVersementEntity(
        idTontinePeriodeVersement: idTontinePeriodeVersement,
        libelle: libelle,
        dateDebut: dateDebut,
        dateFin: dateFin,
        beneficiaireTelephone: beneficiaireTelephone,
        beneficiaireUserId: beneficiaireUserId,
        idTontine: idTontine,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// TontineVersementModel
// Correspond à TontineVersement.java.
// idTontineVersement est un UUID (String).
// membre et tontinePeriodeVersement sont des objets imbriqués.
// ─────────────────────────────────────────────────────────────────────────────

class TontineVersementModel {
  final String idTontineVersement;
  final DateTime? dateVersement;
  final double montant;
  final String? telephone;
  final String? membreTelephone;
  final String? membreNom;
  final String? membrePrenom;
  final int? idTontinePeriodeVersement;
  final String? typePaiement;
  final String? fournisseur;
  final String? numeroCompte;
  final String? numeroCarte;
  final String? nomPorteur;

  const TontineVersementModel({
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

  factory TontineVersementModel.fromJson(Map<String, dynamic> json) {
    final membre = json['membre'] as Map<String, dynamic>?;
    final personne = membre?['personne'] as Map<String, dynamic>?;
    final periode = json['tontinePeriodeVersement'] as Map<String, dynamic>?;
    return TontineVersementModel(
      idTontineVersement: json['idTontineVersement'] as String,
      dateVersement: _parseDate(json['dateVersement']),
      montant: (json['montant'] as num).toDouble(),
      telephone: json['telephone'] as String?,
      membreTelephone: membre?['telephone'] as String?,
      membreNom: personne?['nom'] as String?,
      membrePrenom: personne?['prenom'] as String?,
      idTontinePeriodeVersement:
          (periode?['idTontinePeriodeVersement'] as num?)?.toInt(),
      typePaiement: json['typePaiement'] as String?,
      fournisseur: json['fournisseur'] as String?,
      numeroCompte: json['numeroCompte'] as String?,
      numeroCarte: json['numeroCarte'] as String?,
      nomPorteur: json['nomPorteur'] as String?,
    );
  }

  TontineVersementEntity toEntity() => TontineVersementEntity(
        idTontineVersement: idTontineVersement,
        dateVersement: dateVersement,
        montant: montant,
        telephone: telephone,
        membreTelephone: membreTelephone,
        membreNom: membreNom,
        membrePrenom: membrePrenom,
        idTontinePeriodeVersement: idTontinePeriodeVersement,
        typePaiement: _parseType(typePaiement),
        fournisseur: _parseFournisseur(fournisseur),
        numeroCompte: numeroCompte,
        numeroCarte: numeroCarte,
        nomPorteur: nomPorteur,
      );

  static TontineTypePaiement? _parseType(String? s) => switch (s?.toUpperCase()) {
        'MOBILE_MONEY' => TontineTypePaiement.mobileMoney,
        'CARTE_PAIEMENT' => TontineTypePaiement.cartePaiement,
        _ => null,
      };

  static TontineFournisseur? _parseFournisseur(String? s) =>
      switch (s?.toUpperCase()) {
        'NITA' => TontineFournisseur.nita,
        'AMANA' => TontineFournisseur.amana,
        'AIRTEL_MONEY' => TontineFournisseur.airtelMoney,
        'MOOV_MONEY' => TontineFournisseur.moovMoney,
        'VISA' => TontineFournisseur.visa,
        'MASTERCARD' => TontineFournisseur.mastercard,
        _ => null,
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// DemandeAdhesionModel
// Correspond à DemandeAdhesion.java du backend.
// tontine est un objet imbriqué ; on en extrait l'idTontine.
// ─────────────────────────────────────────────────────────────────────────────

class DemandeAdhesionModel {
  final int idDemandeAdhesion;
  final String telephone;
  final DateTime? dateEnvoi;
  final String statut;
  final int? idTontine;

  const DemandeAdhesionModel({
    required this.idDemandeAdhesion,
    required this.telephone,
    this.dateEnvoi,
    this.statut = 'ENVOYEE',
    this.idTontine,
  });

  factory DemandeAdhesionModel.fromJson(Map<String, dynamic> json) {
    final tontine = json['tontine'] as Map<String, dynamic>?;
    return DemandeAdhesionModel(
      idDemandeAdhesion: (json['idDemandeAdhesion'] as num).toInt(),
      telephone: json['telephone'] as String,
      dateEnvoi: _parseDate(json['dateEnvoi']),
      statut: json['statut'] as String? ?? 'ENVOYEE',
      idTontine: (tontine?['idTontine'] as num?)?.toInt(),
    );
  }

  DemandeAdhesionEntity toEntity() => DemandeAdhesionEntity(
        idDemandeAdhesion: idDemandeAdhesion,
        telephone: telephone,
        dateEnvoi: dateEnvoi,
        statut: _parseStatut(statut),
        idTontine: idTontine,
      );

  static DemandeAdhesionStatus _parseStatut(String s) {
    switch (s.toUpperCase()) {
      case 'ACCEPTEE':
        return DemandeAdhesionStatus.acceptee;
      case 'REFUSEE':
        return DemandeAdhesionStatus.refusee;
      default:
        return DemandeAdhesionStatus.envoyee;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper
// ─────────────────────────────────────────────────────────────────────────────

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  try {
    return DateTime.parse(value as String);
  } catch (_) {
    return null;
  }
}
