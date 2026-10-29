import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/product_entity.dart';

abstract class ProductRepository {
  Future<Either<Failure, List<ProductEntity>>> getProductsByShop(int idBoutique);
  Future<Either<Failure, Unit>> createProduct({
    required int idBoutique,
    required String libelle,
    String? description,
    required double prixUnitaire,
    required int quantite,
    int? nombreTranches,
    bool adasheAutorise = false,
    int? idCategorie,
    String? imagePrincipalePath,
    List<String>? photosPaths,
  });
  Future<Either<Failure, Unit>> updateProduct({
    required int idProduit,
    required int idBoutique,
    required String libelle,
    String? description,
    required double prixUnitaire,
    required int quantite,
    required bool statut,
    int? nombreTranches,
    bool adasheAutorise = false,
    int? idCategorie,
    String? imagePrincipalePath,
    List<String>? photosPaths,
    String? existingImagePrincipale,
    List<String>? existingPhotos,
  });
  Future<Either<Failure, Unit>> deleteProduct(int idProduit);
}
