part of 'onboarding_bloc.dart';

abstract class OnboardingState extends Equatable {
  const OnboardingState();
  @override
  List<Object?> get props => [];
}

class OnboardingInitial extends OnboardingState {}

class OnboardingLoading extends OnboardingState {}

class ProfileCompleted extends OnboardingState {}

class ProfileUpdated extends OnboardingState {}

class BoutiqueCreated extends OnboardingState {}

class BoutiqueUpdated extends OnboardingState {}

class OnboardingFailure extends OnboardingState {
  final String message;
  const OnboardingFailure(this.message);

  @override
  List<Object?> get props => [message];
}

class SessionExpired extends OnboardingState {}