import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goapp/features/auth/domain/usecases/resend_otp_usecase.dart';

class OtpState extends Equatable {
  const OtpState({
    this.code = '',
    this.secondsLeft = 30,
    this.canResend = false,
    this.isLoading = false,
    this.submitRequested = false,
    this.submitError,
    this.resendMessage,
    this.errorMessage,
  });

  final String code;
  final int secondsLeft;
  final bool canResend;
  final bool isLoading;
  final bool submitRequested;
  final String? submitError;
  final String? resendMessage;
  final String? errorMessage;

  OtpState copyWith({
    String? code,
    int? secondsLeft,
    bool? canResend,
    bool? isLoading,
    bool? submitRequested,
    String? submitError,
    String? resendMessage,
    String? errorMessage,
    bool clearSubmitError = false,
    bool clearResendMessage = false,
    bool clearErrorMessage = false,
  }) {
    return OtpState(
      code: code ?? this.code,
      secondsLeft: secondsLeft ?? this.secondsLeft,
      canResend: canResend ?? this.canResend,
      isLoading: isLoading ?? this.isLoading,
      submitRequested: submitRequested ?? this.submitRequested,
      submitError: clearSubmitError ? null : (submitError ?? this.submitError),
      resendMessage: clearResendMessage
          ? null
          : (resendMessage ?? this.resendMessage),
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => <Object?>[
    code,
    secondsLeft,
    canResend,
    isLoading,
    submitRequested,
    submitError,
    resendMessage,
    errorMessage,
  ];
}

class OtpCubit extends Cubit<OtpState> {
  OtpCubit({required ResendOtpUseCase resendOtpUseCase})
    : _resendOtpUseCase = resendOtpUseCase,
      super(const OtpState()) {
    _startTimer();
  }

  static const int otpLength = 4;
  final ResendOtpUseCase _resendOtpUseCase;
  Timer? _timer;

  void _startTimer() {
    _timer?.cancel();
    emit(state.copyWith(secondsLeft: 30, canResend: false));
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final next = state.secondsLeft - 1;
      if (next <= 0) {
        timer.cancel();
        emit(state.copyWith(secondsLeft: 0, canResend: true));
      } else {
        emit(state.copyWith(secondsLeft: next));
      }
    });
  }

  void updateCode(String code) {
    final normalized = code.replaceAll(RegExp(r'[^0-9]'), '');
    final trimmed = normalized.length > otpLength
        ? normalized.substring(0, otpLength)
        : normalized;
    emit(
      state.copyWith(
        code: trimmed,
        clearSubmitError: true,
        clearErrorMessage: true,
      ),
    );
  }

  void submit(String phone, String otpId) {
    if (state.code.length != otpLength) {
      emit(state.copyWith(submitError: 'Enter complete OTP'));
      return;
    }
    emit(
      state.copyWith(
        isLoading: true,
        submitRequested: true,
        clearSubmitError: true,
        clearErrorMessage: true,
      ),
    );
  }

  Future<void> resend(String phone) async {
    if (!state.canResend || state.isLoading) {
      return;
    }
    emit(
      state.copyWith(
        isLoading: true,
        clearResendMessage: true,
        clearErrorMessage: true,
      ),
    );
    final result = await _resendOtpUseCase.call(phone: phone);
    result.fold(
      (failure) =>
          emit(state.copyWith(isLoading: false, errorMessage: failure.message)),
      (message) {
        emit(state.copyWith(isLoading: false, resendMessage: message));
        _startTimer();
      },
    );
  }

  void consumeActions() {
    emit(state.copyWith(submitRequested: false));
  }

  void handleAuthFailure(String message) {
    emit(
      state.copyWith(
        isLoading: false,
        submitRequested: false,
        errorMessage: message,
        clearSubmitError: true,
      ),
    );
  }

  void handleAuthSuccess() {
    emit(
      state.copyWith(
        isLoading: false,
        submitRequested: false,
        clearSubmitError: true,
        clearErrorMessage: true,
      ),
    );
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
