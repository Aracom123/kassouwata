class SaveTontineModel {
  final String libelle;
  final String? description;
  final DateTime? dateDebut;
  final DateTime? dateFin;
  final double montant;
  final String? periodicite;
  final String? ownerIdUser;

  const SaveTontineModel({
    required this.libelle,
    this.description,
    this.dateDebut,
    this.dateFin,
    required this.montant,
    this.periodicite,
    this.ownerIdUser,
  });

  Map<String, dynamic> toJson() => {
        'libelle': libelle,
        if (description != null && description!.isNotEmpty)
          'description': description,
        if (dateDebut != null)
          'dateDebut': dateDebut!.toIso8601String().split('T')[0],
        if (dateFin != null)
          'dateFin': dateFin!.toIso8601String().split('T')[0],
        'montant': montant,
        if (periodicite != null) 'periodicite': periodicite,
        if (ownerIdUser != null) 'tontineOwner': {'idUser': ownerIdUser},
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// SavePeriodeModel
// Corps de la requête POST/PUT /api/nosTontinePeriodeVersements/save|update/{id}
// Les champs tontine et beneficiaire sont des objets imbriqués (référence par ID).
// ─────────────────────────────────────────────────────────────────────────────

class SavePeriodeModel {
  final String libelle;
  final DateTime? dateDebut;
  final DateTime? dateFin;
  /// ID de la tontine parente (obligatoire pour la création)
  final int? idTontine;
  /// UUID du membre bénéficiaire (optionnel)
  final String? beneficiaireUserId;

  const SavePeriodeModel({
    required this.libelle,
    this.dateDebut,
    this.dateFin,
    this.idTontine,
    this.beneficiaireUserId,
  });

  Map<String, dynamic> toJson() => {
        'libelle': libelle,
        if (dateDebut != null)
          'dateDebut': dateDebut!.toIso8601String().split('T')[0],
        if (dateFin != null)
          'dateFin': dateFin!.toIso8601String().split('T')[0],
        if (idTontine != null) 'tontine': {'idTontine': idTontine},
        if (beneficiaireUserId != null && beneficiaireUserId!.isNotEmpty)
          'beneficiaire': {'idUser': beneficiaireUserId},
      };
}
