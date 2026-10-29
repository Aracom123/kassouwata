import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/storage/secure_storage.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/register_usecase.dart';

part 'auth_event.dart';
part 'auth_state.dart';

@injectable
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase _loginUseCase;
  final RegisterUseCase _registerUseCase;
  final SecureStorage _storage;
  final AuthRepository _authRepository;

  AuthBloc(this._loginUseCase, this._registerUseCase, this._storage,
      this._authRepository)
      : super(AuthInitial()) {
    on<CheckAuthStatus>(_onCheckAuth);
    on<LoginRequested>(_onLogin);
    on<RegisterRequested>(_onRegister);
    on<OtpVerifyRequested>(_onOtpVerify);
    on<ResendOtpRequested>(_onResendOtp);
    on<LogoutRequested>(_onLogout);
    on<UserUpdated>(_onUserUpdated);
  }

  Future<void> _onCheckAuth(
      CheckAuthStatus event, Emitter<AuthState> emit) async {
    final token = await _storage.getToken();
    if (token == null || token.isEmpty) {
      emit(Unauthenticated());
      return;
    }

    final expired = await _storage.isTokenExpired();
    if (expired) {
      await _storage.clearAll();
      emit(Unauthenticated());
      return;
    }

    final tel = await _storage.getTelephone() ?? '';
    final profile = await _storage.getProfile() ?? '';
    final id = await _storage.getUserId() ?? '';
    final status = await _storage.getStatus() ?? 'ACTIVE';

    if (status == 'KYC_PENDING') {
      final prenom = await _storage.getPrenom();
      final nom = await _storage.getNom();
      emit(KycPending(idUser: id, token: token, prenom: prenom, nom: nom));
      return;
    }

    emit(Authenticated(UserEntity(
      idUser: id,
      telephone: tel,
      profile: profile,
      status: status,
      token: token,
    )));
  }

  Future<void> _onLogin(
      LoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await _loginUseCase(
        telephone: event.telephone, password: event.password);
    result.fold(
      (f) => emit(AuthFailure(f.message)),
      (user) {
        if (user.status == 'KYC_PENDING') {
          emit(KycPending(
            idUser: user.idUser,
            token: user.token,
            prenom: user.prenom,
            nom: user.nom,
          ));
        } else {
          emit(Authenticated(user));
        }
      },
    );
  }

  Future<void> _onRegister(
      RegisterRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await _registerUseCase(
      telephone: event.telephone,
      password: event.password,
      nom: event.nom,
      prenom: event.prenom,
      vendeur: event.vendeur,
    );
    result.fold(
      (f) => emit(AuthFailure(f.message)),
      (telephone) => emit(OtpRequired(telephone)),
    );
  }

  Future<void> _onOtpVerify(
      OtpVerifyRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await _authRepository.verifyOtp(
      telephone: event.telephone,
      code: event.code,
    );
    result.fold(
      (f) => emit(AuthFailure(f.message)),
      (_) => emit(OtpVerified(event.telephone)),
    );
  }

  Future<void> _onResendOtp(
      ResendOtpRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await _authRepository.sendOtp(telephone: event.telephone);
    result.fold(
      (f) => emit(AuthFailure(f.message)),
      (_) => emit(OtpRequired(event.telephone)),
    );
  }

  Future<void> _onLogout(
      LogoutRequested event, Emitter<AuthState> emit) async {
    await _authRepository.logout();
    emit(Unauthenticated());
  }

  Future<void> _onUserUpdated(
      UserUpdated event, Emitter<AuthState> emit) async {
    emit(Authenticated(event.user));
  }
}
