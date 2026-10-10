import 'package:equatable/equatable.dart';

class BoutiqueEntity extends Equatable {
  final int idBoutique;
  final String libelle;
  final String? description;
  final String? adresse;
  final String status;

  const BoutiqueEntity({
    required this.idBoutique,
    required this.libelle,
    this.description,
    this.adresse,
    required this.status,
  });

  bool get isActive => status == 'ACTIVE';

  @override
  List<Object?> get props => [idBoutique];
}
