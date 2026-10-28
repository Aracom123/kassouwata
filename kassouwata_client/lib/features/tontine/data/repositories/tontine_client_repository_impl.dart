import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/demande_entity.dart';
import '../../domain/repositories/tontine_client_repository.dart';
import '../datasources/tontine_client_datasource.dart';
import '../models/tontine_client_models.dart';

class TontineClientRepositoryImpl implements TontineClientRepository {
  final TontineClientDataSource _remote;
  TontineClientRepositoryImpl(this._remote);

  @override
  Future<Either<Failure, List<DemandeAdhesionEntity>>> getMyInvitations(
      String telephone) async {
    try {
      // Rattachées au compte côté serveur : un changement de numéro ne fait
      // plus perdre les invitations ni les tontines rejointes.
      final mine = await _remote.getMesDemandes();
      return Right(mine);
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Erreur réseau'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> respondToInvitation(
      int idDemande, DemandeStatus response) async {
    try {
      final statutStr =
          response == DemandeStatus.acceptee ? 'ACCEPTEE' : 'REFUSEE';
      await _remote.updateDemande(
          idDemande, {'idDemandeAdhesion': idDemande, 'statut': statutStr});
      return const Right(null);
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        return const Left(
          ServerFailure('Vous n\'êtes pas autorisé à répondre à cette invitation.'),
        );
      }
      final data = e.response?.data;
      String? serverMsg;
      if (data is Map) {
        serverMsg = data['message'] as String? ?? data['error'] as String?;
      }
      return Left(ServerFailure(serverMsg ?? e.message ?? 'Erreur réseau'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<PeriodeVersementEntity>>> getPeriodes(
      int idTontine) async {
    try {
      final all = await _remote.getAllPeriodes();
      final filtered =
          all.where((p) => p.idTontine == idTontine).toList();
      return Right(filtered);
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Erreur réseau'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, TontineVersementEntity>> sendVersement({
    required int idPeriode,
    required double montant,
    required String membreTelephone,
    required String membreIdUser,
  }) async {
    try {
      final model = TontineVersementModel(
        idTontineVersement: '',
        idTontinePeriodeVersement: idPeriode,
        montant: montant,
        membreTelephone: membreTelephone,
        membreIdUser: membreIdUser,
      );
      final result = await _remote.saveVersement(model.toJson());
      return Right(result);
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Erreur réseau'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<TontineEntity>>> getMyTontines(
      String idUser) async {
    try {
      final all = await _remote.getTontines();
      final mine = all.where((t) => t.ownerIdUser == idUser).toList();
      return Right(mine);
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Erreur réseau'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, TontineEntity>> createTontine({
    required String libelle,
    required double montant,
    String? periodicite,
    String? description,
    DateTime? dateDebut,
    DateTime? dateFin,
    required String idUser,
  }) async {
    try {
      final payload = TontineModel.buildPayload(
        libelle: libelle,
        montant: montant,
        periodicite: periodicite,
        description: description,
        dateDebut: dateDebut,
        dateFin: dateFin,
        idUser: idUser,
      );
      final result = await _remote.saveTontine(payload);
      return Right(result);
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Erreur réseau'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, TontineEntity>> getTontineById(int idTontine) async {
    try {
      final result = await _remote.getTontineById(idTontine);
      return Right(result);
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Erreur réseau'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<TontineVersementEntity>>> getAllVersements() async {
    try {
      final all = await _remote.getAllVersements();
      return Right(all);
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Erreur réseau'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<DemandeAdhesionEntity>>> getTontineDemandes(
      int idTontine) async {
    try {
      final all = await _remote.getAllDemandes();
      final filtered =
          all.where((d) => d.idTontine == idTontine).toList();
      return Right(filtered);
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Erreur réseau'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PeriodeVersementEntity>> addPeriode({
    required String libelle,
    required int idTontine,
    DateTime? dateDebut,
    DateTime? dateFin,
    String? beneficiaireIdUser,
  }) async {
    try {
      final payload = PeriodeVersementModel.buildPayload(
        libelle: libelle,
        idTontine: idTontine,
        dateDebut: dateDebut,
        dateFin: dateFin,
        beneficiaireIdUser: beneficiaireIdUser,
      );
      final result = await _remote.savePeriode(payload);
      return Right(result);
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Erreur réseau'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<UserSummaryEntity>>> getUsers() async {
    try {
      final all = await _remote.getUsers();
      return Right(all);
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Erreur réseau'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, DemandeAdhesionEntity>> inviteMembre({
    required int idTontine,
    required String telephone,
  }) async {
    try {
      final payload = {
        'telephone': telephone,
        'statut': 'ENVOYEE',
        'tontine': {'idTontine': idTontine},
      };
      final result = await _remote.saveDemande(payload);
      return Right(result);
    } on DioException catch (e) {
      final data = e.response?.data;
      String? serverMsg;
      if (data is Map) {
        serverMsg = data['error'] as String? ?? data['message'] as String?;
      }
      return Left(ServerFailure(serverMsg ?? e.message ?? 'Erreur réseau'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
