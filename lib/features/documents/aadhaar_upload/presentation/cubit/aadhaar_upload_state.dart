import 'package:equatable/equatable.dart';
import 'package:goapp/features/documents/aadhaar_upload/data/models/document_upload_response.dart';

class AadhaarUploadState extends Equatable {
  const AadhaarUploadState({
    required this.aadhaarNumber,
    required this.filePath,
    required this.fileName,
    required this.isSubmitting,
    required this.response,
    required this.errorMessage,
    required this.aadhaarError,
  });

  final String aadhaarNumber;
  final String? filePath;
  final String? fileName;
  final bool isSubmitting;
  final DocumentUploadResponse? response;
  final String? errorMessage;
  final String? aadhaarError;

  factory AadhaarUploadState.initial() => const AadhaarUploadState(
    aadhaarNumber: '',
    filePath: null,
    fileName: null,
    isSubmitting: false,
    response: null,
    errorMessage: null,
    aadhaarError: null,
  );

  bool get hasFile => filePath != null && filePath!.trim().isNotEmpty;

  bool get isAadhaarValid => RegExp(r'^\d{12}$').hasMatch(aadhaarNumber.trim());

  bool get canSubmit => isAadhaarValid && hasFile && !isSubmitting;

  AadhaarUploadState copyWith({
    String? aadhaarNumber,
    String? filePath,
    String? fileName,
    bool? isSubmitting,
    DocumentUploadResponse? response,
    String? errorMessage,
    String? aadhaarError,
    bool clearResponse = false,
    bool clearError = false,
    bool clearFile = false,
    bool clearAadhaarError = false,
  }) {
    return AadhaarUploadState(
      aadhaarNumber: aadhaarNumber ?? this.aadhaarNumber,
      filePath: clearFile ? null : (filePath ?? this.filePath),
      fileName: clearFile ? null : (fileName ?? this.fileName),
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
    filePath,
    fileName,
    isSubmitting,
    response,
    errorMessage,
    aadhaarError,
  ];
}
