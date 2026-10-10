import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/categorie_entity.dart';

part 'categorie_model.g.dart';

@JsonSerializable()
class CategorieModel extends CategorieEntity {
  const CategorieModel({
    required super.idCategorie,
    required super.libelle,
    super.description,
  });

  factory CategorieModel.fromJson(Map<String, dynamic> json) =>
      _$CategorieModelFromJson(json);
  Map<String, dynamic> toJson() => _$CategorieModelToJson(this);
}