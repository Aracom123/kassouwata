part of 'tontine_bloc.dart';

abstract class TontineState extends Equatable {
  const TontineState();
  @override
  List<Object?> get props => [];
}

class TontineInitial extends TontineState {}

class TontineLoading extends TontineState {}

class TontinesLoaded extends TontineState {
  final List<TontineEntity> tontines;
  const TontinesLoaded(this.tontines);
  @override
  List<Object?> get props => [tontines];
}

class TontinesFullLoaded extends TontineState {
  final List<TontineEntity> myTontines;
  final List<TontineEntity> joinedTontines;
  const TontinesFullLoaded({
    required this.myTontines,
    required this.joinedTontines,
  });
  @override
  List<Object?> get props => [myTontines, joinedTontines];
}

class PeriodesLoaded extends TontineState {
  final List<PeriodeVersementEntity> periodes;
  const PeriodesLoaded(this.periodes);
  @override
  List<Object?> get props => [periodes];
}

class VersementsLoaded extends TontineState {
  final List<TontineVersementEntity> versements;
  const VersementsLoaded(this.versements);
  @override
  List<Object?> get props => [versements];
}

class DemandesAdhesionLoaded extends TontineState {
  final List<DemandeAdhesionEntity> demandes;
  const DemandesAdhesionLoaded(this.demandes);
  @override
  List<Object?> get props => [demandes];
}

class TontineOperationSuccess extends TontineState {
  final String message;
  const TontineOperationSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

class VersementCreated extends TontineState {
  const VersementCreated();
}

class TontineFailure extends TontineState {
  final String message;
  const TontineFailure(this.message);
  @override
  List<Object?> get props => [message];
}
