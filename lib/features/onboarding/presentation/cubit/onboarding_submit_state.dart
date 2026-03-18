import 'package:equatable/equatable.dart';

class OnboardingSubmitState extends Equatable {
  const OnboardingSubmitState({
    required this.declarationAccepted,
    required this.isSubmitting,
    required this.submitted,
    this.errorMessage,
    this.submissionId,
    this.status,
    this.message,
  });

  final bool declarationAccepted;
  final bool isSubmitting;
  final bool submitted;
  final String? errorMessage;
  final String? submissionId;
  final String? status;
  final String? message;

  bool get isSuccess => submitted;

  OnboardingSubmitState copyWith({
    bool? declarationAccepted,
    bool? isSubmitting,
    bool? submitted,
    String? errorMessage,
    String? submissionId,
    String? status,
    String? message,
    bool clearError = false,
  }) {
    return OnboardingSubmitState(
      declarationAccepted: declarationAccepted ?? this.declarationAccepted,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitted: submitted ?? this.submitted,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      submissionId: submissionId ?? this.submissionId,
      status: status ?? this.status,
      message: message ?? this.message,
    );
  }

  static const OnboardingSubmitState initial = OnboardingSubmitState(
    declarationAccepted: false,
    isSubmitting: false,
    submitted: false,
  );

  @override
  List<Object?> get props => [
    declarationAccepted,
    isSubmitting,
    submitted,
    errorMessage,
    submissionId,
    status,
    message,
  ];
}
