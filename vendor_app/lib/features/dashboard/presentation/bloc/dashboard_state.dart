part of 'dashboard_bloc.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();
  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final String boutiqueName;
  final String userName;
  final int nbCommandes;
  final int nbCommandesEnAttente;
  final int nbProduits;
  final int nbProduitsActifs;
  final int nbTontines;
  final double revenuTotal;

  const DashboardLoaded({
    required this.boutiqueName,
    required this.userName,
    required this.nbCommandes,
    required this.nbCommandesEnAttente,
    required this.nbProduits,
    required this.nbProduitsActifs,
    required this.nbTontines,
    required this.revenuTotal,
  });

  @override
  List<Object?> get props => [
        boutiqueName,
        nbCommandes,
        nbProduits,
        nbTontines,
        revenuTotal,
      ];
}

class DashboardFailure extends DashboardState {
  final String message;
  const DashboardFailure(this.message);
  @override
  List<Object?> get props => [message];
}
