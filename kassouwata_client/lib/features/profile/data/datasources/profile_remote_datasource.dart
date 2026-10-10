import 'package:injectable/injectable.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';

abstract class ProfileRemoteDataSource {
  /// Complète le profil KYC : envoie tous les champs de la Personne.
  Future<void> completeProfile({
    required String idUser,
    required String nom,
    required String prenom,
    String? email,
    String? genre,
    String? adresse,
    String? dateNaissance,
    String? lieuNaissance,
  });

  /// Rafraîchit le token JWT sans mot de passe.
  /// Retourne la réponse JSON du backend (même format que /authenticate).
  Future<Map<String, dynamic>> refreshToken();
}

@Injectable(as: ProfileRemoteDataSource)
class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final DioClient _dioClient;
  const ProfileRemoteDataSourceImpl(this._dioClient);

  @override
  Future<void> completeProfile({
    required String idUser,
    required String nom,
    required String prenom,
    String? email,
    String? genre,
    String? adresse,
    String? dateNaissance,
    String? lieuNaissance,
  }) async {
    final data = <String, dynamic>{
      'nom': nom,
      'prenom': prenom,
    };
    if (email != null && email.isNotEmpty) data['email'] = email;
    if (genre != null && genre.isNotEmpty) data['genre'] = genre;
    if (adresse != null && adresse.isNotEmpty) data['adresse'] = adresse;
    if (dateNaissance != null && dateNaissance.isNotEmpty) data['dateNaissance'] = dateNaissance;
    if (lieuNaissance != null && lieuNaissance.isNotEmpty) data['lieuNaissance'] = lieuNaissance;

    await _dioClient.dio.put(
      ApiEndpoints.completeProfile(idUser),
      data: data,
    );
  }

  @override
  Future<Map<String, dynamic>> refreshToken() async {
    final response = await _dioClient.dio.post(ApiEndpoints.refreshToken);
    return response.data as Map<String, dynamic>;
  }
}
