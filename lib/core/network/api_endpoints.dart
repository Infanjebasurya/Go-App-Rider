class ApiEndpoints {
  static const String authSendOtp = '/api/v1/auth/send-otp';
  static const String authOtpRequest = '/api/v1/auth/otp/request';
  static const String authVerifyOtp = '/api/v1/auth/otp/verify';
  static const String authLogin = '/auth/login';
  static const String authRequestOtp = '/auth/request-otp';
  static const String authResendOtp = '/auth/resend-otp';
  static const String profileCreate = '/api/v1/profile/create';
  static const String onboardingProfile = '/api/v1/onboarding/profile';
  static const String onboardingProgress = '/api/v1/onboarding/progress';
  static const String onboardingSubmit = '/api/v1/onboarding/submit';
  static const String profileImageUpload = '/api/v1/documents/profile-image';
  static const String drivingLicenseUpload =
      '/api/v1/documents/driving-license';
  static const String vehicleRcUpload = '/api/v1/documents/vehicle-rc';
  static const String documents = '/api/v1/documents';
  static const String submitAllDocuments = '/api/v1/documents/submit-all';
  static const String documentsAadhaar = '/api/v1/documents/aadhaar';
  static const String documentsPan = '/api/v1/documents/pan';
  static const String documentsStatus = '/api/v1/documents/status';
  static const String bankDetails = '/api/v1/bank/details';
  static const String vehicleTypes = '/api/v1/vehicles/types';
  static const String vehicleSelect = '/api/v1/vehicles/select';
  static const String captainProfile = '/v1/captain/profile';
}
