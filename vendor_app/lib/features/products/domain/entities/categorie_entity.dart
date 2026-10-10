import 'package:equatable/equatable.dart';

class CategorieEntity extends Equatable {
  final int idCategorie;
  final String libelle;
  final String? description;

  const CategorieEntity({
    required this.idCategorie,
    required this.libelle,
    this.description,
  });

  @override
  List<Object?> get props => [idCategorie, libelle];
}