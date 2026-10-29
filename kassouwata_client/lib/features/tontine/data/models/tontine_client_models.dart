import '../../domain/entities/demande_entity.dart';

class UserSummaryModel extends UserSummaryEntity {
  const UserSummaryModel({
    required super.idUser,
    required super.telephone,
    super.nom,
    super.prenom,
  });

  factory UserSummaryModel.fromJson(Map<String, dynamic> json) {
    final personne = json['personne'] as Map<String, dynamic>?;
    return UserSummaryModel(
      idUser: (json['idUser'] as String?) ?? '',
      telephone: (json['telephone'] as String?) ?? '',
      nom: personne?['nom'] as String?,
      prenom: personne?['prenom'] as String?,
    );
  }
}

class TontineModel extends TontineEntity {
  const TontineModel({
    required super.idTontine,
    required super.libelle,
    super.description,
    super.dateDebut,
    super.dateFin,
    required super.montant,
    super.periodicite,
    super.ownerIdUser,
    super.typeAdashe,
    super.statutAdashe,
    super.produitId,
    super.produitLibelle,
    super.produitImage,
    super.montantCible,
    super.nombreMembres,
    super.nombrePeriodes,
    super.ouverte,
    super.motifRefus,
  });

  factory TontineModel.fromJson(Map<String, dynamic> json) {
    final owner = json['tontineOwner'] as Map<String, dynamic>?;
    final produit = json['produit'] as Map<String, dynamic>?;
    return TontineModel(
      idTontine: (json['idTontine'] as num).toInt(),
      libelle: json['libelle'] as String? ?? '',
      description: json['description'] as String?,
      dateDebut: json['dateDebut'] != null
          ? DateTime.tryParse(json['dateDebut'].toString())
          : null,
      dateFin: json['dateFin'] != null
          ? DateTime.tryParse(json['dateFin'].toString())
          : null,
      montant: (json['montant'] as num?)?.toDouble() ?? 0.0,
      periodicite: json['periodicite'] as String?,
      ownerIdUser: owner?['idUser'] as String?,
      typeAdashe: json['typeAdashe'] as String?,
      statutAdashe: json['statutAdashe'] as String?,
      produitId: (produit?['idProduit'] as num?)?.toInt(),
      produitLibelle: produit?['libelle'] as String?,
      produitImage: produit?['imagePrincipale'] as String?,
      montantCible: (json['montantCible'] as num?)?.toDouble(),
      nombreMembres: (json['nombreMembres'] as num?)?.toInt(),
      nombrePeriodes: (json['nombrePeriodes'] as num?)?.toInt(),
      ouverte: json['ouverte'] == true,
      motifRefus: json['motifRefus'] as String?,
    );
  }

  static Map<String, dynamic> buildPayload({
    required String libelle,
    required double montant,
    String? periodicite,
    String? description,
    DateTime? dateDebut,
    DateTime? dateFin,
    required String idUser,
  }) =>
      {
        'libelle': libelle,
        'montant': montant,
        if (periodicite != null && periodicite.isNotEmpty)
          'periodicite': periodicite,
        if (description != null && description.isNotEmpty)
          'description': description,
        if (dateDebut != null) 'dateDebut': dateDebut.toIso8601String(),
        if (dateFin != null) 'dateFin': dateFin.toIso8601String(),
        'tontineOwner': {'idUser': idUser},
      };
}

class DemandeAdhesionModel extends DemandeAdhesionEntity {
  const DemandeAdhesionModel({
    required super.idDemandeAdhesion,
    required super.telephone,
    super.dateEnvoi,
    required super.statut,
    super.idTontine,
    super.tontineLibelle,
  });

  factory DemandeAdhesionModel.fromJson(Map<String, dynamic> json) {
    final tontine = json['tontine'] as Map<String, dynamic>?;
    final statutStr =
        (json['statut'] as String? ?? 'ENVOYEE').toUpperCase();
    DemandeStatus statut;
    switch (statutStr) {
      case 'ACCEPTEE':
        statut = DemandeStatus.acceptee;
      case 'REFUSEE':
        statut = DemandeStatus.refusee;
      default:
        statut = DemandeStatus.envoyee;
    }
    return DemandeAdhesionModel(
      idDemandeAdhesion: (json['idDemandeAdhesion'] as num).toInt(),
      telephone: json['telephone'] as String? ?? '',
      dateEnvoi: json['dateEnvoi'] != null
          ? DateTime.tryParse(json['dateEnvoi'].toString())
          : null,
      statut: statut,
      idTontine: (tontine?['idTontine'] as num?)?.toInt(),
      tontineLibelle: tontine?['libelle'] as String?,
    );
  }
}

class PeriodeVersementModel extends PeriodeVersementEntity {
  const PeriodeVersementModel({
    required super.idTontinePeriodeVersement,
    super.libelle,
    super.dateDebut,
    super.dateFin,
    super.idTontine,
    super.beneficiaireTelephone,
  });

  factory PeriodeVersementModel.fromJson(Map<String, dynamic> json) {
    final tontine = json['tontine'] as Map<String, dynamic>?;
    final beneficiaire = json['beneficiaire'] as Map<String, dynamic>?;
    return PeriodeVersementModel(
      idTontinePeriodeVersement:
          (json['idTontinePeriodeVersement'] as num).toInt(),
      libelle: json['libelle'] as String?,
      dateDebut: json['dateDebut'] != null
          ? DateTime.tryParse(json['dateDebut'].toString())
          : null,
      dateFin: json['dateFin'] != null
          ? DateTime.tryParse(json['dateFin'].toString())
          : null,
      idTontine: (tontine?['idTontine'] as num?)?.toInt(),
      beneficiaireTelephone: beneficiaire?['telephone'] as String?,
    );
  }

  static Map<String, dynamic> buildPayload({
    required String libelle,
    required int idTontine,
    DateTime? dateDebut,
    DateTime? dateFin,
    String? beneficiaireIdUser,
  }) =>
      {
        'libelle': libelle,
        'tontine': {'idTontine': idTontine},
        if (dateDebut != null) 'dateDebut': dateDebut.toIso8601String(),
        if (dateFin != null) 'dateFin': dateFin.toIso8601String(),
        if (beneficiaireIdUser != null)
          'beneficiaire': {'idUser': beneficiaireIdUser},
      };
}

class TontineVersementModel extends TontineVersementEntity {
  const TontineVersementModel({
    required super.idTontineVersement,
    super.idTontinePeriodeVersement,
    super.montant,
    super.dateVersement,
    super.membreTelephone,
    super.membreIdUser,
  });

  factory TontineVersementModel.fromJson(Map<String, dynamic> json) {
    final periode = json['tontinePeriodeVersement'] as Map<String, dynamic>?;
    final membre = json['membre'] as Map<String, dynamic>?;
    return TontineVersementModel(
      idTontineVersement: json['idTontineVersement'] as String,
      idTontinePeriodeVersement:
          (periode?['idTontinePeriodeVersement'] as num?)?.toInt(),
      montant: (json['montant'] as num?)?.toDouble(),
      dateVersement: json['dateVersement'] != null
          ? DateTime.tryParse(json['dateVersement'].toString())
          : null,
      membreTelephone: membre?['telephone'] as String? ??
          json['telephone'] as String?,
      membreIdUser: membre?['idUser'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'tontinePeriodeVersement': {
          'idTontinePeriodeVersement': idTontinePeriodeVersement
        },
        if (membreIdUser != null)
          'membre': {'idUser': membreIdUser}
        else if (membreTelephone != null)
          'membre': {'telephone': membreTelephone},
        'telephone': membreTelephone,
        'montant': montant,
        'dateVersement': DateTime.now().toIso8601String(),
      };
}
