import 'package:json_annotation/json_annotation.dart';

part 'create_boutique_model.g.dart';

/// Corps de la requête POST /api/nosBoutiques/save
@JsonSerializable()
class CreateBoutiqueRequestModel {
  final String libelle;
  final String? description;
  final String? adresse;
  final double? latitude;
  final double? longitude;
  final BoutiqueVendeurModel vendeur;
  final String status;

  const CreateBoutiqueRequestModel({
    required this.libelle,
    this.description,
    this.adresse,
    this.latitude,
    this.longitude,
    required this.vendeur,
    this.status = 'PENDING',
  });

  factory CreateBoutiqueRequestModel.fromJson(Map<String, dynamic> json) =>
      _$CreateBoutiqueRequestModelFromJson(json);
  Map<String, dynamic> toJson() => _$CreateBoutiqueRequestModelToJson(this);
}

@JsonSerializable()
class BoutiqueVendeurModel {
  final String idUser;
  const BoutiqueVendeurModel({required this.idUser});

  factory BoutiqueVendeurModel.fromJson(Map<String, dynamic> json) =>
      _$BoutiqueVendeurModelFromJson(json);
  Map<String, dynamic> toJson() => _$BoutiqueVendeurModelToJson(this);
}