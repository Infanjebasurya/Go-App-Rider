import 'package:equatable/equatable.dart';
import 'package:goapp/features/onboarding/data/models/onboarding_progress_response_model.dart';

sealed class OnboardingProgressState extends Equatable {
  const OnboardingProgressState();

  @override
  List<Object?> get props => const [];
}

final class OnboardingProgressLoading extends OnboardingProgressState {
  const OnboardingProgressLoading();
}

final class OnboardingProgressSuccess extends OnboardingProgressState {
  const OnboardingProgressSuccess(this.data);

  final OnboardingProgressResponseModel data;

  @override
  List<Object?> get props => [data];
}

final class OnboardingProgressFailure extends OnboardingProgressState {
  const OnboardingProgressFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
