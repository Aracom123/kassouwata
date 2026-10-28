import '../../domain/entities/user_entity.dart';

/// Correspond à la réponse de /authenticate
class AuthResponseModel {
  final String token;
  final String idUser;
  final String status;
  final String login;
  final String profile;
  final String? email;
  final String? nom;
  final String? prenom;
  final String? genre;
  final String? adresse;
  final String? dateNaissance;
  final String? lieuNaissance;
  /// Date d'expiration du JWT (null si absent dans la réponse)
  final DateTime? expiresIn;
  /// Boutique du vendeur (profil VENDEUR uniquement, null sinon)
  final Map<String, dynamic>? boutique;

  const AuthResponseModel({
    required this.token,
    required this.idUser,
    required this.status,
    required this.login,
    required this.profile,
    this.email,
    this.nom,
    this.prenom,
    this.genre,
    this.adresse,
    this.dateNaissance,
    this.lieuNaissance,
    this.expiresIn,
    this.boutique,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    // Le backend envoie expiresIn soit comme timestamp (int ms) soit comme String ISO
    DateTime? expiresIn;
    final raw = json['expiresIn'];
    if (raw is int) {
      expiresIn = DateTime.fromMillisecondsSinceEpoch(raw);
    } else if (raw is String) {
      expiresIn = DateTime.tryParse(raw);
    }

    return AuthResponseModel(
      token: json['token'] as String,
      idUser: json['idUser'] as String,
      status: json['status'] as String? ?? 'KYC_PENDING',
      login: json['login'] as String,
      profile: json['profile'] as String? ?? '',
      email: json['email'] as String?,
      nom: json['nom'] as String?,
      prenom: json['prenom'] as String?,
      genre: json['genre'] as String?,
      adresse: json['adresse'] as String?,
      dateNaissance: json['dateNaissance'] as String?,
      lieuNaissance: json['lieuNaissance'] as String?,
      expiresIn: expiresIn,
      boutique: json['boutique'] is Map
          ? Map<String, dynamic>.from(json['boutique'] as Map)
          : null,
    );
  }

  UserEntity toEntity() => UserEntity(
        idUser: idUser,
        telephone: login,
        nom: nom,
        prenom: prenom,
        email: email,
        genre: genre,
        adresse: adresse,
        dateNaissance: dateNaissance,
        lieuNaissance: lieuNaissance,
        profile: profile,
        status: status,
        token: token,
      );
}
