import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/tontine_entity.dart';
import '../../domain/repositories/tontine_repository.dart';

part 'tontine_event.dart';
part 'tontine_state.dart';

@injectable
class TontineBloc extends Bloc<TontineEvent, TontineState> {
  final TontineRepository _repository;

  TontineBloc(this._repository) : super(TontineInitial()) {
    on<LoadTontines>(_onLoadTontines);
    on<LoadTontinesFull>(_onLoadTontinesFull);
    on<CreateTontine>(_onCreateTontine);
    on<UpdateTontine>(_onUpdateTontine);
    on<DeleteTontine>(_onDeleteTontine);
    on<LoadPeriodes>(_onLoadPeriodes);
    on<CreatePeriode>(_onCreatePeriode);
    on<UpdatePeriode>(_onUpdatePeriode);
    on<DeletePeriode>(_onDeletePeriode);
    on<LoadVersements>(_onLoadVersements);
    on<CreateVersement>(_onCreateVersement);
    on<LoadDemandesAdhesion>(_onLoadDemandesAdhesion);
    on<CreateDemandeAdhesion>(_onCreateDemandeAdhesion);
    on<UpdateStatutDemande>(_onUpdateStatutDemande);
    on<DeleteDemandeAdhesion>(_onDeleteDemandeAdhesion);
  }

  Future<void> _onLoadTontines(
      LoadTontines event, Emitter<TontineState> emit) async {
    emit(TontineLoading());
    final result = await _repository.getTontines();
    result.fold(
      (f) => emit(TontineFailure(f.message)),
      (list) => emit(TontinesLoaded(list)),
    );
  }

  Future<void> _onCreateTontine(
      CreateTontine event, Emitter<TontineState> emit) async {
    emit(TontineLoading());
    final result = await _repository.createTontine(
      libelle: event.libelle,
      description: event.description,
      dateDebut: event.dateDebut,
      dateFin: event.dateFin,
      montant: event.montant,
      periodicite: event.periodicite,
      ownerIdUser: event.ownerIdUser,
    );
    result.fold(
      (f) => emit(TontineFailure(f.message)),
      (_) => emit(const TontineOperationSuccess('Tontine créée avec succès')),
    );
  }

  Future<void> _onUpdateTontine(
      UpdateTontine event, Emitter<TontineState> emit) async {
    emit(TontineLoading());
    final result = await _repository.updateTontine(
      idTontine: event.idTontine,
      libelle: event.libelle,
      description: event.description,
      dateDebut: event.dateDebut,
      dateFin: event.dateFin,
      montant: event.montant,
      periodicite: event.periodicite,
    );
    result.fold(
      (f) => emit(TontineFailure(f.message)),
      (_) =>
          emit(const TontineOperationSuccess('Tontine mise à jour avec succès')),
    );
  }

  Future<void> _onDeleteTontine(
      DeleteTontine event, Emitter<TontineState> emit) async {
    emit(TontineLoading());
    final result = await _repository.deleteTontine(event.idTontine);
    result.fold(
      (f) => emit(TontineFailure(f.message)),
      (_) => emit(const TontineOperationSuccess('Tontine supprimée')),
    );
  }

  Future<void> _onLoadPeriodes(
      LoadPeriodes event, Emitter<TontineState> emit) async {
    emit(TontineLoading());
    final result = await _repository.getPeriodes(event.idTontine);
    result.fold(
      (f) => emit(TontineFailure(f.message)),
      (list) => emit(PeriodesLoaded(list)),
    );
  }

  Future<void> _onCreatePeriode(
      CreatePeriode event, Emitter<TontineState> emit) async {
    emit(TontineLoading());
    final result = await _repository.createPeriode(
      idTontine: event.idTontine,
      libelle: event.libelle,
      dateDebut: event.dateDebut,
      dateFin: event.dateFin,
      beneficiaireUserId: event.beneficiaireUserId,
    );
    result.fold(
      (f) => emit(TontineFailure(f.message)),
      (_) => emit(const TontineOperationSuccess('Période créée avec succès')),
    );
  }

  Future<void> _onUpdatePeriode(
      UpdatePeriode event, Emitter<TontineState> emit) async {
    emit(TontineLoading());
    final result = await _repository.updatePeriode(
      idTontinePeriodeVersement: event.idTontinePeriodeVersement,
      idTontine: event.idTontine,
      libelle: event.libelle,
      dateDebut: event.dateDebut,
      dateFin: event.dateFin,
      beneficiaireUserId: event.beneficiaireUserId,
    );
    result.fold(
      (f) => emit(TontineFailure(f.message)),
      (_) =>
          emit(const TontineOperationSuccess('Période mise à jour avec succès')),
    );
  }

  Future<void> _onDeletePeriode(
      DeletePeriode event, Emitter<TontineState> emit) async {
    emit(TontineLoading());
    final result =
        await _repository.deletePeriode(event.idTontinePeriodeVersement);
    result.fold(
      (f) => emit(TontineFailure(f.message)),
      (_) => emit(const TontineOperationSuccess('Période supprimée')),
    );
  }

  Future<void> _onLoadVersements(
      LoadVersements event, Emitter<TontineState> emit) async {
    emit(TontineLoading());
    final result =
        await _repository.getVersements(event.idTontinePeriodeVersement);
    result.fold(
      (f) => emit(TontineFailure(f.message)),
      (list) => emit(VersementsLoaded(list)),
    );
  }

  Future<void> _onLoadTontinesFull(
      LoadTontinesFull event, Emitter<TontineState> emit) async {
    emit(TontineLoading());
    final tontinesResult = await _repository.getTontines();
    final demandesResult = await _repository.getAllDemandes();

    tontinesResult.fold(
      (f) => emit(TontineFailure(f.message)),
      (tontines) {
        final demandes = demandesResult.getOrElse(() => []);

        final myTontines = tontines
            .where((t) => t.tontineOwnerTelephone == event.userTelephone)
            .toList();

        final acceptedIds = demandes
            .where((d) =>
                d.telephone == event.userTelephone &&
                d.statut == DemandeAdhesionStatus.acceptee)
            .map((d) => d.idTontine)
            .whereType<int>()
            .toSet();

        final joinedTontines = tontines
            .where((t) =>
                acceptedIds.contains(t.idTontine) &&
                t.tontineOwnerTelephone != event.userTelephone)
            .toList();

        emit(TontinesFullLoaded(
          myTontines: myTontines,
          joinedTontines: joinedTontines,
        ));
      },
    );
  }

  Future<void> _onCreateVersement(
      CreateVersement event, Emitter<TontineState> emit) async {
    emit(TontineLoading());
    final result = await _repository.createVersement(
      idPeriode: event.idPeriode,
      montant: event.montant,
      telephone: event.telephone,
      idUser: event.idUser,
      typePaiement: event.typePaiement,
      fournisseur: event.fournisseur,
      numeroCompte: event.numeroCompte,
      numeroCarte: event.numeroCarte,
      nomPorteur: event.nomPorteur,
    );
    result.fold(
      (f) => emit(TontineFailure(f.message)),
      (_) => emit(const VersementCreated()),
    );
  }

  Future<void> _onLoadDemandesAdhesion(
      LoadDemandesAdhesion event, Emitter<TontineState> emit) async {
    emit(TontineLoading());
    final result = await _repository.getDemandesAdhesion(event.idTontine);
    result.fold(
      (f) => emit(TontineFailure(f.message)),
      (list) => emit(DemandesAdhesionLoaded(list)),
    );
  }

  Future<void> _onCreateDemandeAdhesion(
      CreateDemandeAdhesion event, Emitter<TontineState> emit) async {
    emit(TontineLoading());
    final result = await _repository.createDemandeAdhesion(
      idTontine: event.idTontine,
      telephone: event.telephone,
    );
    result.fold(
      (f) => emit(TontineFailure(f.message)),
      (_) => emit(
          const TontineOperationSuccess('Invitation envoyée avec succès')),
    );
  }

  Future<void> _onUpdateStatutDemande(
      UpdateStatutDemande event, Emitter<TontineState> emit) async {
    emit(TontineLoading());
    final result = await _repository.updateStatutDemande(
      idDemandeAdhesion: event.idDemandeAdhesion,
      statut: event.statut,
    );
    result.fold(
      (f) => emit(TontineFailure(f.message)),
      (_) =>
          emit(const TontineOperationSuccess('Statut mis à jour avec succès')),
    );
  }

  Future<void> _onDeleteDemandeAdhesion(
      DeleteDemandeAdhesion event, Emitter<TontineState> emit) async {
    emit(TontineLoading());
    final result =
        await _repository.deleteDemandeAdhesion(event.idDemandeAdhesion);
    result.fold(
      (f) => emit(TontineFailure(f.message)),
      (_) => emit(const TontineOperationSuccess('Invitation supprimée')),
    );
  }
}
