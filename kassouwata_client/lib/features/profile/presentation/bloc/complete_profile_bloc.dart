import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../features/auth/domain/entities/user_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/usecases/complete_profile_usecase.dart';

part 'complete_profile_event.dart';
part 'complete_profile_state.dart';

@injectable
class CompleteProfileBloc
    extends Bloc<CompleteProfileEvent, CompleteProfileState> {
  final CompleteProfileUseCase _useCase;
  final ProfileRepository _repository;

  CompleteProfileBloc(this._useCase, this._repository)
      : super(CompleteProfileInitial()) {
    on<SubmitProfile>(_onSubmit);
    on<UpdateProfile>(_onUpdate);
  }

  Future<void> _onSubmit(
      SubmitProfile event, Emitter<CompleteProfileState> emit) async {
    emit(CompleteProfileLoading());

    // 1. Soumettre le profil
    final result = await _useCase(
      idUser: event.idUser,
      nom: event.nom,
      prenom: event.prenom,
      email: event.email,
      genre: event.genre,
      adresse: event.adresse,
      dateNaissance: event.dateNaissance,
      lieuNaissance: event.lieuNaissance,
    );

    if (result.isLeft()) {
      result.fold(
        (failure) => emit(CompleteProfileFailure(failure.message)),
        (_) {},
      );
      return;
    }

    // 2. Profil soumis → rafraîchir le token silencieusement
    final refreshResult = await _repository.refreshSession();
    refreshResult.fold(
      (_) => emit(CompleteProfileSuccessNoRefresh()),
      (user) => emit(CompleteProfileSuccess(user)),
    );
  }

  Future<void> _onUpdate(
      UpdateProfile event, Emitter<CompleteProfileState> emit) async {
    emit(CompleteProfileLoading());

    final result = await _useCase(
      idUser: event.idUser,
      nom: event.nom,
      prenom: event.prenom,
      email: event.email,
      genre: event.genre,
      adresse: event.adresse,
      dateNaissance: event.dateNaissance,
      lieuNaissance: event.lieuNaissance,
    );

    if (result.isLeft()) {
      result.fold(
        (failure) => emit(CompleteProfileFailure(failure.message)),
        (_) {},
      );
      return;
    }

    // Rafraîchir la session pour que AuthBloc reflète les nouvelles infos
    final refreshResult = await _repository.refreshSession();
    refreshResult.fold(
      (_) => emit(CompleteProfileFailure('Profil mis à jour mais impossible de rafraîchir la session.')),
      (user) => emit(UpdateProfileSuccess(user)),
    );
  }
}
