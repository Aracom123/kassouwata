import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/livraison_entity.dart';

part 'livraison_model.g.dart';

@JsonSerializable()
class LivraisonModel {
  final int idLivraison;
  final DateTime? dateLivraison;
  final String? adresseLivraison;
  final int? idCommande;

  const LivraisonModel({
    required this.idLivraison,
    this.dateLivraison,
    this.adresseLivraison,
    this.idCommande,
  });

  factory LivraisonModel.fromJson(Map<String, dynamic> json) =>
      _$LivraisonModelFromJson(json);
  Map<String, dynamic> toJson() => _$LivraisonModelToJson(this);

  LivraisonEntity toEntity() => LivraisonEntity(
        idLivraison: idLivraison,
        dateLivraison: dateLivraison,
        adresseLivraison: adresseLivraison,
        idCommande: idCommande,
      );
}