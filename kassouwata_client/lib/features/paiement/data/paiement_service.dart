import 'package:dio/dio.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_client.dart';
import 'paiement_models.dart';

/// Erreur lisible renvoyée par le backend ({"error": "..."}).
class PaiementException implements Exception {
  final String message;
  const PaiementException(this.message);
  @override
  String toString() => message;
}

/// Appels au backend pour les paiements (Mobile Money, STA, carte).
class PaiementService {
  final DioClient _client;
  PaiementService(this._client);

  /// Catégories et moyens de paiement actifs.
  Future<List<CategoriePaiement>> getMoyens() async {
    try {
      final response = await _client.dio.get(ApiEndpoints.moyensPaiement);
      final data = response.data as List<dynamic>? ?? [];
      return data
          .map((e) => CategoriePaiement.fromJson(e as Map<String, dynamic>))
          .where((c) => c.moyens.isNotEmpty)
          .toList();
    } on DioException catch (e) {
      throw PaiementException(_message(e, 'Impossible de charger les moyens de paiement'));
    }
  }

  /// Lance un paiement. [corps] contient éventuellement des données de carte :
  /// il n'est jamais journalisé (cf. filtre du logger dans DioClient).
  Future<ResultatPaiement> payer(Map<String, dynamic> corps) async {
    try {
      final response = await _client.dio.post(
        ApiEndpoints.payer,
        data: corps,
        // L'appel à l'agrégateur (et le chiffrement du CVV) peut être long
        options: Options(receiveTimeout: const Duration(seconds: 60)),
      );
      return ResultatPaiement.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw PaiementException(_message(e, 'Le paiement n\'a pas pu être lancé'));
    }
  }

  /// Interroge l'agrégateur via le backend et renvoie le statut à jour.
  Future<ResultatPaiement> verifierStatut(String referenceExterne) async {
    try {
      final response =
          await _client.dio.get(ApiEndpoints.statutPaiement(referenceExterne));
      return ResultatPaiement.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw PaiementException(_message(e, 'Vérification impossible pour le moment'));
    }
  }

  /// Total, montant payé, reste à payer d'une commande.
  Future<Map<String, dynamic>> resumeCommande(int idCommande) async {
    try {
      final response = await _client.dio.get(ApiEndpoints.resumePaiementCommande(idCommande));
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw PaiementException(_message(e, 'Erreur réseau'));
    }
  }

  static String _message(DioException e, String parDefaut) {
    final data = e.response?.data;
    if (data is Map) {
      final msg = data['error'] ?? data['message'];
      if (msg is String && msg.isNotEmpty) return msg;
    } else if (data is String && data.isNotEmpty && data.length < 200) {
      return data;
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return 'Connexion impossible. Vérifiez votre réseau.';
    }
    return parDefaut;
  }
}
