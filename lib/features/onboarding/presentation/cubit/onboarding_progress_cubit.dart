import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goapp/features/onboarding/data/services/onboarding_progress_service.dart';
import 'onboarding_progress_state.dart';

class OnboardingProgressCubit extends Cubit<OnboardingProgressState> {
  OnboardingProgressCubit({OnboardingProgressService? service})
      : _service = service ?? OnboardingProgressService(),
        super(const OnboardingProgressLoading());

  final OnboardingProgressService _service;

  Future<void> load() async {
    emit(const OnboardingProgressLoading());
    try {
      final data = await _service.fetchProgress();
      emit(OnboardingProgressSuccess(data));
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '').trim();
      emit(OnboardingProgressFailure(msg.isEmpty ? 'Something went wrong.' : msg));
    }
  }
}
