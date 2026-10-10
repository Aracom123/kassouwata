import 'package:json_annotation/json_annotation.dart';

part 'token_model.g.dart';

/// Convertit int ou String en String nullable (robustesse typage backend).
String? _toNullableString(dynamic value) =>
    value == null ? null : value.toString();

/// Correspond à la réponse de POST /authenticate
@JsonSerializable()
class TokenModel {
  final String token;
  @JsonKey(fromJson: _toNullableString)
  final String? expiresIn;
  final bool? isExpired;
  @JsonKey(fromJson: _toNullableString)
  final String? idUser;
  final String? status;
  final String? login;
  final String? profile;
  final String? email;
  final String? nom;
  final String? prenom;
  @JsonKey(includeToJson: false)
  final Map<String, dynamic>? boutique;

  const TokenModel({
    required this.token,
    this.expiresIn,
    this.isExpired,
    this.idUser,
    this.status,
    this.login,
    this.profile,
    this.email,
    this.nom,
    this.prenom,
    this.boutique,
  });

  factory TokenModel.fromJson(Map<String, dynamic> json) =>
      _$TokenModelFromJson(json);
  Map<String, dynamic> toJson() => _$TokenModelToJson(this);
}