import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/tontine_entity.dart';
import '../../domain/repositories/tontine_repository.dart';
import '../datasources/tontine_remote_datasource.dart';
import '../models/save_tontine_model.dart';

@Injectable(as: TontineRepository)
class TontineRepositoryImpl implements TontineRepository {
  final TontineRemoteDataSource _remoteDataSource;
  const TontineRepositoryImpl(this._remoteDataSource);

  Failure _handleError(Object e) {
    if (e is DioException) {
      if (e.response != null) {
        final msg = e.response?.data?.toString() ?? 'Erreur serveur';
        return ServerFailure(msg, statusCode: e.response?.statusCode);
      }
      return NetworkFailure(e.message ?? 'Erreur réseau');
    }
    return ServerFailure(e.toString());
  }

  // ── Tontines ──────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, List<TontineEntity>>> getTontines() async {
    try {
      final models = await _remoteDataSource.getTontines();
      return Right(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> createTontine({
    required String libelle,
    String? description,
    DateTime? dateDebut,
    DateTime? dateFin,
    required double montant,
    String? periodicite,
    String? ownerIdUser,
  }) async {
    try {
      await _remoteDataSource.saveTontine(SaveTontineModel(
        libelle: libelle,
        description: description,
        dateDebut: dateDebut,
        dateFin: dateFin,
        montant: montant,
        periodicite: periodicite,
        ownerIdUser: ownerIdUser,
      ));
      return const Right(unit);
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateTontine({
    required int idTontine,
    required String libelle,
    String? description,
    DateTime? dateDebut,
    DateTime? dateFin,
    required double montant,
    String? periodicite,
  }) async {
    try {
      await _remoteDataSource.updateTontine(
          idTontine,
          SaveTontineModel(
            libelle: libelle,
            description: description,
            dateDebut: dateDebut,
            dateFin: dateFin,
            montant: montant,
            periodicite: periodicite,
          ));
      return const Right(unit);
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteTontine(int idTontine) async {
    try {
      await _remoteDataSource.deleteTontine(idTontine);
      return const Right(unit);
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  // ── Périodes ──────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, List<PeriodeVersementEntity>>> getPeriodes(
      int idTontine) async {
    try {
      final models = await _remoteDataSource.getPeriodes();
      final filtered = models
          .where((m) => m.idTontine == idTontine)
          .map((m) => m.toEntity())
          .toList();
      return Right(filtered);
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> createPeriode({
    required int idTontine,
    required String libelle,
    DateTime? dateDebut,
    DateTime? dateFin,
    String? beneficiaireUserId,
  }) async {
    try {
      await _remoteDataSource.savePeriode(SavePeriodeModel(
        libelle: libelle,
        dateDebut: dateDebut,
        dateFin: dateFin,
        idTontine: idTontine,
        beneficiaireUserId: beneficiaireUserId,
      ));
      return const Right(unit);
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> updatePeriode({
    required int idTontinePeriodeVersement,
    required int idTontine,
    required String libelle,
    DateTime? dateDebut,
    DateTime? dateFin,
    String? beneficiaireUserId,
  }) async {
    try {
      await _remoteDataSource.updatePeriode(
          idTontinePeriodeVersement,
          SavePeriodeModel(
            libelle: libelle,
            dateDebut: dateDebut,
            dateFin: dateFin,
            idTontine: idTontine,
            beneficiaireUserId: beneficiaireUserId,
          ));
      return const Right(unit);
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> deletePeriode(
      int idTontinePeriodeVersement) async {
    try {
      await _remoteDataSource.deletePeriode(idTontinePeriodeVersement);
      return const Right(unit);
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  // ── Versements ────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, List<TontineVersementEntity>>> getVersements(
      int idTontinePeriodeVersement) async {
    try {
      final models = await _remoteDataSource.getVersements();
      final filtered = models
          .where((m) =>
              m.idTontinePeriodeVersement == idTontinePeriodeVersement)
          .map((m) => m.toEntity())
          .toList();
      return Right(filtered);
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> createVersement({
    required int idPeriode,
    required double montant,
    required String telephone,
    String? idUser,
    required TontineTypePaiement typePaiement,
    required TontineFournisseur fournisseur,
    String? numeroCompte,
    String? numeroCarte,
    String? nomPorteur,
  }) async {
    try {
      await _remoteDataSource.saveVersement({
        'montant': montant,
        'telephone': telephone,
        'typePaiement': typePaiement == TontineTypePaiement.mobileMoney
            ? 'MOBILE_MONEY'
            : 'CARTE_PAIEMENT',
        'fournisseur': fournisseur.apiValue,
        if (idUser != null) 'membre': {'idUser': idUser},
        if (numeroCompte != null && numeroCompte.isNotEmpty)
          'numeroCompte': numeroCompte,
        if (numeroCarte != null && numeroCarte.isNotEmpty)
          'numeroCarte': numeroCarte,
        if (nomPorteur != null && nomPorteur.isNotEmpty)
          'nomPorteur': nomPorteur,
        'tontinePeriodeVersement': {'idTontinePeriodeVersement': idPeriode},
      });
      return const Right(unit);
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  // ── Demandes d'adhésion ───────────────────────────────────────────────────

  @override
  Future<Either<Failure, List<DemandeAdhesionEntity>>> getAllDemandes() async {
    try {
      final models = await _remoteDataSource.getDemandesAdhesion();
      return Right(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  @override
  Future<Either<Failure, List<DemandeAdhesionEntity>>> getDemandesAdhesion(
      int idTontine) async {
    try {
      final models = await _remoteDataSource.getDemandesAdhesion();
      final filtered = models
          .where((m) => m.idTontine == idTontine)
          .map((m) => m.toEntity())
          .toList();
      return Right(filtered);
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> createDemandeAdhesion({
    required int idTontine,
    required String telephone,
  }) async {
    try {
      await _remoteDataSource.saveDemandeAdhesion({
        'telephone': telephone,
        'tontine': {'idTontine': idTontine},
      });
      return const Right(unit);
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateStatutDemande({
    required int idDemandeAdhesion,
    required DemandeAdhesionStatus statut,
  }) async {
    try {
      final statutStr = statut.name.toUpperCase();
      await _remoteDataSource.updateDemandeAdhesion(
          idDemandeAdhesion, {'statut': statutStr});
      return const Right(unit);
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteDemandeAdhesion(
      int idDemandeAdhesion) async {
    try {
      await _remoteDataSource.deleteDemandeAdhesion(idDemandeAdhesion);
      return const Right(unit);
    } catch (e) {
      return Left(_handleError(e));
    }
  }
}
