import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/demande_entity.dart';

abstract class TontineClientRepository {
  /// Invitations reçues sur le numéro de l'utilisateur
  Future<Either<Failure, List<DemandeAdhesionEntity>>> getMyInvitations(
      String telephone);

  /// Accepter ou refuser une invitation
  Future<Either<Failure, void>> respondToInvitation(
      int idDemande, DemandeStatus response);

  /// Périodes de versement d'une tontine
  Future<Either<Failure, List<PeriodeVersementEntity>>> getPeriodes(
      int idTontine);

  /// Envoyer une cotisation
  Future<Either<Failure, TontineVersementEntity>> sendVersement({
    required int idPeriode,
    required double montant,
    required String membreTelephone,
    required String membreIdUser,
  });

  /// Tontines créées par l'utilisateur
  Future<Either<Failure, List<TontineEntity>>> getMyTontines(String idUser);

  /// Créer une nouvelle tontine
  Future<Either<Failure, TontineEntity>> createTontine({
    required String libelle,
    required double montant,
    String? periodicite,
    String? description,
    DateTime? dateDebut,
    DateTime? dateFin,
    required String idUser,
  });

  /// Tontine par identifiant
  Future<Either<Failure, TontineEntity>> getTontineById(int idTontine);

  /// Tous les versements (cotisations effectuées)
  Future<Either<Failure, List<TontineVersementEntity>>> getAllVersements();

  /// Demandes d'adhésion pour une tontine donnée (vue propriétaire)
  Future<Either<Failure, List<DemandeAdhesionEntity>>> getTontineDemandes(
      int idTontine);

  /// Ajouter une période de versement à une tontine
  Future<Either<Failure, PeriodeVersementEntity>> addPeriode({
    required String libelle,
    required int idTontine,
    DateTime? dateDebut,
    DateTime? dateFin,
    String? beneficiaireIdUser,
  });

  /// Liste de tous les utilisateurs (pour afficher noms/prénoms)
  Future<Either<Failure, List<UserSummaryEntity>>> getUsers();

  /// Inviter un membre à rejoindre une tontine (par numéro de téléphone)
  Future<Either<Failure, DemandeAdhesionEntity>> inviteMembre({
    required int idTontine,
    required String telephone,
  });
}
