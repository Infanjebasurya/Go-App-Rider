import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goapp/core/storage/driver_id_store.dart';
import 'package:goapp/core/storage/onboarding_submission_store.dart';
import 'package:goapp/features/onboarding/data/datasources/onboarding_submit_remote_data_source.dart';

import 'onboarding_submit_state.dart';

class OnboardingSubmitCubit extends Cubit<OnboardingSubmitState> {
  OnboardingSubmitCubit({OnboardingSubmitRemoteDataSource? remote})
    : _remote = remote ?? OnboardingSubmitRemoteDataSourceImpl(),
      super(OnboardingSubmitState.initial);

  final OnboardingSubmitRemoteDataSource _remote;

  void setDeclarationAccepted(bool value) {
    emit(state.copyWith(declarationAccepted: value, clearError: true));
  }

  Future<void> submit({required bool allStepsCompleted}) async {
    if (state.isSubmitting) return;

    if (!allStepsCompleted) {
      emit(
        state.copyWith(
          errorMessage: 'Please complete all onboarding steps first.',
        ),
      );
      return;
    }
    if (!state.declarationAccepted) {
      emit(
        state.copyWith(
          errorMessage: 'Please accept the declaration to submit.',
        ),
      );
      return;
    }

    final String driverId = (DriverIdStore.driverId() ?? '').trim();
    if (driverId.isEmpty) {
      emit(
        state.copyWith(errorMessage: 'Driver id missing. Please try again.'),
      );
      return;
    }

    emit(
      state.copyWith(isSubmitting: true, submitted: false, clearError: true),
    );
    try {
      final response = await _remote.submit(
        driverId: driverId,
        declarationAccepted: state.declarationAccepted,
      );

      final String submissionId = (response.submissionId ?? '').trim();
      if (submissionId.isNotEmpty) {
        await OnboardingSubmissionStore.save(
          submissionId: submissionId,
          status: response.status,
        );
      }

      emit(
        state.copyWith(
          isSubmitting: false,
          submitted: true,
          submissionId: submissionId,
          status: response.status,
          message: response.message,
        ),
      );
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '').trim();
      emit(
        state.copyWith(
          isSubmitting: false,
          submitted: false,
          errorMessage: msg.isEmpty ? 'Submission failed.' : msg,
        ),
      );
    }
  }
}
