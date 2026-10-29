import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/personne_entity.dart';

part 'personne_model.g.dart';


@JsonSerializable()
class PersonneModel extends PersonneEntity {
  const PersonneModel({
    required super.idPersonne,
    required super.nom,
    required super.prenom,
    super.email,
    super.genre,
    super.adresse,
    super.dateNaissance,
    super.lieuNaissance,
    super.photo,
  });

  factory PersonneModel.fromJson(Map<String, dynamic> json) =>
      _$PersonneModelFromJson(json);
  Map<String, dynamic> toJson() => _$PersonneModelToJson(this);
}