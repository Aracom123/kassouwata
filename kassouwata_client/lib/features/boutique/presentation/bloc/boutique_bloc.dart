import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../catalogue/domain/entities/product_entity.dart';
import '../../domain/entities/boutique_entity.dart';
import '../../domain/repositories/boutique_repository.dart';

part 'boutique_event.dart';
part 'boutique_state.dart';

class BoutiqueBloc extends Bloc<BoutiqueEvent, BoutiqueState> {
  final BoutiqueRepository _repository;

  BoutiqueBloc(this._repository) : super(const BoutiqueState()) {
    on<LoadBoutiques>(_onLoadBoutiques);
    on<LoadBoutiqueProducts>(_onLoadBoutiqueProducts);
  }

  Future<void> _onLoadBoutiques(
      LoadBoutiques event, Emitter<BoutiqueState> emit) async {
    emit(state.copyWith(status: BoutiqueStatus.loading));
    final result = await _repository.getBoutiques();
    result.fold(
      (f) => emit(state.copyWith(
          status: BoutiqueStatus.failure, errorMessage: f.message)),
      (list) => emit(state.copyWith(
          status: BoutiqueStatus.success, boutiques: list)),
    );
  }

  Future<void> _onLoadBoutiqueProducts(
      LoadBoutiqueProducts event, Emitter<BoutiqueState> emit) async {
    emit(state.copyWith(productsStatus: BoutiqueStatus.loading));
    final result = await _repository.getProductsByBoutique(event.boutiqueId);
    result.fold(
      (f) => emit(state.copyWith(
          productsStatus: BoutiqueStatus.failure, errorMessage: f.message)),
      (products) => emit(state.copyWith(
          productsStatus: BoutiqueStatus.success, boutiqueProducts: products)),
    );
  }
}
