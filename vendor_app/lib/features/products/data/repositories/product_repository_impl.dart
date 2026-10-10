import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/product_remote_datasource.dart';
import '../models/save_product_model.dart';

@Injectable(as: ProductRepository)
class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDataSource _remoteDataSource;
  const ProductRepositoryImpl(this._remoteDataSource);

  Failure _handleError(Object e) {
    if (e is DioException) {
      if (e.response != null) {
        final msg = e.response?.data?.toString() ?? 'Erreur serveur';
        return ServerFailure(msg, statusCode: e.response?.statusCode);
      }
      return NetworkFailure(e.message ?? 'Erreur réseau');
    }
    return ServerFailure(e.toString());
  }

  @override
  Future<Either<Failure, List<ProductEntity>>> getProductsByShop(int idBoutique) async {
    try {
      final models = await _remoteDataSource.getProductsByBoutique(idBoutique);
      return Right(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> createProduct({
    required int idBoutique,
    required String libelle,
    String? description,
    required double prixUnitaire,
    required int quantite,
    int? nombreTranches,
    int? idCategorie,
    String? imagePrincipalePath,
    List<String>? photosPaths,
  }) async {
    try {
      String? imagePrincipale;
      String? photos;

      if (imagePrincipalePath != null) {
        imagePrincipale = await _remoteDataSource.uploadImage(imagePrincipalePath);
      }
      if (photosPaths != null && photosPaths.isNotEmpty) {
        final filenames = await _remoteDataSource.uploadImages(photosPaths);
        photos = filenames.join(',');
      }

      await _remoteDataSource.saveProduct(SaveProductRequestModel(
        idBoutique: idBoutique,
        libelle: libelle,
        description: description,
        prixUnitaire: prixUnitaire,
        quantite: quantite,
        nombreTranches: nombreTranches,
        imagePrincipale: imagePrincipale,
        photos: photos,
        idCategorie: idCategorie,
        statut: true,
      ));
      return const Right(unit);
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateProduct({
    required int idProduit,
    required int idBoutique,
    required String libelle,
    String? description,
    required double prixUnitaire,
    required int quantite,
    required bool statut,
    int? nombreTranches,
    int? idCategorie,
    String? imagePrincipalePath,
    List<String>? photosPaths,
    String? existingImagePrincipale,
    List<String>? existingPhotos,
  }) async {
    try {
      String? imagePrincipale = existingImagePrincipale;
      String? photos = existingPhotos?.join(',');

      if (imagePrincipalePath != null) {
        imagePrincipale = await _remoteDataSource.uploadImage(imagePrincipalePath);
        if (existingImagePrincipale != null) {
          await _remoteDataSource.deleteFile(existingImagePrincipale);
        }
      }
      if (photosPaths != null && photosPaths.isNotEmpty) {
        final filenames = await _remoteDataSource.uploadImages(photosPaths);
        photos = filenames.join(',');
      }

      await _remoteDataSource.updateProduct(idProduit, SaveProductRequestModel(
        idBoutique: idBoutique,
        libelle: libelle,
        description: description,
        prixUnitaire: prixUnitaire,
        quantite: quantite,
        nombreTranches: nombreTranches,
        imagePrincipale: imagePrincipale,
        photos: photos,
        idCategorie: idCategorie,
        statut: statut,
      ));
      return const Right(unit);
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteProduct(int idProduit) async {
    try {
      await _remoteDataSource.deleteProduct(idProduit);
      return const Right(unit);
    } catch (e) {
      return Left(_handleError(e));
    }
  }
}
