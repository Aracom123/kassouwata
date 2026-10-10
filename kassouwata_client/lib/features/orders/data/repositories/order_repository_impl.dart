import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../cart/domain/entities/cart_item_entity.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/repositories/order_repository.dart';
import '../datasources/order_remote_datasource.dart';
import '../models/order_model.dart';

class OrderRepositoryImpl implements OrderRepository {
  final OrderRemoteDataSource _remote;
  final SecureStorage _storage;

  OrderRepositoryImpl(this._remote, this._storage);

  @override
  Future<Either<Failure, List<OrderEntity>>> getMyOrders() async {
    try {
      final userId = await _storage.getUserId();
      if (userId == null) return const Right([]);
      final orders = await _remote.getMyOrders(userId);
      return Right(orders);
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Erreur réseau'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<OrderEntity>>> placeOrder({
    required List<CartItemEntity> items,
    required PaymentMethod modePaiement,
    required TypeVente typeVente,
    String? adresseLivraison,
  }) async {
    try {
      final userId = await _storage.getUserId();
      if (userId == null) {
        return const Left(ServerFailure('Non authentifié'));
      }

      final total = items.fold<double>(0, (sum, item) => sum + item.subtotal);

      // Construire les lignes à inclure dans le corps de la commande.
      // En POSTPAYE : une seule commande avec toutes les lignes.
      // En PREPAYE  : le backend éclate en N commandes (une par produit).
      final lignesJson = items.map((item) => OrderLineModel(
            idProduitCommande: 0,
            idProduit: item.product.idProduit,
            libelleProduit: item.product.libelle,
            prixUnitaire: item.product.prix,
            quantite: item.quantity,
          ).toJson()).toList();

      final commandeBody = OrderModel(
        idCommande: 0,
        dateCommande: DateTime.now(),
        statut: OrderStatus.enAttente,
        modePaiement: modePaiement,
        typeVente: typeVente,
        montantTotal: total,
        adresseLivraison: adresseLivraison,
      ).toJson(userId, lignes: lignesJson);

      // Le backend retourne toujours une List<Commande> :
      // • POSTPAYE → 1 commande
      // • PREPAYE  → N commandes (une par produit du panier)
      final commandes = await _remote.saveCommande(commandeBody);
      if (commandes.isEmpty) {
        return const Left(ServerFailure('Aucune commande créée'));
      }

      return Right(List<OrderEntity>.from(commandes));
    } on DioException catch (e) {
      if (e.response != null) {
        final data = e.response!.data;
        String? msg;
        if (data is Map) {
          msg = data['error'] as String? ?? data['message'] as String?;
        } else if (data is String) {
          msg = data;
        }
        return Left(ServerFailure(msg ?? 'Erreur serveur'));
      }
      return Left(ServerFailure(e.message ?? 'Erreur réseau'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, OrderEntity>> cancelOrder(int id) async {
    try {
      final order = await _remote.cancelCommande(id);
      return Right(order);
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Erreur réseau'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<VersementEntity>>> getVersements(
      int commandeId) async {
    try {
      final versements = await _remote.getVersements(commandeId);
      return Right(versements);
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Erreur réseau'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, VersementEntity>> addVersement({
    required int commandeId,
    required double montant,
    required String modePaiement,
    String? moyenPaiement,
  }) async {
    try {
      final body = VersementModel(
        idTransaction: 0,
        montant: montant,
        dateTransaction: DateTime.now(),
        modePaiement: modePaiement,
        moyenPaiement: moyenPaiement,
      ).toJson(idCommande: commandeId);
      final versement = await _remote.saveVersement(body);
      return Right(versement);
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Erreur réseau'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
