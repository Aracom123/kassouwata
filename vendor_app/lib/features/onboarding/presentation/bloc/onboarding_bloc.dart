import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../data/datasources/onboarding_datasource.dart';
import '../../../auth/data/datasources/auth_local_datasource.dart';
import '../../../auth/data/models/update_user_model.dart';
import '../../../shop/data/models/create_boutique_model.dart';
import '../../../shop/data/models/update_boutique_model.dart';

part 'onboarding_event.dart';
part 'onboarding_state.dart';

@injectable
class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  final OnboardingDataSource _dataSource;
  final AuthLocalDataSource _localDataSource;

  OnboardingBloc(this._dataSource, this._localDataSource) : super(OnboardingInitial()) {
    on<CompleteProfileRequested>(_onCompleteProfile);
    on<EditProfileRequested>(_onEditProfile);
    on<CreateBoutiqueRequested>(_onCreateBoutique);
    on<EditBoutiqueRequested>(_onEditBoutique);
  }

  /// Retourne `true` si l'exception correspond à une session expirée
  /// (token expiré détecté localement → DioExceptionType.cancel,
  ///  ou rejet 401 renvoyé par le serveur).
  bool _isSessionExpired(Object e) {
    if (e is DioException) {
      return e.type == DioExceptionType.cancel ||
          e.response?.statusCode == 401;
    }
    return false;
  }

  Future<void> _onCompleteProfile(
    CompleteProfileRequested event,
    Emitter<OnboardingState> emit,
  ) async {
    emit(OnboardingLoading());
    try {
      final request = UpdateUserRequestModel(
        status: 'ACTIVE',
        profile: const UpdateProfileModel(idProfile: 2),
        personne: UpdatePersonneModel(
          nom: event.nom,
          prenom: event.prenom,
          genre: event.genre,
          adresse: event.adresse,
          lieuNaissance: event.lieuNaissance,
          dateNaissance: event.dateNaissance,
          email: event.email,
        ),
      );
      await _dataSource.updateUser(idUser: event.idUser, request: request);
      emit(ProfileCompleted());
    } catch (e) {
      if (_isSessionExpired(e)) {
        emit(SessionExpired());
      } else {
        emit(OnboardingFailure(e.toString()));
      }
    }
  }

  Future<void> _onEditProfile(
    EditProfileRequested event,
    Emitter<OnboardingState> emit,
  ) async {
    emit(OnboardingLoading());
    try {
      final request = UpdateUserRequestModel(
        status: event.currentStatus,
        profile: const UpdateProfileModel(idProfile: 2),
        personne: UpdatePersonneModel(
          nom: event.nom,
          prenom: event.prenom,
          genre: event.genre,
          adresse: event.adresse,
          lieuNaissance: event.lieuNaissance,
          dateNaissance: event.dateNaissance,
          email: event.email,
        ),
      );
      await _dataSource.updateUser(idUser: event.idUser, request: request);
      emit(ProfileUpdated());
    } catch (e) {
      if (_isSessionExpired(e)) {
        emit(SessionExpired());
      } else {
        emit(OnboardingFailure(e.toString()));
      }
    }
  }

  Future<void> _onEditBoutique(
    EditBoutiqueRequested event,
    Emitter<OnboardingState> emit,
  ) async {
    emit(OnboardingLoading());
    try {
      final request = UpdateBoutiqueRequestModel(
        libelle: event.libelle,
        description: event.description,
        adresse: event.adresse,
        latitude: event.latitude,
        longitude: event.longitude,
        status: event.currentStatus,
        commission: event.currentCommission,
        idUser: event.idUser,
      );
      await _dataSource.updateBoutique(
        idBoutique: event.idBoutique,
        request: request,
      );
      emit(BoutiqueUpdated());
    } catch (e) {
      if (_isSessionExpired(e)) {
        emit(SessionExpired());
      } else {
        emit(OnboardingFailure(e.toString()));
      }
    }
  }

  Future<void> _onCreateBoutique(
    CreateBoutiqueRequested event,
    Emitter<OnboardingState> emit,
  ) async {
    emit(OnboardingLoading());
    try {
      final request = CreateBoutiqueRequestModel(
        libelle: event.libelle,
        description: event.description,
        adresse: event.adresse,
        latitude: event.latitude,
        longitude: event.longitude,
        vendeur: BoutiqueVendeurModel(idUser: event.idUser),
        status: 'PENDING',
      );
      final boutique = await _dataSource.createBoutique(request);
      await _localDataSource.cacheBoutique(boutique);
      emit(BoutiqueCreated());
    } catch (e) {
      if (_isSessionExpired(e)) {
        emit(SessionExpired());
      } else {
        emit(OnboardingFailure(e.toString()));
      }
    }
  }
}