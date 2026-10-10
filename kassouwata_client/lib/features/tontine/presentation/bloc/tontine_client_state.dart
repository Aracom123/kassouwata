part of 'tontine_client_bloc.dart';

enum TontineLoadStatus { initial, loading, success, failure }

class TontineClientState extends Equatable {
  final TontineLoadStatus invitationsStatus;
  final TontineLoadStatus periodesStatus;
  final TontineLoadStatus versementStatus;
  final TontineLoadStatus myTontinesStatus;
  final TontineLoadStatus createTontineStatus;
  final TontineLoadStatus tontineDemandesStatus;
  final TontineLoadStatus addPeriodeStatus;
  final TontineLoadStatus currentTontineStatus;
  final TontineLoadStatus allVersementsStatus;
  final TontineLoadStatus usersStatus;
  final TontineLoadStatus inviteMembreStatus;
  final List<DemandeAdhesionEntity> invitations;
  final List<PeriodeVersementEntity> periodes;
  final List<TontineEntity> myTontines;
  final List<DemandeAdhesionEntity> tontineDemandes;
  final List<TontineVersementEntity> allVersements;
  final List<UserSummaryEntity> users;
  final TontineEntity? currentTontine;
  final String? errorMessage;

  const TontineClientState({
    this.invitationsStatus = TontineLoadStatus.initial,
    this.periodesStatus = TontineLoadStatus.initial,
    this.versementStatus = TontineLoadStatus.initial,
    this.myTontinesStatus = TontineLoadStatus.initial,
    this.createTontineStatus = TontineLoadStatus.initial,
    this.tontineDemandesStatus = TontineLoadStatus.initial,
    this.addPeriodeStatus = TontineLoadStatus.initial,
    this.currentTontineStatus = TontineLoadStatus.initial,
    this.allVersementsStatus = TontineLoadStatus.initial,
    this.usersStatus = TontineLoadStatus.initial,
    this.inviteMembreStatus = TontineLoadStatus.initial,
    this.invitations = const [],
    this.periodes = const [],
    this.myTontines = const [],
    this.tontineDemandes = const [],
    this.allVersements = const [],
    this.users = const [],
    this.currentTontine,
    this.errorMessage,
  });

  TontineClientState copyWith({
    TontineLoadStatus? invitationsStatus,
    TontineLoadStatus? periodesStatus,
    TontineLoadStatus? versementStatus,
    TontineLoadStatus? myTontinesStatus,
    TontineLoadStatus? createTontineStatus,
    TontineLoadStatus? tontineDemandesStatus,
    TontineLoadStatus? addPeriodeStatus,
    TontineLoadStatus? currentTontineStatus,
    TontineLoadStatus? allVersementsStatus,
    TontineLoadStatus? usersStatus,
    TontineLoadStatus? inviteMembreStatus,
    List<DemandeAdhesionEntity>? invitations,
    List<PeriodeVersementEntity>? periodes,
    List<TontineEntity>? myTontines,
    List<DemandeAdhesionEntity>? tontineDemandes,
    List<TontineVersementEntity>? allVersements,
    List<UserSummaryEntity>? users,
    TontineEntity? currentTontine,
    String? errorMessage,
  }) =>
      TontineClientState(
        invitationsStatus: invitationsStatus ?? this.invitationsStatus,
        periodesStatus: periodesStatus ?? this.periodesStatus,
        versementStatus: versementStatus ?? this.versementStatus,
        myTontinesStatus: myTontinesStatus ?? this.myTontinesStatus,
        createTontineStatus: createTontineStatus ?? this.createTontineStatus,
        tontineDemandesStatus:
            tontineDemandesStatus ?? this.tontineDemandesStatus,
        addPeriodeStatus: addPeriodeStatus ?? this.addPeriodeStatus,
        currentTontineStatus:
            currentTontineStatus ?? this.currentTontineStatus,
        allVersementsStatus: allVersementsStatus ?? this.allVersementsStatus,
        usersStatus: usersStatus ?? this.usersStatus,
        inviteMembreStatus: inviteMembreStatus ?? this.inviteMembreStatus,
        invitations: invitations ?? this.invitations,
        periodes: periodes ?? this.periodes,
        myTontines: myTontines ?? this.myTontines,
        tontineDemandes: tontineDemandes ?? this.tontineDemandes,
        allVersements: allVersements ?? this.allVersements,
        users: users ?? this.users,
        currentTontine: currentTontine ?? this.currentTontine,
        errorMessage: errorMessage ?? this.errorMessage,
      );

  @override
  List<Object?> get props => [
        invitationsStatus,
        periodesStatus,
        versementStatus,
        myTontinesStatus,
        createTontineStatus,
        tontineDemandesStatus,
        addPeriodeStatus,
        currentTontineStatus,
        allVersementsStatus,
        usersStatus,
        inviteMembreStatus,
        invitations,
        periodes,
        myTontines,
        tontineDemandes,
        allVersements,
        users,
        currentTontine,
        errorMessage,
      ];
}
