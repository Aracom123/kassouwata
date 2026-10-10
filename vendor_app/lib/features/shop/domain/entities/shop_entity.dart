import 'package:equatable/equatable.dart';
import '../../../../shared/enums/boutique_status.dart';

class ShopEntity extends Equatable {
  final int idBoutique;
  final String libelle;
  final String? description;
  final String? adresse;
  final double? latitude;
  final double? longitude;
  final double commission;
  final BoutiqueStatus status;

  const ShopEntity({
    required this.idBoutique,
    required this.libelle,
    this.description,
    this.adresse,
    this.latitude,
    this.longitude,
    this.commission = 5.0,
    this.status = BoutiqueStatus.pending,
  });

  @override
  List<Object?> get props => [idBoutique, libelle, status];
}