import 'package:equatable/equatable.dart';

enum DocumentStep {
  profilePhoto,
  drivingLicense,
  vehicleRC,
  identityAadhaar,
  identityPan,
  bankAccount,
}

enum DocumentUploadType { image, document }

class StepConfig {
  final DocumentStep step;
  final String title;
  final String subtitle;
  final String numberLabel;
  final String numberHint;
  final String numberExample;
  final String expiryLabel;
  final String expiryHint;
  final String allowedPattern;
  final bool forceUppercase;
  final int? maxLength;
  final bool isBankStep;
  final bool isProfileStep;
  final bool requiresBackSide;
  final bool requiresExpiryDate;
  final String frontLabel;
  final String backLabel;

  const StepConfig({
    required this.step,
    required this.title,
    required this.subtitle,
    required this.numberLabel,
    required this.numberHint,
    required this.allowedPattern,
    this.forceUppercase = false,
    this.numberExample = '',
    this.expiryLabel = '',
    this.expiryHint = '',
    this.maxLength,
    this.isBankStep = false,
    this.isProfileStep = false,
    this.requiresBackSide = true,
    this.requiresExpiryDate = false,
    this.frontLabel = 'Front Side',
    this.backLabel = 'Back Side',
  });
}

const List<StepConfig> kStepConfigs = [
  StepConfig(
    step: DocumentStep.profilePhoto,
    title: 'Profile Photo',
    subtitle: 'Upload a clear profile picture',
    numberLabel: '',
    numberHint: '',
    allowedPattern: r'[A-Za-z0-9]',
    isProfileStep: true,
  ),
  StepConfig(
    step: DocumentStep.drivingLicense,
    title: 'Driving License',
    subtitle: 'Driving Certificate',
    numberLabel: 'Driving License Number',
    numberHint: 'Mh022354851253',
    numberExample: 'Example: MH1220180012345',
    expiryLabel: 'Expiry Date',
    expiryHint: 'YYYY-MM-DD',
    allowedPattern: r'[A-Za-z0-9]',
    forceUppercase: true,
    maxLength: 15,
    requiresBackSide: true,
    requiresExpiryDate: false,
    frontLabel: 'Front Side',
    backLabel: 'Back Side',
  ),
  StepConfig(
    step: DocumentStep.vehicleRC,
    title: 'Vehicle RC',
    subtitle: 'Registration Certificate',
    numberLabel: 'Vehicle Number',
    numberHint: 'TN01AB1234',
    numberExample: 'Example: TN01AB1234',
    allowedPattern: r'[A-Za-z0-9]',
    forceUppercase: true,
    maxLength: 10,
    requiresBackSide: true,
    frontLabel: 'Front Side',
    backLabel: 'Back Side',
  ),
  StepConfig(
    step: DocumentStep.identityAadhaar,
    title: 'Aadhaar Verification',
    subtitle: 'Upload your Aadhaar for quick approval',
    numberLabel: 'Aadhaar Number',
    numberHint: '1234 5678 9012',
    numberExample: 'Example: 2018 0012 3453',
    allowedPattern: r'[0-9]',
    maxLength: 12,
  ),
  StepConfig(
    step: DocumentStep.identityPan,
    title: 'Pan Verification',
    subtitle: 'Upload your Pan for quick approval',
    numberLabel: 'Pan Number',
    numberHint: 'ABCDE1231P',
    numberExample: 'Example: AKCDE1531P',
    allowedPattern: r'[A-Za-z0-9]',
    forceUppercase: true,
    maxLength: 10,
    requiresBackSide: false,
  ),
  StepConfig(
    step: DocumentStep.bankAccount,
    title: 'Link Bank Account',
    subtitle: 'Securely link your account for direct payouts',
    numberLabel: '',
    numberHint: '',
    allowedPattern: r'[A-Za-z0-9]',
    isBankStep: true,
  ),
];

class BankAccountData extends Equatable {
  final String accountHolderName;
  final String bankName;
  final String accountNumber;
  final String confirmAccountNumber;
  final String ifscCode;
  final String? bankDocumentPath;
  final DocumentUploadType? bankDocumentType;
  final String? nameError;
  final String? bankNameError;
  final String? accountNumberError;
  final String? confirmAccountNumberError;
  final String? ifscError;
  final String? bankDocumentError;

  const BankAccountData({
    this.accountHolderName = '',
    this.bankName = '',
    this.accountNumber = '',
    this.confirmAccountNumber = '',
    this.ifscCode = '',
    this.bankDocumentPath,
    this.bankDocumentType,
    this.nameError,
    this.bankNameError,
    this.accountNumberError,
    this.confirmAccountNumberError,
    this.ifscError,
    this.bankDocumentError,
  });

  bool get hasErrors =>
      nameError != null ||
      bankNameError != null ||
      accountNumberError != null ||
      confirmAccountNumberError != null ||
      ifscError != null ||
      bankDocumentError != null;

  bool get isComplete =>
      bankName.trim().isNotEmpty &&
      accountNumber.trim().isNotEmpty &&
      confirmAccountNumber.trim().isNotEmpty &&
      confirmAccountNumber == accountNumber &&
      ifscCode.trim().isNotEmpty &&
      bankDocumentPath != null &&
      bankDocumentPath!.trim().isNotEmpty;

  BankAccountData copyWith({
    String? accountHolderName,
    String? bankName,
    String? accountNumber,
    String? confirmAccountNumber,
    String? ifscCode,
    String? bankDocumentPath,
    DocumentUploadType? bankDocumentType,
    String? nameError,
    String? bankNameError,
    String? accountNumberError,
    String? confirmAccountNumberError,
    String? ifscError,
    String? bankDocumentError,
    bool clearNameError = false,
    bool clearBankNameError = false,
    bool clearAccountNumberError = false,
    bool clearConfirmError = false,
    bool clearIfscError = false,
    bool clearBankDocumentError = false,
    bool clearBankDocument = false,
  }) {
    return BankAccountData(
      accountHolderName: accountHolderName ?? this.accountHolderName,
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      confirmAccountNumber: confirmAccountNumber ?? this.confirmAccountNumber,
      ifscCode: ifscCode ?? this.ifscCode,
      bankDocumentPath: clearBankDocument
          ? null
          : (bankDocumentPath ?? this.bankDocumentPath),
      bankDocumentType: clearBankDocument
          ? null
          : (bankDocumentType ?? this.bankDocumentType),
      nameError: clearNameError ? null : (nameError ?? this.nameError),
      bankNameError: clearBankNameError
          ? null
          : (bankNameError ?? this.bankNameError),
      accountNumberError: clearAccountNumberError
          ? null
          : (accountNumberError ?? this.accountNumberError),
      confirmAccountNumberError: clearConfirmError
          ? null
          : (confirmAccountNumberError ?? this.confirmAccountNumberError),
      ifscError: clearIfscError ? null : (ifscError ?? this.ifscError),
      bankDocumentError: clearBankDocumentError
          ? null
          : (bankDocumentError ?? this.bankDocumentError),
    );
  }

  @override
  List<Object?> get props => [
    accountHolderName,
    bankName,
    accountNumber,
    confirmAccountNumber,
    ifscCode,
    bankDocumentPath,
    bankDocumentType,
    nameError,
    bankNameError,
    accountNumberError,
    confirmAccountNumberError,
    ifscError,
    bankDocumentError,
  ];
}

class StepData extends Equatable {
  final DocumentStep step;
  final bool frontCaptured;
  final bool backCaptured;
  final String? frontPath;
  final String? backPath;
  final DocumentUploadType? frontType;
  final DocumentUploadType? backType;
  final String documentNumber;
  final String expiryDate;
  final String? numberError;
  final String? expiryDateError;
  final String? imageError;

  const StepData({
    required this.step,
    this.frontCaptured = false,
    this.backCaptured = false,
    this.frontPath,
    this.backPath,
    this.frontType,
    this.backType,
    this.documentNumber = '',
    this.expiryDate = '',
    this.numberError,
    this.expiryDateError,
    this.imageError,
  });

  bool get isNumberValid => documentNumber.trim().isNotEmpty;
  bool get isProfileStep => step == DocumentStep.profilePhoto;
  bool get requiresBackSide =>
      step != DocumentStep.identityPan && step != DocumentStep.profilePhoto;

  bool get requiresExpiryDate => false;

  bool get isComplete {
    if (isProfileStep) return frontCaptured;
    if (step == DocumentStep.drivingLicense) {
      return frontCaptured && isNumberValid;
    }
    if (step == DocumentStep.vehicleRC) {
      return frontCaptured && isNumberValid;
    }
    if (step == DocumentStep.identityPan) {
      return frontCaptured && isNumberValid;
    }
    return frontCaptured && backCaptured && isNumberValid;
  }

  StepData copyWith({
    bool? frontCaptured,
    bool? backCaptured,
    String? frontPath,
    String? backPath,
    DocumentUploadType? frontType,
    DocumentUploadType? backType,
    String? documentNumber,
    String? expiryDate,
    String? numberError,
    bool clearError = false,
    String? expiryDateError,
    bool clearExpiryError = false,
    String? imageError,
    bool clearImageError = false,
    bool clearFrontUpload = false,
    bool clearBackUpload = false,
  }) {
    return StepData(
      step: step,
      frontCaptured: frontCaptured ?? this.frontCaptured,
      backCaptured: backCaptured ?? this.backCaptured,
      frontPath: clearFrontUpload ? null : (frontPath ?? this.frontPath),
      backPath: clearBackUpload ? null : (backPath ?? this.backPath),
      frontType: clearFrontUpload ? null : (frontType ?? this.frontType),
      backType: clearBackUpload ? null : (backType ?? this.backType),
      documentNumber: documentNumber ?? this.documentNumber,
      expiryDate: expiryDate ?? this.expiryDate,
      numberError: clearError ? null : (numberError ?? this.numberError),
      expiryDateError: clearExpiryError
          ? null
          : (expiryDateError ?? this.expiryDateError),
      imageError: clearImageError ? null : (imageError ?? this.imageError),
    );
  }

  @override
  List<Object?> get props => [
    step,
    frontCaptured,
    backCaptured,
    frontPath,
    backPath,
    frontType,
    backType,
    documentNumber,
    expiryDate,
    numberError,
    expiryDateError,
    imageError,
  ];
}

class DocumentUploadState extends Equatable {
  final int currentStepIndex;
  final List<StepData> steps;
  final BankAccountData bankData;
  final bool isSubmitting;
  final bool isAllDone;
  final bool isProfileImageProcessing;
  final String? statusMessage;
  final bool statusIsError;

  const DocumentUploadState({
    this.currentStepIndex = 0,
    required this.steps,
    this.bankData = const BankAccountData(),
    this.isSubmitting = false,
    this.isAllDone = false,
    this.isProfileImageProcessing = false,
    this.statusMessage,
    this.statusIsError = false,
  });

  factory DocumentUploadState.initial() => DocumentUploadState(
    currentStepIndex: 0,
    steps: [
      DocumentStep.profilePhoto,
      DocumentStep.drivingLicense,
      DocumentStep.vehicleRC,
      DocumentStep.identityAadhaar,
      DocumentStep.identityPan,
    ].map((s) => StepData(step: s)).toList(),
    bankData: const BankAccountData(),
  );

  int get totalSteps => steps.length + 1;

  bool get isCurrentStepBank => currentStepIndex == steps.length;

  bool get isCurrentStepProfile =>
      !isCurrentStepBank && currentDocStep.isProfileStep;

  StepData get currentDocStep => steps[currentStepIndex];

  StepConfig get currentConfig => kStepConfigs[currentStepIndex];

  bool get isLastStep => currentStepIndex == totalSteps - 1;

  bool get canGoBack => currentStepIndex > 0;

  int get completedCount {
    int count = steps.where((s) => s.isComplete).length;
    if (bankData.isComplete) count++;
    return count;
  }

  DocumentUploadState copyWithDocStep(StepData updated) {
    final newSteps = List<StepData>.from(steps);
    newSteps[currentStepIndex] = updated;
    return copyWith(steps: newSteps);
  }

  DocumentUploadState copyWith({
    int? currentStepIndex,
    List<StepData>? steps,
    BankAccountData? bankData,
    bool? isSubmitting,
    bool? isAllDone,
    bool? isProfileImageProcessing,
    String? statusMessage,
    bool clearStatusMessage = false,
    bool? statusIsError,
  }) {
    return DocumentUploadState(
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      steps: steps ?? this.steps,
      bankData: bankData ?? this.bankData,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isAllDone: isAllDone ?? this.isAllDone,
      isProfileImageProcessing:
          isProfileImageProcessing ?? this.isProfileImageProcessing,
      statusMessage: clearStatusMessage
          ? null
          : (statusMessage ?? this.statusMessage),
      statusIsError: statusIsError ?? this.statusIsError,
    );
  }

  @override
  List<Object?> get props => [
    currentStepIndex,
    steps,
    bankData,
    isSubmitting,
    isAllDone,
    isProfileImageProcessing,
    statusMessage,
    statusIsError,
  ];
}
