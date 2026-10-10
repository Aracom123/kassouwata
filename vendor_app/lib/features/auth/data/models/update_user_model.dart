import 'package:json_annotation/json_annotation.dart';

part 'update_user_model.g.dart';

/// Corps de la requête PUT /api/nosUsers/update/{id}
@JsonSerializable()
class UpdateUserRequestModel {
  final String status;
  final UpdateProfileModel profile;
  final UpdatePersonneModel personne;

  const UpdateUserRequestModel({
    required this.status,
    required this.profile,
    required this.personne,
  });

  factory UpdateUserRequestModel.fromJson(Map<String, dynamic> json) =>
      _$UpdateUserRequestModelFromJson(json);
  Map<String, dynamic> toJson() => _$UpdateUserRequestModelToJson(this);
}

@JsonSerializable()
class UpdateProfileModel {
  final int idProfile;
  const UpdateProfileModel({required this.idProfile});

  factory UpdateProfileModel.fromJson(Map<String, dynamic> json) =>
      _$UpdateProfileModelFromJson(json);
  Map<String, dynamic> toJson() => _$UpdateProfileModelToJson(this);
}

@JsonSerializable()
class UpdatePersonneModel {
  final String? nom;
  final String? prenom;
  final String? genre;
  final String? adresse;
  final String? lieuNaissance;
  final String? email;
  @JsonKey(toJson: _dateToJson, fromJson: _dateFromJson)
  final DateTime? dateNaissance;

  const UpdatePersonneModel({
    this.nom,
    this.prenom,
    this.genre,
    this.adresse,
    this.lieuNaissance,
    this.email,
    this.dateNaissance,
  });

  factory UpdatePersonneModel.fromJson(Map<String, dynamic> json) =>
      _$UpdatePersonneModelFromJson(json);
  Map<String, dynamic> toJson() => _$UpdatePersonneModelToJson(this);
}

String? _dateToJson(DateTime? date) => date?.toIso8601String().split('T').first;
DateTime? _dateFromJson(String? s) => s == null ? null : DateTime.tryParse(s);