import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../models/tontine_client_models.dart';

abstract class TontineClientDataSource {
  Future<List<DemandeAdhesionModel>> getAllDemandes();
  /// Demandes reçues par l'utilisateur connecté (liées à son compte)
  Future<List<DemandeAdhesionModel>> getMesDemandes();
  Future<DemandeAdhesionModel> updateDemande(
      int id, Map<String, dynamic> body);
  Future<DemandeAdhesionModel> saveDemande(Map<String, dynamic> body);
  Future<List<PeriodeVersementModel>> getAllPeriodes();
  Future<TontineVersementModel> saveVersement(Map<String, dynamic> body);
  Future<List<TontineModel>> getTontines();
  Future<TontineModel> getTontineById(int id);
  Future<TontineModel> saveTontine(Map<String, dynamic> body);
  Future<PeriodeVersementModel> savePeriode(Map<String, dynamic> body);
  Future<List<TontineVersementModel>> getAllVersements();
  Future<List<UserSummaryModel>> getUsers();
}

class TontineClientDataSourceImpl implements TontineClientDataSource {
  final DioClient _dio;
  TontineClientDataSourceImpl(this._dio);

  List<T> _parsePageContent<T>(
    dynamic data,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final map = data as Map<String, dynamic>? ?? {};
    final content = map['content'] as List<dynamic>? ?? [];
    return content
        .map((e) => fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<DemandeAdhesionModel>> getAllDemandes() async {
    final response = await _dio.dio.get(
      ApiEndpoints.demandesAdhesion,
      queryParameters: {'size': 1000, 'page': 0},
    );
    return _parsePageContent(
        response.data, DemandeAdhesionModel.fromJson);
  }

  @override
  Future<List<DemandeAdhesionModel>> getMesDemandes() async {
    final response = await _dio.dio.get(ApiEndpoints.mesDemandesAdhesion);
    final data = response.data as List<dynamic>? ?? [];
    return data
        .map((e) => DemandeAdhesionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<DemandeAdhesionModel> updateDemande(
      int id, Map<String, dynamic> body) async {
    final response = await _dio.dio.put(
        ApiEndpoints.updateDemandeAdhesion(id),
        data: body);
    return DemandeAdhesionModel.fromJson(
        response.data as Map<String, dynamic>);
  }

  @override
  Future<DemandeAdhesionModel> saveDemande(Map<String, dynamic> body) async {
    final response = await _dio.dio.post(
      ApiEndpoints.saveDemandeAdhesion,
      data: body,
    );
    return DemandeAdhesionModel.fromJson(
        response.data as Map<String, dynamic>);
  }

  @override
  Future<List<PeriodeVersementModel>> getAllPeriodes() async {
    final response = await _dio.dio.get(
      ApiEndpoints.periodes,
      queryParameters: {'size': 1000, 'page': 0},
    );
    return _parsePageContent(
        response.data, PeriodeVersementModel.fromJson);
  }

  @override
  Future<TontineVersementModel> saveVersement(
      Map<String, dynamic> body) async {
    final response =
        await _dio.dio.post(ApiEndpoints.saveVersement, data: body);
    return TontineVersementModel.fromJson(
        response.data as Map<String, dynamic>);
  }

  @override
  Future<List<TontineModel>> getTontines() async {
    final response = await _dio.dio.get(
      ApiEndpoints.tontines,
      queryParameters: {'size': 1000, 'page': 0},
    );
    return _parsePageContent(response.data, TontineModel.fromJson);
  }

  @override
  Future<TontineModel> saveTontine(Map<String, dynamic> body) async {
    final response =
        await _dio.dio.post(ApiEndpoints.saveTontine, data: body);
    return TontineModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<PeriodeVersementModel> savePeriode(
      Map<String, dynamic> body) async {
    final response =
        await _dio.dio.post(ApiEndpoints.savePeriode, data: body);
    return PeriodeVersementModel.fromJson(
        response.data as Map<String, dynamic>);
  }

  @override
  Future<TontineModel> getTontineById(int id) async {
    final response =
        await _dio.dio.get(ApiEndpoints.tontineById(id));
    return TontineModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<List<TontineVersementModel>> getAllVersements() async {
    final response = await _dio.dio.get(
      ApiEndpoints.versements,
      queryParameters: {'size': 1000, 'page': 0},
    );
    return _parsePageContent(
        response.data, TontineVersementModel.fromJson);
  }

  @override
  Future<List<UserSummaryModel>> getUsers() async {
    final response = await _dio.dio.get(
      ApiEndpoints.users,
      queryParameters: {'size': 1000, 'page': 0},
    );
    final list = (response.data as List<dynamic>?) ?? [];
    return list
        .map((e) => UserSummaryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
