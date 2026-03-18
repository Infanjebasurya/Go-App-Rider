import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goapp/features/onboarding/data/datasources/onboarding_progress_remote_data_source.dart';
import 'onboarding_progress_state.dart';

class OnboardingProgressCubit extends Cubit<OnboardingProgressState> {
  OnboardingProgressCubit({OnboardingProgressRemoteDataSource? remote})
    : _remote = remote ?? OnboardingProgressRemoteDataSourceImpl(),
      super(const OnboardingProgressLoading());

  final OnboardingProgressRemoteDataSource _remote;

  Future<void> load() async {
    emit(const OnboardingProgressLoading());
    try {
      final data = await _remote.fetchProgress();
      emit(OnboardingProgressSuccess(data));
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '').trim();
      emit(
        OnboardingProgressFailure(msg.isEmpty ? 'Something went wrong.' : msg),
      );
    }
  }
}
