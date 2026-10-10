import 'package:json_annotation/json_annotation.dart';
import '../../../../shared/enums/boutique_status.dart';
import '../../domain/entities/shop_entity.dart';

part 'shop_model.g.dart';

@JsonSerializable()
class ShopModel {
  final int idBoutique;
  final String libelle;
  final String? description;
  final String? adresse;
  final double? latitude;
  final double? longitude;
  final double commission;
  @JsonKey(fromJson: _boutiqueStatusFromJson, toJson: _boutiqueStatusToJson)
  final BoutiqueStatus status;

  const ShopModel({
    required this.idBoutique,
    required this.libelle,
    this.description,
    this.adresse,
    this.latitude,
    this.longitude,
    this.commission = 5.0,
    this.status = BoutiqueStatus.pending,
  });

  factory ShopModel.fromJson(Map<String, dynamic> json) =>
      _$ShopModelFromJson(json);
  Map<String, dynamic> toJson() => _$ShopModelToJson(this);

  ShopEntity toEntity() => ShopEntity(
        idBoutique: idBoutique,
        libelle: libelle,
        description: description,
        adresse: adresse,
        latitude: latitude,
        longitude: longitude,
        commission: commission,
        status: status,
      );
}

BoutiqueStatus _boutiqueStatusFromJson(String value) =>
    BoutiqueStatus.fromJson(value);
String _boutiqueStatusToJson(BoutiqueStatus status) => status.toJson();