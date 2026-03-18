import 'package:equatable/equatable.dart';
import 'package:goapp/features/documents/pan_upload/data/models/pan_upload_response.dart';

class PanUploadState extends Equatable {
  const PanUploadState({
    required this.panNumber,
    required this.filePath,
    required this.fileName,
    required this.isSubmitting,
    required this.response,
    required this.errorMessage,
    required this.panError,
  });

  final String panNumber;
  final String? filePath;
  final String? fileName;
  final bool isSubmitting;
  final PanUploadResponse? response;
  final String? errorMessage;
  final String? panError;

  factory PanUploadState.initial() => const PanUploadState(
    panNumber: '',
    filePath: null,
    fileName: null,
    isSubmitting: false,
    response: null,
    errorMessage: null,
    panError: null,
  );

  bool get hasFile => filePath != null && filePath!.trim().isNotEmpty;

  bool get isPanValid =>
      RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$').hasMatch(panNumber.trim());

  bool get canSubmit => isPanValid && hasFile && !isSubmitting;

  PanUploadState copyWith({
    String? panNumber,
    String? filePath,
    String? fileName,
    bool? isSubmitting,
    PanUploadResponse? response,
    String? errorMessage,
    String? panError,
    bool clearResponse = false,
    bool clearError = false,
    bool clearFile = false,
    bool clearPanError = false,
  }) {
    return PanUploadState(
      panNumber: panNumber ?? this.panNumber,
      filePath: clearFile ? null : (filePath ?? this.filePath),
      fileName: clearFile ? null : (fileName ?? this.fileName),
      isSubmitting: isSubmitting ?? this.isSubmitting,
      response: clearResponse ? null : (response ?? this.response),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      panError: clearPanError ? null : (panError ?? this.panError),
    );
  }

  @override
  List<Object?> get props => <Object?>[
    panNumber,
    filePath,
    fileName,
    isSubmitting,
    response,
    errorMessage,
    panError,
  ];
}
