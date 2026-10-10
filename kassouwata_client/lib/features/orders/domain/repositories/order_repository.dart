import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../cart/domain/entities/cart_item_entity.dart';
import '../entities/order_entity.dart';

abstract class OrderRepository {
  Future<Either<Failure, List<OrderEntity>>> getMyOrders();
  /// Retourne la liste de toutes les commandes créées.
  /// POSTPAYE → 1 commande, PREPAYE → N commandes (une par produit).
  Future<Either<Failure, List<OrderEntity>>> placeOrder({
    required List<CartItemEntity> items,
    required PaymentMethod modePaiement,
    required TypeVente typeVente,
    String? adresseLivraison,
  });
  Future<Either<Failure, OrderEntity>> cancelOrder(int id);
  Future<Either<Failure, List<VersementEntity>>> getVersements(int commandeId);
  Future<Either<Failure, VersementEntity>> addVersement({
    required int commandeId,
    required double montant,
    required String modePaiement,
    String? moyenPaiement,
  });
}
