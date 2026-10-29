class SaveProductRequestModel {
  final int idBoutique;
  final String libelle;
  final String? description;
  final double prixUnitaire;
  final int quantite;
  final String? imagePrincipale;
  final String? photos;
  final bool statut;
  /// Nombre de tranches pour le paiement prépayé.
  /// Null = paiement en tranches non disponible pour ce produit.
  final int? nombreTranches;
  /// Le produit peut être acheté en groupe (Adashé Produit)
  final bool adasheAutorise;
  final int? idCategorie;

  const SaveProductRequestModel({
    required this.idBoutique,
    required this.libelle,
    this.description,
    required this.prixUnitaire,
    required this.quantite,
    this.imagePrincipale,
    this.photos,
    this.statut = true,
    this.nombreTranches,
    this.adasheAutorise = false,
    this.idCategorie,
  });

  Map<String, dynamic> toJson() => {
        'libelle': libelle,
        if (description != null && description!.isNotEmpty) 'description': description,
        'prixUnitaire': prixUnitaire,
        'quantite': quantite,
        if (imagePrincipale != null) 'imagePrincipale': imagePrincipale,
        if (photos != null) 'photos': photos,
        'statut': statut,
        if (nombreTranches != null) 'nombreTranches': nombreTranches,
        'adasheAutorise': adasheAutorise,
        'boutique': {'idBoutique': idBoutique},
        if (idCategorie != null) 'categorie': {'idCategorie': idCategorie},
      };
}
