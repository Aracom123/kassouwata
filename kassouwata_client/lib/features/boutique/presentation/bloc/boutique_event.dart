part of 'boutique_bloc.dart';

abstract class BoutiqueEvent extends Equatable {
  const BoutiqueEvent();
  @override
  List<Object?> get props => [];
}

class LoadBoutiques extends BoutiqueEvent {
  const LoadBoutiques();
}

class LoadBoutiqueProducts extends BoutiqueEvent {
  final int boutiqueId;
  const LoadBoutiqueProducts(this.boutiqueId);
  @override
  List<Object?> get props => [boutiqueId];
}
