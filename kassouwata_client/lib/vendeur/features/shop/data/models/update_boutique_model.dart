/// Corps de la requête PUT /api/nosBoutiques/update/{id}
/// Le vendeur ne peut modifier que libelle, description et adresse.
/// Le status et la commission sont conservés depuis le cache.
class UpdateBoutiqueRequestModel {
  final String libelle;
  final String? description;
  final String? adresse;
  final double? latitude;
  final double? longitude;
  final String status;
  final double commission;
  final String idUser;

  const UpdateBoutiqueRequestModel({
    required this.libelle,
    this.description,
    this.adresse,
    this.latitude,
    this.longitude,
    required this.status,
    required this.commission,
    required this.idUser,
  });

  Map<String, dynamic> toJson() => {
        'libelle': libelle,
        if (description != null) 'description': description,
        if (adresse != null) 'adresse': adresse,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        'status': status,
        'commission': commission,
        'vendeur': {'idUser': idUser},
      };
}
