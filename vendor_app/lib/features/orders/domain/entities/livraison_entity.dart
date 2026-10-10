import 'package:equatable/equatable.dart';

class LivraisonEntity extends Equatable {
  final int idLivraison;
  final DateTime? dateLivraison;
  final String? adresseLivraison;
  final int? idCommande;

  const LivraisonEntity({
    required this.idLivraison,
    this.dateLivraison,
    this.adresseLivraison,
    this.idCommande,
  });

  @override
  List<Object?> get props => [idLivraison, dateLivraison];
}