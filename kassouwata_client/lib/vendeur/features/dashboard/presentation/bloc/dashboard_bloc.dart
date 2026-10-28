import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../features/auth/data/datasources/auth_local_datasource.dart';
import '../../../../features/orders/domain/entities/order_entity.dart';
import '../../../../features/orders/domain/repositories/order_repository.dart';
import '../../../../features/products/data/datasources/product_remote_datasource.dart';
import '../../../../../core/storage/secure_storage.dart';
import '../../../../../features/tontine/domain/entities/demande_entity.dart';
import '../../../../../features/tontine/domain/repositories/tontine_client_repository.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';

@injectable
class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final OrderRepository _orderRepository;
  final ProductRemoteDataSource _productDataSource;
  final TontineClientRepository _tontineRepository;
  final AuthLocalDataSource _localDataSource;
  final SecureStorage _storage;

  DashboardBloc(
    this._orderRepository,
    this._productDataSource,
    this._tontineRepository,
    this._localDataSource,
    this._storage,
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
      // Mêmes règles que la page Tontines : tontines créées par l'utilisateur
      // + tontines rejointes (invitation acceptée), et non toutes les tontines.
      final idUser = await _storage.getUserId() ?? user?.idUser ?? '';
      final creeesF = _tontineRepository.getMyTontines(idUser);
      final demandesF = _tontineRepository.getMyInvitations('');

      final ordersEither = await ordersF;
      final products = await productsF;
      final creees = (await creeesF).fold((_) => <TontineEntity>[], (l) => l);
      final idsCreees = creees.map((t) => t.idTontine).toSet();
      final rejointes = (await demandesF)
          .fold((_) => <DemandeAdhesionEntity>[], (l) => l)
          .where((d) =>
              d.statut == DemandeStatus.acceptee &&
              d.idTontine != null &&
              !idsCreees.contains(d.idTontine))
          .map((d) => d.idTontine)
          .toSet();

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
        nbTontines: creees.length + rejointes.length,
        nbTontinesCreees: creees.length,
        nbTontinesRejointes: rejointes.length,
        revenuTotal: revenu,
      ));
    } catch (e) {
      emit(DashboardFailure(e.toString()));
    }
  }
}

