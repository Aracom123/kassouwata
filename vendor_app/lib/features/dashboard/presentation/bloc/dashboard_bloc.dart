import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../features/auth/data/datasources/auth_local_datasource.dart';
import '../../../../features/orders/domain/entities/order_entity.dart';
import '../../../../features/orders/domain/repositories/order_repository.dart';
import '../../../../features/products/data/datasources/product_remote_datasource.dart';
import '../../../../features/tontine/data/datasources/tontine_remote_datasource.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';

@injectable
class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final OrderRepository _orderRepository;
  final ProductRemoteDataSource _productDataSource;
  final TontineRemoteDataSource _tontineDataSource;
  final AuthLocalDataSource _localDataSource;

  DashboardBloc(
    this._orderRepository,
    this._productDataSource,
    this._tontineDataSource,
    this._localDataSource,
  ) : super(DashboardInitial()) {
    on<LoadDashboard>(_onLoad);
  }

  Future<void> _onLoad(LoadDashboard event, Emitter<DashboardState> emit) async {
    emit(DashboardLoading());
    try {
      final boutique = await _localDataSource.getCachedBoutique();
      final user = await _localDataSource.getCachedUser();

      if (boutique == null) {
        emit(const DashboardFailure('Boutique introuvable. Reconnectez-vous.'));
        return;
      }

      // Chargement parallèle
      final ordersF = _orderRepository.getOrdersByShop(boutique.idBoutique);
      final productsF = _productDataSource.getProductsByBoutique(boutique.idBoutique);
      final tontinesF = _tontineDataSource.getTontines();

      final ordersEither = await ordersF;
      final products = await productsF;
      final tontines = await tontinesF;

      final orders = ordersEither.fold<List<OrderEntity>>((_) => [], (list) => list);

      // Revenu = somme des lignes (quantite × prixUnitaire) des commandes LIVRÉES
      double revenu = 0;
      for (final order in orders) {
        if (order.statut.toUpperCase() == 'LIVREE') {
          for (final ligne in order.lignesPourBoutique(boutique.idBoutique)) {
            revenu += ligne.sousTotal;
          }
        }
      }

      final nbEnAttente = orders
          .where((o) => o.statut.toUpperCase() == 'EN_ATTENTE')
          .length;

      final nbProduitsActifs = products
          .where((p) => p.statut == true)
          .length;

      final prenom = user?.personne?.prenom;
      final nom = user?.personne?.nom;
      final userName = (prenom != null || nom != null)
          ? '${prenom ?? ''} ${nom ?? ''}'.trim()
          : user?.telephone ?? '';

      emit(DashboardLoaded(
        boutiqueName: boutique.libelle,
        userName: userName,
        nbCommandes: orders.length,
        nbCommandesEnAttente: nbEnAttente,
        nbProduits: products.length,
        nbProduitsActifs: nbProduitsActifs,
        nbTontines: tontines.length,
        revenuTotal: revenu,
      ));
    } catch (e) {
      emit(DashboardFailure(e.toString()));
    }
  }
}

