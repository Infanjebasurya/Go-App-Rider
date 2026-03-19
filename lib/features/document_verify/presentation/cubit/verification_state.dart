import 'package:equatable/equatable.dart';

import '../model/document_model.dart';

class VerificationState extends Equatable {
  const VerificationState({
    required this.documents,
    this.isSubmitting = false,
    this.isSubmitted = false,
    this.declarationAccepted = true,
    this.errorMessage,
    this.isProfileImageUploaded = false,
    this.submissionId,
    this.submissionStatus,
    this.submissionMessage,
  });

  final List<Document> documents;
  final bool isSubmitting;
  final bool isSubmitted;
  final bool declarationAccepted;
  final String? errorMessage;
  final bool isProfileImageUploaded;
  final String? submissionId;
  final String? submissionStatus;
  final String? submissionMessage;

  factory VerificationState.initial() {
    return const VerificationState(
      documents: [
        Document(
          type: DocumentType.drivingLicense,
          status: DocumentStatus.required,
        ),
        Document(type: DocumentType.vehicleRC, status: DocumentStatus.required),
        Document(
          type: DocumentType.aadhaarCard,
          status: DocumentStatus.required,
        ),
        Document(type: DocumentType.panCard, status: DocumentStatus.required),
        Document(
          type: DocumentType.bankDetails,
          status: DocumentStatus.required,
        ),
      ],
      isProfileImageUploaded: false,
      declarationAccepted: true,
    );
  }

  int get completedCount => documents.where((d) => d.isCompleted).length;

  int get totalRequiredCount => documents.length + 1;

  int get completedCountWithProfile =>
      completedCount + (isProfileImageUploaded ? 1 : 0);

  double get progressPercentage => totalRequiredCount == 0
      ? 0
      : completedCountWithProfile / totalRequiredCount;

  int get progressPercent => (progressPercentage * 100).round();

  bool get canSubmit =>
      isProfileImageUploaded && completedCount == documents.length;

  VerificationState copyWith({
    List<Document>? documents,
    bool? isSubmitting,
    bool? isSubmitted,
    bool? declarationAccepted,
    String? errorMessage,
    bool? isProfileImageUploaded,
    String? submissionId,
    String? submissionStatus,
    String? submissionMessage,
    bool clearError = false,
  }) {
    return VerificationState(
      documents: documents ?? this.documents,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSubmitted: isSubmitted ?? this.isSubmitted,
      declarationAccepted: declarationAccepted ?? this.declarationAccepted,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isProfileImageUploaded:
          isProfileImageUploaded ?? this.isProfileImageUploaded,
      submissionId: submissionId ?? this.submissionId,
      submissionStatus: submissionStatus ?? this.submissionStatus,
      submissionMessage: submissionMessage ?? this.submissionMessage,
    );
  }

  @override
  List<Object?> get props => [
    documents,
    isSubmitting,
    isSubmitted,
    declarationAccepted,
    errorMessage,
    isProfileImageUploaded,
    submissionId,
    submissionStatus,
    submissionMessage,
  ];
}
