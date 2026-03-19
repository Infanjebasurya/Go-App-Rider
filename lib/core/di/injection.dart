import 'package:get_it/get_it.dart';
import 'package:goapp/core/network/native_network_service.dart';
import 'package:goapp/core/network/directions_route_service.dart';
import 'package:goapp/core/network/network_info.dart';
import 'package:goapp/core/service/network_settings_service.dart';
import 'package:goapp/core/service/network_settings_service_impl.dart';
import 'package:goapp/core/network/network_status_cubit.dart';
import 'package:goapp/core/location/location_permission_guard.dart';
import 'package:goapp/core/service/audio_service.dart';
import 'package:goapp/core/service/app_cleanup_service.dart';
import 'package:goapp/core/service/location_service.dart';
import 'package:goapp/core/service/permission_service.dart';
import 'package:goapp/core/service/vibration_service.dart';
import 'package:goapp/core/service/url_launcher_service.dart';
import 'package:goapp/core/service/contacts_service.dart';
import 'package:goapp/core/service/file_picker_service.dart';
import 'package:goapp/core/service/image_picker_service.dart';
import 'package:goapp/core/service/path_provider_service.dart';
import 'package:goapp/core/storage/shared_preferences_store.dart';
import 'package:goapp/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:goapp/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:goapp/features/auth/domain/services/phone_number_service.dart';
import 'package:goapp/features/auth/domain/repositories/auth_repository.dart';
import 'package:goapp/features/auth/domain/usecases/login_usecase.dart';
import 'package:goapp/features/auth/domain/usecases/request_otp_usecase.dart';
import 'package:goapp/features/auth/domain/usecases/resend_otp_usecase.dart';
import 'package:goapp/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:goapp/features/auth/presentation/cubit/login_form_cubit.dart';
import 'package:goapp/features/auth/presentation/cubit/otp_cubit.dart';
import 'package:goapp/features/about/presentation/cubit/about_cubit.dart';
import 'package:goapp/features/home/data/datasources/captain_remote_data_source.dart';
import 'package:goapp/features/home/data/datasources/online_hours_mock_api.dart';
import 'package:goapp/features/home/data/repositories/captain_repository_impl.dart';
import 'package:goapp/features/home/domain/repositories/captain_repository.dart';
import 'package:goapp/features/home/domain/usecases/get_captain_profile.dart';
import 'package:goapp/features/home/presentation/cubit/available_orders_cubit.dart';
import 'package:goapp/features/home/presentation/cubit/driver_status_cubit.dart';
import 'package:goapp/features/home/presentation/cubit/enter_ride_code_cubit.dart';
import 'package:goapp/features/home/presentation/cubit/home_cubit.dart';
import 'package:goapp/features/home/presentation/cubit/trip_navigation_cubit.dart';
import 'package:goapp/features/documents/presentation/cubit/documents_cubit.dart';
import 'package:goapp/features/documents/presentation/cubit/document_upload_cubit.dart';
import 'package:goapp/features/documents/presentation/services/document_upload_file_service.dart';
import 'package:goapp/features/documents/data/datasources/driving_license_upload_remote_data_source.dart';
import 'package:goapp/features/documents/data/datasources/document_details_remote_data_source.dart';
import 'package:goapp/features/documents/data/datasources/documents_list_remote_data_source.dart';
import 'package:goapp/features/documents/data/datasources/profile_image_upload_remote_data_source.dart';
import 'package:goapp/features/documents/data/datasources/vehicle_rc_upload_remote_data_source.dart';
import 'package:goapp/features/documents/aadhaar_upload/data/repositories/aadhaar_upload_repository_impl.dart';
import 'package:goapp/features/documents/aadhaar_upload/data/services/aadhaar_upload_service.dart';
import 'package:goapp/features/documents/aadhaar_upload/domain/repositories/aadhaar_upload_repository.dart';
import 'package:goapp/features/documents/aadhaar_upload/presentation/cubit/aadhaar_upload_cubit.dart';
import 'package:goapp/features/documents/document_details/data/repositories/document_details_repository_impl.dart';
import 'package:goapp/features/documents/document_details/data/services/document_details_service.dart'
    as doc_details;
import 'package:goapp/features/documents/document_details/domain/repositories/document_details_repository.dart';
import 'package:goapp/features/documents/document_details/presentation/cubit/document_details_cubit.dart';
import 'package:goapp/features/documents/document_status/data/repositories/document_status_repository_impl.dart';
import 'package:goapp/features/documents/document_status/data/services/document_status_service.dart'
    as doc_status;
import 'package:goapp/features/documents/document_status/domain/repositories/document_status_repository.dart';
import 'package:goapp/features/documents/document_status/presentation/cubit/document_status_cubit.dart';
import 'package:goapp/features/documents/pan_upload/data/repositories/pan_upload_repository_impl.dart';
import 'package:goapp/features/documents/pan_upload/data/services/pan_upload_service.dart'
    as pan_upload;
import 'package:goapp/features/documents/pan_upload/domain/repositories/pan_upload_repository.dart';
import 'package:goapp/features/documents/pan_upload/presentation/cubit/pan_upload_cubit.dart';
import 'package:goapp/features/document_verify/data/datasources/submit_all_documents_remote_data_source.dart';
import 'package:goapp/features/document_verify/presentation/cubit/verification_cubit.dart';
import 'package:goapp/features/demand_planner/data/datasources/demand_planner_mock_api.dart';
import 'package:goapp/features/demand_planner/presentation/cubit/demand_planner_cubit.dart';
import 'package:goapp/features/earnings/data/datasources/earnings_wallet_mock_api.dart';
import 'package:goapp/features/earnings/data/repositories/earnings_repository_impl.dart';
import 'package:goapp/features/earnings/domain/repositories/earnings_repository.dart';
import 'package:goapp/features/earnings/domain/usecases/get_earnings_snapshot_usecase.dart';
import 'package:goapp/features/earnings/domain/usecases/get_wallet_transactions_usecase.dart';
import 'package:goapp/features/earnings/presentation/cubit/earnings_cubit.dart';
import 'package:goapp/features/help_support/presentation/cubit/emergency_contacts_cubit.dart';
import 'package:goapp/features/help_support/presentation/cubit/help_cubit.dart';
import 'package:goapp/features/help_support/presentation/cubit/safety_preference_cubit.dart';
import 'package:goapp/features/help_support/data/repositories/earnings_help_repository_mock.dart';
import 'package:goapp/features/help_support/data/repositories/account_help_repository_mock.dart';
import 'package:goapp/features/help_support/data/repositories/app_issues_help_repository_mock.dart';
import 'package:goapp/features/help_support/domain/repositories/earnings_help_repository.dart';
import 'package:goapp/features/help_support/domain/repositories/account_help_repository.dart';
import 'package:goapp/features/help_support/domain/repositories/app_issues_help_repository.dart';
import 'package:goapp/features/help_support/domain/usecases/get_earnings_help_article_usecase.dart';
import 'package:goapp/features/help_support/domain/usecases/get_earnings_help_faqs_usecase.dart';
import 'package:goapp/features/help_support/domain/usecases/get_earnings_help_links_usecase.dart';
import 'package:goapp/features/help_support/domain/usecases/get_account_help_links_usecase.dart';
import 'package:goapp/features/help_support/domain/usecases/get_app_issues_help_links_usecase.dart';
import 'package:goapp/features/help_support/presentation/cubit/earnings_help_cubit.dart';
import 'package:goapp/features/help_support/presentation/cubit/account_help_cubit.dart';
import 'package:goapp/features/help_support/presentation/cubit/app_issues_help_cubit.dart';
import 'package:goapp/features/help_support/data/repositories/support_chat_repository_mock.dart';
import 'package:goapp/features/help_support/domain/repositories/support_chat_repository.dart';
import 'package:goapp/features/help_support/domain/usecases/get_support_chat_transcript_usecase.dart';
import 'package:goapp/features/help_support/domain/usecases/submit_support_chat_feedback_usecase.dart';
import 'package:goapp/features/help_support/presentation/cubit/support_chat_cubit.dart';
import 'package:goapp/features/incentives/data/datasources/incentives_mock_api.dart';
import 'package:goapp/features/incentives/data/repositories/incentives_repository_impl.dart';
import 'package:goapp/features/incentives/domain/repositories/incentives_repository.dart';
import 'package:goapp/features/incentives/domain/usecases/get_incentives_config_usecase.dart';
import 'package:goapp/features/incentives/presentation/cubit/incentives_cubit.dart';
import 'package:goapp/features/rate_app/data/datasources/rate_app_mock_api.dart';
import 'package:goapp/features/rate_app/data/repositories/rate_app_repository_impl.dart';
import 'package:goapp/features/rate_app/domain/repositories/rate_app_repository.dart';
import 'package:goapp/features/rate_app/domain/usecases/submit_rate_app_review_usecase.dart';
import 'package:goapp/features/rate_app/presentation/cubit/rate_app_cubit.dart';
import 'package:goapp/features/refer_earn/data/datasources/referral_mock_api.dart';
import 'package:goapp/features/refer_earn/presentation/cubit/referral_cubit.dart';
import 'package:goapp/features/ride_complete/data/repositories/ride_complete_repository_impl.dart';
import 'package:goapp/features/ride_complete/domain/repositories/ride_complete_repository.dart';
import 'package:goapp/features/ride_complete/domain/usecases/get_feedback_tags.dart';
import 'package:goapp/features/ride_complete/domain/usecases/get_ride_completion_summary.dart';
import 'package:goapp/features/ride_complete/domain/usecases/submit_ride_feedback.dart';
import 'package:goapp/features/ride_complete/presentation/cubit/rate_experience_cubit.dart';
import 'package:goapp/features/ride_complete/presentation/cubit/ride_completed_cubit.dart';
import 'package:goapp/features/ride_history/data/datasources/ride_history_mock_api.dart';
import 'package:goapp/features/ride_history/data/repositories/ride_history_repository_impl.dart';
import 'package:goapp/features/ride_history/domain/repositories/ride_history_repository.dart';
import 'package:goapp/features/ride_history/domain/usecases/get_ride_history_usecase.dart';
import 'package:goapp/features/ride_history/presentation/cubit/ride_history_cubit.dart';
import 'package:goapp/features/sos/presentation/cubit/sos_cubit.dart';
import 'package:goapp/features/profile/data/repositories/local_profile_repository.dart';
import 'package:goapp/features/profile/domain/repositories/profile_repository.dart';
import 'package:goapp/features/profile/domain/services/profile_validation_service.dart';
import 'package:goapp/features/profile/domain/usecases/create_profile_usecase.dart';
import 'package:goapp/features/profile/domain/usecases/get_cached_profile_usecase.dart';
import 'package:goapp/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:goapp/features/profile/presentation/cubit/profile_edit_cubit.dart';
import 'package:goapp/features/profile/presentation/cubit/profile_setup_cubit.dart';
import 'package:goapp/features/profile_photo_capture/data/repositories/profile_photo_repository_impl.dart';
import 'package:goapp/features/profile_photo_capture/data/services/mlkit_live_face_detection_service_impl.dart';
import 'package:goapp/features/profile_photo_capture/data/services/profile_photo_image_processing_service_impl.dart';
import 'package:goapp/features/profile_photo_capture/domain/services/face_auto_capture_policy.dart';
import 'package:goapp/features/profile_photo_capture/domain/repositories/profile_photo_repository.dart';
import 'package:goapp/features/profile_photo_capture/domain/services/live_face_detection_service.dart';
import 'package:goapp/features/profile_photo_capture/domain/services/profile_photo_image_processing_service.dart';
import 'package:goapp/features/profile_photo_capture/domain/usecases/save_profile_photo_usecase.dart';
import 'package:goapp/features/profile_photo_capture/presentation/cubit/face_profile_photo_capture_cubit.dart';
import 'package:goapp/features/profile_photo_capture/presentation/bloc/profile_photo_bloc.dart';
import 'package:goapp/features/city_vehicle/city_selection/presentation/cubit/city_selection_cubit.dart';
import 'package:goapp/features/city_vehicle/vehicle_details/presentation/cubit/vehicle_details_cubit.dart';
import 'package:goapp/features/city_vehicle/vehicle_selection/presentation/cubit/vehicle_selection_cubit.dart';
import 'package:goapp/features/city_vehicle/vehicle_selection/presentation/model/vehicle_model.dart';
import 'package:goapp/features/network_check/data/repositories/internet_repository_impl.dart';
import 'package:goapp/features/network_check/domain/repositories/internet_repository.dart';
import 'package:goapp/features/network_check/presentation/bloc/internet_bloc.dart';
import 'package:goapp/features/network_check/presentation/bloc/reconnect_overlay_cubit.dart';

final GetIt sl = GetIt.instance;
bool _didInit = false;

Future<void> initializeDependencies() async {
  if (_didInit) return;
  _didInit = true;

  // SharedPrefs must be ready before any store/service uses it.
  await SharedPreferencesStore.init();
  sl.registerLazySingleton<SharedPreferencesStore>(
    () => SharedPreferencesStore.global,
  );

  _registerCore();
  _registerNetworkCheck();
  _registerAuth();
  _registerHome();
  _registerProfile();
  _registerProfilePhotoCapture();
  _registerEarnings();
  _registerIncentives();
  _registerRideHistory();
  _registerRideComplete();
  _registerRateApp();
  _registerReferEarn();
  _registerDemandPlanner();
  _registerDocuments();
  _registerCityVehicle();
  _registerSupport();
  _registerSos();
  _registerAbout();
}

void _registerCore() {
  sl
    ..registerLazySingleton<NativeNetworkService>(() => NativeNetworkService())
    ..registerLazySingleton<NetworkInfo>(
      () => NetworkInfoImpl(sl<NativeNetworkService>()),
    )
    ..registerLazySingleton<NetworkSettingsService>(
      () => NetworkSettingsServiceImpl(),
    )
    ..registerLazySingleton<DirectionsRouteService>(
      () => DirectionsRouteService(),
    )
    ..registerFactory<NetworkStatusCubit>(
      () => NetworkStatusCubit(sl<NetworkInfo>()),
    )
    ..registerLazySingleton<LocationPermissionGuard>(
      () => const LocationPermissionGuard(),
    )
    ..registerLazySingleton<AudioService>(() => AudioService())
    ..registerLazySingleton<VibrationService>(() => const VibrationService())
    ..registerLazySingleton<LocationService>(() => const LocationService())
    ..registerLazySingleton<OnlineHoursMockApi>(
      () => const OnlineHoursMockApi(),
    )
    ..registerLazySingleton<EarningsWalletMockApi>(
      () => EarningsWalletMockApi(sl<SharedPreferencesStore>()),
    )
    ..registerLazySingleton<ImagePickerService>(() => ImagePickerService())
    ..registerLazySingleton<FilePickerService>(() => const FilePickerService())
    ..registerLazySingleton<PathProviderService>(
      () => const PathProviderService(),
    )
    ..registerLazySingleton<DocumentUploadFileService>(
      () => DocumentUploadFileService(
        pathProvider: sl(),
        permissionService: sl(),
      ),
    )
    ..registerLazySingleton<AppCleanupService>(
      () => AppCleanupService(fileService: sl()),
    )
    ..registerLazySingleton<PermissionService>(() => const PermissionService())
    ..registerLazySingleton<UrlLauncherService>(
      () => const UrlLauncherService(),
    )
    ..registerLazySingleton<ContactsService>(() => const ContactsService())
    ..registerLazySingleton<PhoneNumberService>(() => PhoneNumberService())
    ..registerLazySingleton<ProfileValidationService>(
      () => ProfileValidationService(),
    );
}

void _registerAuth() {
  sl
    ..registerLazySingleton<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl(),
    )
    ..registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(sl<AuthRemoteDataSource>()),
    )
    ..registerLazySingleton<LoginUseCase>(
      () => LoginUseCase(sl<AuthRepository>()),
    )
    ..registerLazySingleton<RequestOtpUseCase>(
      () => RequestOtpUseCase(sl<AuthRepository>()),
    )
    ..registerLazySingleton<ResendOtpUseCase>(
      () => ResendOtpUseCase(sl<AuthRepository>()),
    )
    ..registerFactory<AuthBloc>(() => AuthBloc(sl(), sl()))
    ..registerFactory<LoginFormCubit>(
      () => LoginFormCubit(phoneNumberService: sl()),
    )
    ..registerFactory<OtpCubit>(() => OtpCubit(resendOtpUseCase: sl()));
}

void _registerHome() {
  sl
    ..registerLazySingleton<CaptainRemoteDataSource>(
      () => CaptainRemoteDataSourceImpl(),
    )
    ..registerLazySingleton<CaptainRepository>(
      () => CaptainRepositoryImpl(sl<CaptainRemoteDataSource>()),
    )
    ..registerLazySingleton<GetCaptainProfile>(
      () => GetCaptainProfile(sl<CaptainRepository>()),
    )
    ..registerFactory<HomeCubit>(() => HomeCubit(sl<GetCaptainProfile>()))
    ..registerFactory<DriverCubit>(
      () => DriverCubit(locationGuard: sl(), onlineHoursApi: sl()),
    )
    ..registerFactory<DriverStatusCubit>(
      () => DriverStatusCubit(locationGuard: sl()),
    )
    ..registerFactory<TripNavigationCubit>(() => TripNavigationCubit())
    ..registerFactory<AvailableOrdersCubit>(() => AvailableOrdersCubit())
    ..registerFactory<EnterRideCodeCubit>(() => EnterRideCodeCubit());
}

void _registerProfile() {
  sl
    ..registerLazySingleton<ProfileRepository>(() => LocalProfileRepository())
    ..registerLazySingleton<CreateProfileUseCase>(
      () => CreateProfileUseCase(sl()),
    )
    ..registerLazySingleton<GetCachedProfileUseCase>(
      () => GetCachedProfileUseCase(sl()),
    )
    ..registerFactory<ProfileBloc>(
      () => ProfileBloc(sl(), sl(), autoLoad: false),
    )
    ..registerFactory<ProfileSetupCubit>(
      () => ProfileSetupCubit(validationService: sl()),
    )
    ..registerFactory<ProfileEditCubit>(
      () => ProfileEditCubit(getCachedProfileUseCase: sl()),
    );
}

void _registerProfilePhotoCapture() {
  sl
    ..registerLazySingleton<FaceAutoCapturePolicy>(
      () => const FaceAutoCapturePolicy(),
    )
    ..registerFactory<LiveFaceDetectionService>(
      () => MlkitLiveFaceDetectionServiceImpl(),
    )
    ..registerFactory<ProfilePhotoImageProcessingService>(
      () => ProfilePhotoImageProcessingServiceImpl(),
    )
    ..registerLazySingleton<ProfilePhotoRepository>(
      () => ProfilePhotoRepositoryImpl(pathProvider: sl()),
    )
    ..registerLazySingleton<SaveProfilePhotoUseCase>(
      () => SaveProfilePhotoUseCase(sl()),
    )
    ..registerFactory<FaceProfilePhotoCaptureCubit>(
      () => FaceProfilePhotoCaptureCubit(
        permissionService: sl(),
        faceDetectionService: sl(),
        policy: sl(),
        imageProcessingService: sl(),
        saveUseCase: sl(),
      ),
    )
    ..registerFactory<ProfilePhotoBloc>(
      () => ProfilePhotoBloc(
        permissionService: sl(),
        imagePickerService: sl(),
        imageProcessingService: sl(),
        saveUseCase: sl(),
      ),
    );
}

void _registerEarnings() {
  sl
    ..registerLazySingleton<EarningsRepository>(
      () => EarningsRepositoryImpl(api: sl()),
    )
    ..registerLazySingleton<GetEarningsSnapshotUseCase>(
      () => GetEarningsSnapshotUseCase(sl()),
    )
    ..registerLazySingleton<GetWalletTransactionsUseCase>(
      () => GetWalletTransactionsUseCase(sl()),
    )
    ..registerFactory<EarningsCubit>(
      () => EarningsCubit(
        getEarningsSnapshot: sl(),
        getWalletTransactions: sl(),
        walletApi: sl(),
      ),
    );
}

void _registerIncentives() {
  sl
    ..registerLazySingleton<IncentivesMockApi>(() => const IncentivesMockApi())
    ..registerLazySingleton<IncentivesRepository>(
      () => IncentivesRepositoryImpl(api: sl()),
    )
    ..registerLazySingleton<GetIncentivesConfigUseCase>(
      () => GetIncentivesConfigUseCase(sl()),
    )
    ..registerFactory<IncentivesCubit>(
      () => IncentivesCubit(getIncentivesConfig: sl()),
    );
}

void _registerRideHistory() {
  sl
    ..registerLazySingleton<RideHistoryMockApi>(
      () => const RideHistoryMockApi(),
    )
    ..registerLazySingleton<RideHistoryRepository>(
      () => RideHistoryRepositoryImpl(api: sl()),
    )
    ..registerLazySingleton<GetRideHistoryUseCase>(
      () => GetRideHistoryUseCase(sl()),
    )
    ..registerFactory<RideHistoryCubit>(
      () => RideHistoryCubit(getRideHistory: sl()),
    );
}

void _registerRideComplete() {
  sl
    ..registerLazySingleton<RideCompleteRepository>(
      () => RideCompleteRepositoryImpl(),
    )
    ..registerLazySingleton<GetRideCompletionSummary>(
      () => GetRideCompletionSummary(sl()),
    )
    ..registerLazySingleton<GetFeedbackTags>(() => GetFeedbackTags(sl()))
    ..registerLazySingleton<SubmitRideFeedback>(() => SubmitRideFeedback(sl()))
    ..registerFactory<RideCompletedCubit>(() => RideCompletedCubit(sl()))
    ..registerFactory<RateExperienceCubit>(
      () => RateExperienceCubit(sl(), sl()),
    );
}

void _registerRateApp() {
  sl
    ..registerLazySingleton<RateAppMockApi>(() => const RateAppMockApi())
    ..registerLazySingleton<RateAppRepository>(
      () => RateAppRepositoryImpl(api: sl()),
    )
    ..registerLazySingleton<SubmitRateAppReviewUseCase>(
      () => SubmitRateAppReviewUseCase(sl()),
    )
    ..registerFactory<RateAppCubit>(
      () => RateAppCubit(submitRateAppReview: sl()),
    );
}

void _registerReferEarn() {
  sl
    ..registerLazySingleton<ReferralMockApi>(() => const ReferralMockApi())
    ..registerFactory<ReferralCubit>(() => ReferralCubit(mockApi: sl()));
}

void _registerDemandPlanner() {
  sl
    ..registerLazySingleton<DemandPlannerMockApi>(
      () => const DemandPlannerMockApi(),
    )
    ..registerFactory<DemandPlannerCubit>(
      () => DemandPlannerCubit(mockApi: sl()),
    );
}

void _registerDocuments() {
  sl
    ..registerLazySingleton<DocumentDetailsRemoteDataSource>(
      () => DocumentDetailsRemoteDataSourceImpl(),
    )
    ..registerLazySingleton<DocumentsListRemoteDataSource>(
      () => DocumentsListRemoteDataSourceImpl(),
    )
    ..registerLazySingleton<DrivingLicenseUploadRemoteDataSource>(
      () => DrivingLicenseUploadRemoteDataSourceImpl(),
    )
    ..registerLazySingleton<ProfileImageUploadRemoteDataSource>(
      () => ProfileImageUploadRemoteDataSourceImpl(),
    )
    ..registerLazySingleton<VehicleRcUploadRemoteDataSource>(
      () => VehicleRcUploadRemoteDataSourceImpl(),
    )
    ..registerLazySingleton<AadhaarUploadService>(
      () => AadhaarUploadServiceImpl(mode: DataMode.mock),
    )
    ..registerLazySingleton<AadhaarUploadRepository>(
      () => AadhaarUploadRepositoryImpl(service: sl<AadhaarUploadService>()),
    )
    ..registerFactory<AadhaarUploadCubit>(
      () => AadhaarUploadCubit(
        repository: sl<AadhaarUploadRepository>(),
        imagePickerService: sl<ImagePickerService>(),
        filePickerService: sl<FilePickerService>(),
      ),
    )
    ..registerLazySingleton<doc_details.DocumentDetailsService>(
      () => doc_details.DocumentDetailsServiceImpl(
        mode: doc_details.DataMode.mock,
      ),
    )
    ..registerLazySingleton<DocumentDetailsRepository>(
      () => DocumentDetailsRepositoryImpl(
        service: sl<doc_details.DocumentDetailsService>(),
      ),
    )
    ..registerFactory<DocumentDetailsCubit>(
      () => DocumentDetailsCubit(repository: sl<DocumentDetailsRepository>()),
    )
    ..registerLazySingleton<doc_status.DocumentStatusService>(
      () =>
          doc_status.DocumentStatusServiceImpl(mode: doc_status.DataMode.mock),
    )
    ..registerLazySingleton<DocumentStatusRepository>(
      () => DocumentStatusRepositoryImpl(
        service: sl<doc_status.DocumentStatusService>(),
      ),
    )
    ..registerFactory<DocumentStatusCubit>(
      () => DocumentStatusCubit(repository: sl<DocumentStatusRepository>()),
    )
    ..registerLazySingleton<pan_upload.PanUploadService>(
      () => pan_upload.PanUploadServiceImpl(mode: pan_upload.DataMode.mock),
    )
    ..registerLazySingleton<PanUploadRepository>(
      () => PanUploadRepositoryImpl(service: sl<pan_upload.PanUploadService>()),
    )
    ..registerFactory<PanUploadCubit>(
      () => PanUploadCubit(
        repository: sl<PanUploadRepository>(),
        imagePickerService: sl<ImagePickerService>(),
        filePickerService: sl<FilePickerService>(),
      ),
    )
    ..registerFactory<DocumentsCubit>(
      () =>
          DocumentsCubit(remoteDataSource: sl<DocumentsListRemoteDataSource>()),
    )
    ..registerLazySingleton<SubmitAllDocumentsRemoteDataSource>(
      () => SubmitAllDocumentsRemoteDataSourceImpl(),
    )
    ..registerFactory<VerificationCubit>(
      () => VerificationCubit(submitAllDataSource: sl()),
    )
    ..registerFactoryParam<DocumentUploadCubit, int, void>(
      (initialStepIndex, _) => DocumentUploadCubit(
        initialStepIndex: initialStepIndex,
        imagePickerService: sl(),
        filePickerService: sl(),
        fileService: sl(),
        drivingLicenseUploadRemoteDataSource: sl(),
        profileImageUploadRemoteDataSource: sl(),
        vehicleRcUploadRemoteDataSource: sl(),
      ),
    );
}

void _registerCityVehicle() {
  sl
    ..registerFactory<CitySelectionCubit>(() => CitySelectionCubit())
    ..registerFactory<VehicleSelectionCubit>(() => VehicleSelectionCubit())
    ..registerFactoryParam<VehicleDetailsCubit, VehicleType, void>(
      (vehicleType, _) => VehicleDetailsCubit(
        vehicleType: vehicleType,
        imagePickerService: sl(),
        filePickerService: sl(),
        permissionService: sl(),
      ),
    );
}

void _registerSupport() {
  sl
    ..registerFactory<HelpCubit>(() => HelpCubit())
    ..registerFactory<SafetyPreferencesCubit>(() => SafetyPreferencesCubit())
    ..registerFactory<EmergencyContactsCubit>(() => EmergencyContactsCubit())
    ..registerLazySingleton<AccountHelpRepository>(
      () => const AccountHelpRepositoryMock(),
    )
    ..registerLazySingleton<GetAccountHelpLinksUseCase>(
      () => GetAccountHelpLinksUseCase(sl()),
    )
    ..registerFactory<AccountHelpCubit>(() => AccountHelpCubit(getLinks: sl()))
    ..registerLazySingleton<AppIssuesHelpRepository>(
      () => const AppIssuesHelpRepositoryMock(),
    )
    ..registerLazySingleton<GetAppIssuesHelpLinksUseCase>(
      () => GetAppIssuesHelpLinksUseCase(sl()),
    )
    ..registerFactory<AppIssuesHelpCubit>(
      () => AppIssuesHelpCubit(getLinks: sl()),
    )
    ..registerLazySingleton<EarningsHelpRepository>(
      () => const EarningsHelpRepositoryMock(),
    )
    ..registerLazySingleton<GetEarningsHelpLinksUseCase>(
      () => GetEarningsHelpLinksUseCase(sl()),
    )
    ..registerLazySingleton<GetEarningsHelpFaqsUseCase>(
      () => GetEarningsHelpFaqsUseCase(sl()),
    )
    ..registerLazySingleton<GetEarningsHelpArticleUseCase>(
      () => GetEarningsHelpArticleUseCase(sl()),
    )
    ..registerFactory<EarningsHelpCubit>(
      () => EarningsHelpCubit(getLinks: sl()),
    )
    ..registerLazySingleton<SupportChatRepository>(
      () => const SupportChatRepositoryMock(),
    )
    ..registerLazySingleton<GetSupportChatTranscriptUseCase>(
      () => GetSupportChatTranscriptUseCase(sl()),
    )
    ..registerLazySingleton<SubmitSupportChatFeedbackUseCase>(
      () => SubmitSupportChatFeedbackUseCase(sl()),
    )
    ..registerFactory<SupportChatCubit>(
      () => SupportChatCubit(getTranscript: sl(), submitFeedback: sl()),
    );
}

/// Safe for hot-reload: registers Support Chat dependencies if missing.
void ensureSupportChatDependenciesRegistered() {
  if (!sl.isRegistered<SupportChatRepository>()) {
    sl.registerLazySingleton<SupportChatRepository>(
      () => const SupportChatRepositoryMock(),
    );
  }
  if (!sl.isRegistered<GetSupportChatTranscriptUseCase>()) {
    sl.registerLazySingleton<GetSupportChatTranscriptUseCase>(
      () => GetSupportChatTranscriptUseCase(sl()),
    );
  }
  if (!sl.isRegistered<SubmitSupportChatFeedbackUseCase>()) {
    sl.registerLazySingleton<SubmitSupportChatFeedbackUseCase>(
      () => SubmitSupportChatFeedbackUseCase(sl()),
    );
  }
  if (!sl.isRegistered<SupportChatCubit>()) {
    sl.registerFactory<SupportChatCubit>(
      () => SupportChatCubit(getTranscript: sl(), submitFeedback: sl()),
    );
  }
}

/// Safe for hot-reload: registers Earnings Help dependencies if missing.
void ensureEarningsHelpDependenciesRegistered() {
  if (!sl.isRegistered<EarningsHelpRepository>()) {
    sl.registerLazySingleton<EarningsHelpRepository>(
      () => const EarningsHelpRepositoryMock(),
    );
  }
  if (!sl.isRegistered<GetEarningsHelpLinksUseCase>()) {
    sl.registerLazySingleton<GetEarningsHelpLinksUseCase>(
      () => GetEarningsHelpLinksUseCase(sl()),
    );
  }
  if (!sl.isRegistered<GetEarningsHelpFaqsUseCase>()) {
    sl.registerLazySingleton<GetEarningsHelpFaqsUseCase>(
      () => GetEarningsHelpFaqsUseCase(sl()),
    );
  }
  if (!sl.isRegistered<GetEarningsHelpArticleUseCase>()) {
    sl.registerLazySingleton<GetEarningsHelpArticleUseCase>(
      () => GetEarningsHelpArticleUseCase(sl()),
    );
  }
  if (!sl.isRegistered<EarningsHelpCubit>()) {
    sl.registerFactory<EarningsHelpCubit>(
      () => EarningsHelpCubit(getLinks: sl()),
    );
  }
}

void _registerSos() {
  sl.registerFactory<SosCubit>(() => SosCubit());
}

void _registerAbout() {
  sl.registerFactory<AboutCubit>(() => AboutCubit());
}

void _registerNetworkCheck() {
  sl
    ..registerLazySingleton<InternetRepository>(
      () => InternetRepositoryImpl(sl<NetworkInfo>()),
    )
    ..registerLazySingleton<InternetBloc>(
      () => InternetBloc(sl<InternetRepository>()),
    )
    ..registerFactory<ReconnectOverlayCubit>(
      () => ReconnectOverlayCubit(sl<InternetBloc>()),
    );
}
