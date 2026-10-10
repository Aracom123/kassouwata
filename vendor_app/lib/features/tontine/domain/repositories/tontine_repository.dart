import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/tontine_entity.dart';

abstract class TontineRepository {
  // ── Tontines ──────────────────────────────────────────────────────────────

  Future<Either<Failure, List<TontineEntity>>> getTontines();

  Future<Either<Failure, Unit>> createTontine({
    required String libelle,
    String? description,
    DateTime? dateDebut,
    DateTime? dateFin,
    required double montant,
    String? periodicite,
    String? ownerIdUser,
  });

  Future<Either<Failure, Unit>> updateTontine({
    required int idTontine,
    required String libelle,
    String? description,
    DateTime? dateDebut,
    DateTime? dateFin,
    required double montant,
    String? periodicite,
  });

  Future<Either<Failure, Unit>> deleteTontine(int idTontine);

  // ── Périodes ──────────────────────────────────────────────────────────────

  /// Récupère toutes les périodes et filtre par [idTontine] côté client.
  Future<Either<Failure, List<PeriodeVersementEntity>>> getPeriodes(
      int idTontine);

  Future<Either<Failure, Unit>> createPeriode({
    required int idTontine,
    required String libelle,
    DateTime? dateDebut,
    DateTime? dateFin,
    String? beneficiaireUserId,
  });

  Future<Either<Failure, Unit>> updatePeriode({
    required int idTontinePeriodeVersement,
    required int idTontine,
    required String libelle,
    DateTime? dateDebut,
    DateTime? dateFin,
    String? beneficiaireUserId,
  });

  Future<Either<Failure, Unit>> deletePeriode(int idTontinePeriodeVersement);

  // ── Versements ────────────────────────────────────────────────────────────

  /// Récupère tous les versements et filtre par [idTontinePeriodeVersement] côté client.
  Future<Either<Failure, List<TontineVersementEntity>>> getVersements(
      int idTontinePeriodeVersement);

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
  });

  // ── Demandes d'adhésion ───────────────────────────────────────────────────

  /// Récupère toutes les demandes sans filtre.
  Future<Either<Failure, List<DemandeAdhesionEntity>>> getAllDemandes();

  /// Récupère toutes les demandes et filtre par [idTontine] côté client.
  Future<Either<Failure, List<DemandeAdhesionEntity>>> getDemandesAdhesion(
      int idTontine);

  Future<Either<Failure, Unit>> createDemandeAdhesion({
    required int idTontine,
    required String telephone,
  });

  Future<Either<Failure, Unit>> updateStatutDemande({
    required int idDemandeAdhesion,
    required DemandeAdhesionStatus statut,
  });

  Future<Either<Failure, Unit>> deleteDemandeAdhesion(
      int idDemandeAdhesion);
}
