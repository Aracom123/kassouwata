import '../../domain/entities/boutique_entity.dart';

class BoutiqueModel extends BoutiqueEntity {
  const BoutiqueModel({
    required super.idBoutique,
    required super.libelle,
    super.description,
    super.adresse,
    required super.status,
  });

  factory BoutiqueModel.fromJson(Map<String, dynamic> json) {
    return BoutiqueModel(
      idBoutique: (json['idBoutique'] as num).toInt(),
      libelle: json['libelle'] as String? ?? '',
      description: json['description'] as String?,
      adresse: json['adresse'] as String?,
      status: json['status'] as String? ?? 'PENDING',
    );
  }
}
