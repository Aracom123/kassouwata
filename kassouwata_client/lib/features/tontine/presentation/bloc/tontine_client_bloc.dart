import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/demande_entity.dart';
import '../../domain/repositories/tontine_client_repository.dart';

part 'tontine_client_event.dart';
part 'tontine_client_state.dart';

class TontineClientBloc
    extends Bloc<TontineClientEvent, TontineClientState> {
  final TontineClientRepository _repository;

  TontineClientBloc(this._repository) : super(const TontineClientState()) {
    on<LoadMyInvitations>(_onLoadInvitations);
    on<RespondToInvitation>(_onRespond);
    on<LoadPeriodes>(_onLoadPeriodes);
    on<SendVersement>(_onSendVersement);
    on<LoadMyTontines>(_onLoadMyTontines);
    on<CreateTontine>(_onCreateTontine);
    on<LoadTontineDemandes>(_onLoadTontineDemandes);
    on<AddPeriode>(_onAddPeriode);
    on<LoadCurrentTontine>(_onLoadCurrentTontine);
    on<LoadAllVersements>(_onLoadAllVersements);
    on<LoadUsers>(_onLoadUsers);
    on<InviteMembre>(_onInviteMembre);
  }

  Future<void> _onLoadInvitations(
      LoadMyInvitations event, Emitter<TontineClientState> emit) async {
    emit(state.copyWith(invitationsStatus: TontineLoadStatus.loading));
    final result = await _repository.getMyInvitations(event.telephone);
    result.fold(
      (f) => emit(state.copyWith(
          invitationsStatus: TontineLoadStatus.failure,
          errorMessage: f.message)),
      (invitations) => emit(state.copyWith(
          invitationsStatus: TontineLoadStatus.success,
          invitations: invitations)),
    );
  }

  Future<void> _onRespond(
      RespondToInvitation event, Emitter<TontineClientState> emit) async {
    final result = await _repository.respondToInvitation(
        event.idDemande, event.response);
    result.fold(
      (f) => emit(
          state.copyWith(errorMessage: f.message)),
      (_) {
        // Update local list
        final updated = state.invitations.map((d) {
          if (d.idDemandeAdhesion == event.idDemande) {
            return DemandeAdhesionEntity(
              idDemandeAdhesion: d.idDemandeAdhesion,
              telephone: d.telephone,
              dateEnvoi: d.dateEnvoi,
              statut: event.response,
              idTontine: d.idTontine,
              tontineLibelle: d.tontineLibelle,
            );
          }
          return d;
        }).toList();
        emit(state.copyWith(invitations: updated));
      },
    );
  }

  Future<void> _onLoadPeriodes(
      LoadPeriodes event, Emitter<TontineClientState> emit) async {
    emit(state.copyWith(periodesStatus: TontineLoadStatus.loading));
    final result = await _repository.getPeriodes(event.idTontine);
    result.fold(
      (f) => emit(state.copyWith(
          periodesStatus: TontineLoadStatus.failure,
          errorMessage: f.message)),
      (periodes) => emit(state.copyWith(
          periodesStatus: TontineLoadStatus.success, periodes: periodes)),
    );
  }

  Future<void> _onSendVersement(
      SendVersement event, Emitter<TontineClientState> emit) async {
    emit(state.copyWith(versementStatus: TontineLoadStatus.loading));
    final result = await _repository.sendVersement(
      idPeriode: event.idPeriode,
      montant: event.montant,
      membreTelephone: event.membreTelephone,
      membreIdUser: event.membreIdUser,
    );
    result.fold(
      (f) => emit(state.copyWith(
          versementStatus: TontineLoadStatus.failure,
          errorMessage: f.message)),
      (versement) => emit(state.copyWith(
          versementStatus: TontineLoadStatus.success,
          allVersements: [...state.allVersements, versement])),
    );
  }

  Future<void> _onLoadMyTontines(
      LoadMyTontines event, Emitter<TontineClientState> emit) async {
    emit(state.copyWith(myTontinesStatus: TontineLoadStatus.loading));
    final result = await _repository.getMyTontines(event.idUser);
    result.fold(
      (f) => emit(state.copyWith(
          myTontinesStatus: TontineLoadStatus.failure,
          errorMessage: f.message)),
      (tontines) => emit(state.copyWith(
          myTontinesStatus: TontineLoadStatus.success,
          myTontines: tontines)),
    );
  }

  Future<void> _onLoadCurrentTontine(
      LoadCurrentTontine event, Emitter<TontineClientState> emit) async {
    emit(state.copyWith(currentTontineStatus: TontineLoadStatus.loading));
    final result = await _repository.getTontineById(event.idTontine);
    result.fold(
      (f) => emit(state.copyWith(
          currentTontineStatus: TontineLoadStatus.failure,
          errorMessage: f.message)),
      (tontine) => emit(state.copyWith(
          currentTontineStatus: TontineLoadStatus.success,
          currentTontine: tontine)),
    );
  }

  Future<void> _onLoadAllVersements(
      LoadAllVersements event, Emitter<TontineClientState> emit) async {
    emit(state.copyWith(allVersementsStatus: TontineLoadStatus.loading));
    final result = await _repository.getAllVersements();
    result.fold(
      (f) => emit(state.copyWith(
          allVersementsStatus: TontineLoadStatus.failure,
          errorMessage: f.message)),
      (versements) => emit(state.copyWith(
          allVersementsStatus: TontineLoadStatus.success,
          allVersements: versements)),
    );
  }

  Future<void> _onLoadTontineDemandes(
      LoadTontineDemandes event, Emitter<TontineClientState> emit) async {
    emit(state.copyWith(tontineDemandesStatus: TontineLoadStatus.loading));
    final result = await _repository.getTontineDemandes(event.idTontine);
    result.fold(
      (f) => emit(state.copyWith(
          tontineDemandesStatus: TontineLoadStatus.failure,
          errorMessage: f.message)),
      (demandes) => emit(state.copyWith(
          tontineDemandesStatus: TontineLoadStatus.success,
          tontineDemandes: demandes)),
    );
  }

  Future<void> _onAddPeriode(
      AddPeriode event, Emitter<TontineClientState> emit) async {
    emit(state.copyWith(addPeriodeStatus: TontineLoadStatus.loading));
    final result = await _repository.addPeriode(
      libelle: event.libelle,
      idTontine: event.idTontine,
      dateDebut: event.dateDebut,
      dateFin: event.dateFin,
      beneficiaireIdUser: event.beneficiaireIdUser,
    );
    result.fold(
      (f) => emit(state.copyWith(
          addPeriodeStatus: TontineLoadStatus.failure,
          errorMessage: f.message)),
      (periode) => emit(state.copyWith(
          addPeriodeStatus: TontineLoadStatus.success,
          periodes: [...state.periodes, periode])),
    );
  }

  Future<void> _onLoadUsers(
      LoadUsers event, Emitter<TontineClientState> emit) async {
    emit(state.copyWith(usersStatus: TontineLoadStatus.loading));
    final result = await _repository.getUsers();
    result.fold(
      (f) => emit(state.copyWith(
          usersStatus: TontineLoadStatus.failure, errorMessage: f.message)),
      (users) => emit(state.copyWith(
          usersStatus: TontineLoadStatus.success, users: users)),
    );
  }

  Future<void> _onCreateTontine(
      CreateTontine event, Emitter<TontineClientState> emit) async {
    emit(state.copyWith(createTontineStatus: TontineLoadStatus.loading));
    final result = await _repository.createTontine(
      libelle: event.libelle,
      montant: event.montant,
      periodicite: event.periodicite,
      description: event.description,
      dateDebut: event.dateDebut,
      dateFin: event.dateFin,
      idUser: event.idUser,
    );
    result.fold(
      (f) => emit(state.copyWith(
          createTontineStatus: TontineLoadStatus.failure,
          errorMessage: f.message)),
      (tontine) => emit(state.copyWith(
          createTontineStatus: TontineLoadStatus.success,
          myTontines: [tontine, ...state.myTontines])),
    );
  }

  Future<void> _onInviteMembre(
      InviteMembre event, Emitter<TontineClientState> emit) async {
    emit(state.copyWith(inviteMembreStatus: TontineLoadStatus.loading));
    final result = await _repository.inviteMembre(
      idTontine: event.idTontine,
      telephone: event.telephone,
    );
    result.fold(
      (f) => emit(state.copyWith(
          inviteMembreStatus: TontineLoadStatus.failure,
          errorMessage: f.message)),
      (demande) => emit(state.copyWith(
          inviteMembreStatus: TontineLoadStatus.success,
          tontineDemandes: [...state.tontineDemandes, demande])),
    );
  }
}
