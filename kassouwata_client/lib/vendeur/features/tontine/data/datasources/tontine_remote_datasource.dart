import 'package:injectable/injectable.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../models/save_tontine_model.dart';
import '../models/tontine_model.dart';

abstract class TontineRemoteDataSource {
  // Tontines
  Future<List<TontineModel>> getTontines();
  Future<void> saveTontine(SaveTontineModel request);
  Future<void> updateTontine(int id, SaveTontineModel request);
  Future<void> deleteTontine(int id);

  // Périodes — filtrées côté client par idTontine
  Future<List<PeriodeVersementModel>> getPeriodes();
  Future<void> savePeriode(SavePeriodeModel request);
  Future<void> updatePeriode(int idPeriode, SavePeriodeModel request);
  Future<void> deletePeriode(int idPeriode);

  // Versements — filtrés côté client par idTontinePeriodeVersement
  Future<List<TontineVersementModel>> getVersements();
  Future<void> saveVersement(Map<String, dynamic> body);
  Future<void> deleteVersement(String idVersement);

  // Demandes d'adhésion — filtrées côté client par idTontine
  Future<List<DemandeAdhesionModel>> getDemandesAdhesion();
  Future<void> saveDemandeAdhesion(Map<String, dynamic> body);
  Future<void> updateDemandeAdhesion(int id, Map<String, dynamic> body);
  Future<void> deleteDemandeAdhesion(int id);
}

@Injectable(as: TontineRemoteDataSource)
class TontineRemoteDataSourceImpl implements TontineRemoteDataSource {
  final DioClient _dioClient;
  const TontineRemoteDataSourceImpl(this._dioClient);

  // ── Helpers ──────────────────────────────────────────────────────────────

  /// Extrait la liste depuis une réponse paginée (Page<T>) ou une liste directe.
  List _extractList(dynamic data) {
    if (data is Map) return (data['content'] as List?) ?? [];
    if (data is List) return data;
    return [];
  }

  // ── Tontines ─────────────────────────────────────────────────────────────

  @override
  Future<List<TontineModel>> getTontines() async {
    final response = await _dioClient.dio.get(ApiEndpoints.tontines);
    return _extractList(response.data)
        .map((e) => TontineModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> saveTontine(SaveTontineModel request) async {
    await _dioClient.dio
        .post(ApiEndpoints.saveTontine, data: request.toJson());
  }

  @override
  Future<void> updateTontine(int id, SaveTontineModel request) async {
    await _dioClient.dio
        .put(ApiEndpoints.updateTontineById(id), data: request.toJson());
  }

  @override
  Future<void> deleteTontine(int id) async {
    await _dioClient.dio.delete(ApiEndpoints.deleteTontineById(id));
  }

  // ── Périodes ─────────────────────────────────────────────────────────────

  @override
  Future<List<PeriodeVersementModel>> getPeriodes() async {
    final response = await _dioClient.dio.get(ApiEndpoints.periodes);
    return _extractList(response.data)
        .map((e) => PeriodeVersementModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> savePeriode(SavePeriodeModel request) async {
    await _dioClient.dio
        .post(ApiEndpoints.savePeriode, data: request.toJson());
  }

  @override
  Future<void> updatePeriode(int idPeriode, SavePeriodeModel request) async {
    await _dioClient.dio.put(
        ApiEndpoints.updatePeriodeById(idPeriode),
        data: request.toJson());
  }

  @override
  Future<void> deletePeriode(int idPeriode) async {
    await _dioClient.dio.delete(ApiEndpoints.deletePeriodeById(idPeriode));
  }

  // ── Versements ───────────────────────────────────────────────────────────

  @override
  Future<List<TontineVersementModel>> getVersements() async {
    final response = await _dioClient.dio.get(ApiEndpoints.versements);
    return _extractList(response.data)
        .map((e) => TontineVersementModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> saveVersement(Map<String, dynamic> body) async {
    await _dioClient.dio.post(ApiEndpoints.saveVersement, data: body);
  }

  @override
  Future<void> deleteVersement(String idVersement) async {
    await _dioClient.dio
        .delete(ApiEndpoints.deleteVersementById(idVersement));
  }

  // ── Demandes d'adhésion ──────────────────────────────────────────────────

  @override
  Future<List<DemandeAdhesionModel>> getDemandesAdhesion() async {
    final response =
        await _dioClient.dio.get(ApiEndpoints.demandesAdhesion);
    return _extractList(response.data)
        .map((e) =>
            DemandeAdhesionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> saveDemandeAdhesion(Map<String, dynamic> body) async {
    await _dioClient.dio
        .post(ApiEndpoints.saveDemandeAdhesion, data: body);
  }

  @override
  Future<void> updateDemandeAdhesion(
      int id, Map<String, dynamic> body) async {
    await _dioClient.dio
        .put(ApiEndpoints.updateDemandeAdhesionById(id), data: body);
  }

  @override
  Future<void> deleteDemandeAdhesion(int id) async {
    await _dioClient.dio
        .delete(ApiEndpoints.deleteDemandeAdhesionById(id));
  }
}
