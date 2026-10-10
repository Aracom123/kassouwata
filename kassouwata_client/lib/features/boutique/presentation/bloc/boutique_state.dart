part of 'boutique_bloc.dart';

enum BoutiqueStatus { initial, loading, success, failure }

class BoutiqueState extends Equatable {
  final BoutiqueStatus status;
  final List<BoutiqueEntity> boutiques;
  final List<ProductEntity> boutiqueProducts;
  final BoutiqueStatus productsStatus;
  final String? errorMessage;

  const BoutiqueState({
    this.status = BoutiqueStatus.initial,
    this.boutiques = const [],
    this.boutiqueProducts = const [],
    this.productsStatus = BoutiqueStatus.initial,
    this.errorMessage,
  });

  BoutiqueState copyWith({
    BoutiqueStatus? status,
    List<BoutiqueEntity>? boutiques,
    List<ProductEntity>? boutiqueProducts,
    BoutiqueStatus? productsStatus,
    String? errorMessage,
  }) {
    return BoutiqueState(
      status: status ?? this.status,
      boutiques: boutiques ?? this.boutiques,
      boutiqueProducts: boutiqueProducts ?? this.boutiqueProducts,
      productsStatus: productsStatus ?? this.productsStatus,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [status, boutiques, boutiqueProducts, productsStatus, errorMessage];
}
