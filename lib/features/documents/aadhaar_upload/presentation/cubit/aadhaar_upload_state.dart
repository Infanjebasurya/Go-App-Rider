import 'package:equatable/equatable.dart';
import 'package:goapp/features/documents/aadhaar_upload/data/models/document_upload_response.dart';

class AadhaarUploadState extends Equatable {
  const AadhaarUploadState({
    required this.aadhaarNumber,
    required this.frontFilePath,
    required this.frontFileName,
    required this.backFilePath,
    required this.backFileName,
    required this.isSubmitting,
    required this.response,
    required this.errorMessage,
    required this.aadhaarError,
  });

  final String aadhaarNumber;
  final String? frontFilePath;
  final String? frontFileName;
  final String? backFilePath;
  final String? backFileName;
  final bool isSubmitting;
  final AadhaarUploadResponse? response;
  final String? errorMessage;
  final String? aadhaarError;

  factory AadhaarUploadState.initial() => const AadhaarUploadState(
    aadhaarNumber: '',
    frontFilePath: null,
    frontFileName: null,
    backFilePath: null,
    backFileName: null,
    isSubmitting: false,
    response: null,
    errorMessage: null,
    aadhaarError: null,
  );

  bool get hasFrontFile =>
      frontFilePath != null && frontFilePath!.trim().isNotEmpty;
  bool get hasBackFile =>
      backFilePath != null && backFilePath!.trim().isNotEmpty;

  bool get isAadhaarValid => RegExp(r'^\d{12}$').hasMatch(aadhaarNumber.trim());

  bool get canSubmit =>
      isAadhaarValid && hasFrontFile && hasBackFile && !isSubmitting;

  AadhaarUploadState copyWith({
    String? aadhaarNumber,
    String? frontFilePath,
    String? frontFileName,
    String? backFilePath,
    String? backFileName,
    bool? isSubmitting,
    AadhaarUploadResponse? response,
    String? errorMessage,
    String? aadhaarError,
    bool clearResponse = false,
    bool clearError = false,
    bool clearFrontFile = false,
    bool clearBackFile = false,
    bool clearAadhaarError = false,
  }) {
    return AadhaarUploadState(
      aadhaarNumber: aadhaarNumber ?? this.aadhaarNumber,
      frontFilePath: clearFrontFile
          ? null
          : (frontFilePath ?? this.frontFilePath),
      frontFileName: clearFrontFile
          ? null
          : (frontFileName ?? this.frontFileName),
      backFilePath: clearBackFile ? null : (backFilePath ?? this.backFilePath),
      backFileName: clearBackFile ? null : (backFileName ?? this.backFileName),
      isSubmitting: isSubmitting ?? this.isSubmitting,
      response: clearResponse ? null : (response ?? this.response),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      aadhaarError: clearAadhaarError
          ? null
          : (aadhaarError ?? this.aadhaarError),
    );
  }

  @override
  List<Object?> get props => <Object?>[
    aadhaarNumber,
    frontFilePath,
    frontFileName,
    backFilePath,
    backFileName,
    isSubmitting,
    response,
    errorMessage,
    aadhaarError,
  ];
}
