import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:goapp/core/config/api_config.dart';
import 'package:goapp/core/error/failures.dart';
import 'package:goapp/core/network/api_endpoints.dart';
import 'package:goapp/core/storage/auth_token_store.dart';
import 'package:goapp/core/storage/driver_id_store.dart';
import 'package:goapp/core/storage/user_cache_model.dart';
import 'package:goapp/core/storage/user_cache_store.dart';
import 'package:goapp/features/profile/data/models/get_profile_details_response_model.dart';
import 'package:goapp/features/profile/data/models/onboarding_get_profile_response_model.dart';
import 'package:goapp/features/profile/data/models/onboarding_profile_create_response_model.dart';
import 'package:goapp/features/profile/domain/entities/profile.dart';
import 'package:goapp/features/profile/domain/repositories/profile_repository.dart';
import 'package:goapp/features/profile/presentation/widgets/either.dart';

class LocalProfileRepository implements ProfileRepository {
  LocalProfileRepository({Dio? dio}) : _dio = dio ?? _buildDio() {
    if (dio == null && kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          request: true,
          requestBody: true,
          responseBody: true,
          error: true,
        ),
      );
    }
  }

  Profile? _cached;
  final Dio _dio;

  @override
  Future<Either<Failure, Profile>> createProfile({
    required String name,
    required String gender,
    required String email,
    required String dob,
    required String refer,
    required String emergencyContact,
  }) async {
    final String trimmedName = name.trim();
    final String trimmedGender = gender.trim();
    final String trimmedDob = dob.trim();
    if (trimmedName.isEmpty) {
      return const Left(ServerFailure('Full name is required.'));
    }
    if (trimmedGender.isEmpty) {
      return const Left(ServerFailure('Gender is required.'));
    }
    if (trimmedDob.isEmpty) {
      return const Left(ServerFailure('Date of birth is required.'));
    }

    final existing = UserCacheStore.read();
    final String dobValue = trimmedDob.isEmpty
        ? (existing?.dob ?? '')
        : trimmedDob;

    final String trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty) {
      return const Left(ServerFailure('Email is required.'));
    }
    final Map<String, dynamic> body = <String, dynamic>{
      'full_name': trimmedName,
      'email': trimmedEmail,
      'dob': _toApiDate(trimmedDob),
      'gender': _toOnboardingGender(trimmedGender),
    };

    try {
      if (kDebugMode) {
        debugPrint(
          'Profile API called -> POST '
          '${_dio.options.baseUrl}${ApiEndpoints.onboardingProfile}',
        );
        debugPrint('Profile API request body -> $body');
      }
      final Response<dynamic> response = await _dio.post(
        ApiEndpoints.onboardingProfile,
        data: body,
      );

      if (response.data is! Map<String, dynamic>) {
        return const Left(ServerFailure('Invalid profile response.'));
      }

      final OnboardingProfileCreateResponseModel parsed =
          OnboardingProfileCreateResponseModel.fromJson(
            response.data as Map<String, dynamic>,
          );

      if (kDebugMode) {
        debugPrint('Profile API response -> ${response.data}');
      }

      if (!parsed.success) {
        final message = parsed.message.trim().isEmpty
            ? 'Failed to save profile.'
            : parsed.message.trim();
        return Left(ServerFailure(message));
      }

      final String driverId = (parsed.driverId ?? '').trim();
      if (driverId.isEmpty) {
        return const Left(
          ServerFailure('Invalid profile response (driverId missing).'),
        );
      }

      await DriverIdStore.saveDriverId(driverId);
      if ((parsed.requestId ?? '').trim().isNotEmpty) {
        await DriverIdStore.saveLastProfileRequestId(parsed.requestId!);
      }

      final Profile profile = Profile(
        id: driverId,
        name: trimmedName,
        gender: trimmedGender,
        refer: refer.trim(),
        emergencyContact: emergencyContact.trim(),
        email: trimmedEmail.isEmpty ? null : trimmedEmail,
        phone: existing?.phone,
        dob: dobValue.isEmpty ? null : dobValue,
        rating: existing?.rating ?? 0.0,
        totalTrips: existing?.totalTrips ?? 0,
        totalYears: existing?.totalYears ?? 0.0,
      );

      _cached = profile;
      await UserCacheStore.save(_toCacheModel(profile));
      debugPrint(
        'Profile created successfully -> driverId=${profile.id}, fullName=${profile.name}',
      );
      return Right(profile);
    } on DioException catch (error) {
      return Left(ServerFailure(_mapDioError(error)));
    } catch (error) {
      return Left(ServerFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, Profile?>> getCachedProfile() async {
    final stored = await UserCacheStore.load();
    final Profile? localProfile = stored == null
        ? _cached
        : _fromCacheModel(stored);
    _cached = localProfile;

    final String storedDriverId = (DriverIdStore.driverId() ?? '').trim();
    final String localDriverId = (localProfile?.id ?? '').trim();
    final String driverId =
        storedDriverId.isNotEmpty ? storedDriverId : localDriverId;

    if (driverId.isNotEmpty && driverId != 'local-profile') {
      try {
        final Map<String, dynamic> body = <String, dynamic>{
          'driverId': driverId,
        };
        if (kDebugMode) {
          debugPrint(
            'Onboarding Profile API called -> GET '
            '${_dio.options.baseUrl}${ApiEndpoints.onboardingProfile}',
          );
          debugPrint('Onboarding Profile API request body -> $body');
        }

        final Response<dynamic> response = await _dio.request(
          ApiEndpoints.onboardingProfile,
          data: body,
          queryParameters: <String, dynamic>{'driverId': driverId},
          options: Options(method: 'GET'),
        );

        if (kDebugMode) {
          debugPrint('Onboarding Profile API response -> ${response.data}');
        }

        if (response.data is! Map<String, dynamic>) {
          return const Left(ServerFailure('Invalid profile response.'));
        }

        final OnboardingGetProfileResponseModel parsed =
            OnboardingGetProfileResponseModel.fromJson(
              response.data as Map<String, dynamic>,
            );

        if (!parsed.success) {
          final message = (parsed.message ?? '').trim();
          return Left(
            ServerFailure(
              message.isEmpty ? 'Failed to fetch profile.' : message,
            ),
          );
        }

        final data = parsed.data;
        if (data == null) {
          return const Left(
            ServerFailure('Invalid profile response (data missing).'),
          );
        }

        final resolvedDriverId = data.driverId.trim().isEmpty
            ? driverId
            : data.driverId.trim();

        await DriverIdStore.saveDriverId(resolvedDriverId);

        final Profile remoteProfile = Profile(
          id: resolvedDriverId,
          name: data.fullName.trim(),
          gender: _fromOnboardingGender(data.gender),
          refer: localProfile?.refer ?? '',
          emergencyContact: localProfile?.emergencyContact ?? '',
          email: data.email.trim().isEmpty ? null : data.email.trim(),
          phone: localProfile?.phone,
          dob: data.dob.trim().isEmpty ? null : data.dob.trim(),
          rating: localProfile?.rating ?? 0.0,
          totalTrips: localProfile?.totalTrips ?? 0,
          totalYears: localProfile?.totalYears ?? 0.0,
        );

        _cached = remoteProfile;
        await UserCacheStore.save(_toCacheModel(remoteProfile));
        return Right(remoteProfile);
      } on DioException catch (error) {
        if (_shouldUseStaticFallback(error)) {
          return Right(localProfile);
        }
        return Left(ServerFailure(_mapDioError(error)));
      } catch (error) {
        return Left(ServerFailure(error.toString()));
      }
    }

    final String? accessToken = AuthTokenStore.accessToken();
    if (accessToken == null || accessToken.isEmpty) {
      return Right(localProfile);
    }

    try {
      debugPrint(
        'Profile API called -> GET ${_dio.options.baseUrl}${ApiEndpoints.captainProfile}',
      );
      final Response<dynamic> response = await _dio.get(
        ApiEndpoints.captainProfile,
        options: Options(
          headers: <String, String>{'Authorization': 'Bearer $accessToken'},
        ),
      );

      if (response.data is! Map<String, dynamic>) {
        return Right(localProfile);
      }

      final GetProfileDetailsResponseModel parsed =
          GetProfileDetailsResponseModel.fromJson(
            response.data as Map<String, dynamic>,
          );
      final Profile remoteProfile = parsed.profile.toEntity();
      final Profile mergedProfile = _mergeProfiles(
        remote: remoteProfile,
        local: localProfile,
      );

      _cached = mergedProfile;
      await UserCacheStore.save(_toCacheModel(mergedProfile));
      debugPrint(
        'Profile details fetched -> driverId=${mergedProfile.id}, fullName=${mergedProfile.name}',
      );
      return Right(mergedProfile);
    } on DioException catch (error) {
      if (_shouldUseStaticFallback(error)) {
        return Right(localProfile);
      }
      return Left(ServerFailure(_mapDioError(error)));
    } catch (error) {
      return Left(ServerFailure(error.toString()));
    }
  }

  static Profile _fromCacheModel(LocalUserCacheModel user) {
    return Profile(
      id: user.id,
      name: user.fullName,
      gender: user.gender,
      refer: user.referCode,
      emergencyContact: user.emergencyContact,
      email: user.email,
      phone: user.phone,
      dob: user.dob,
      rating: user.rating,
      totalTrips: user.totalTrips,
      totalYears: user.totalYears,
    );
  }

  static LocalUserCacheModel _toCacheModel(Profile profile) {
    return LocalUserCacheModel(
      id: profile.id,
      fullName: profile.name,
      gender: profile.gender,
      referCode: profile.refer,
      emergencyContact: profile.emergencyContact,
      email: profile.email,
      phone: profile.phone,
      dob: profile.dob,
      rating: profile.rating,
      totalTrips: profile.totalTrips,
      totalYears: profile.totalYears,
    );
  }

  Profile _mergeProfiles({required Profile remote, required Profile? local}) {
    return Profile(
      id: remote.id.isNotEmpty ? remote.id : (local?.id ?? ''),
      name: remote.name.isNotEmpty ? remote.name : (local?.name ?? ''),
      gender: remote.gender.isNotEmpty ? remote.gender : (local?.gender ?? ''),
      refer: remote.refer.isNotEmpty ? remote.refer : (local?.refer ?? ''),
      emergencyContact: remote.emergencyContact.isNotEmpty
          ? remote.emergencyContact
          : (local?.emergencyContact ?? ''),
      email: (remote.email?.isNotEmpty ?? false) ? remote.email : local?.email,
      phone: (remote.phone?.isNotEmpty ?? false) ? remote.phone : local?.phone,
      dob: (remote.dob?.isNotEmpty ?? false) ? remote.dob : local?.dob,
      rating: remote.rating != 0.0 ? remote.rating : (local?.rating ?? 0.0),
      totalTrips: remote.totalTrips != 0
          ? remote.totalTrips
          : (local?.totalTrips ?? 0),
      totalYears: remote.totalYears != 0.0
          ? remote.totalYears
          : (local?.totalYears ?? 0.0),
    );
  }

  String _toApiDate(String value) {
    final List<String> parts = value.trim().split(RegExp(r'\s+'));
    if (parts.length != 3) return value.trim();
    final int? day = int.tryParse(parts[0]);
    final int? year = int.tryParse(parts[2]);
    final int? month = _monthIndex(parts[1]);
    if (day == null || year == null || month == null) {
      return value.trim();
    }
    final String mm = month.toString().padLeft(2, '0');
    final String dd = day.toString().padLeft(2, '0');
    return '$year-$mm-$dd';
  }

  int? _monthIndex(String monthName) {
    switch (monthName.toLowerCase()) {
      case 'january':
        return 1;
      case 'february':
        return 2;
      case 'march':
        return 3;
      case 'april':
        return 4;
      case 'may':
        return 5;
      case 'june':
        return 6;
      case 'july':
        return 7;
      case 'august':
        return 8;
      case 'september':
        return 9;
      case 'october':
        return 10;
      case 'november':
        return 11;
      case 'december':
        return 12;
    }
    return null;
  }

  String _toOnboardingGender(String value) {
    final normalized = value.trim().toLowerCase();
    switch (normalized) {
      case 'male':
      case 'm':
      case 'man':
      case 'boy':
      case 'male.':
        return 'male';
      case 'female':
      case 'f':
      case 'woman':
      case 'girl':
      case 'female.':
        return 'female';
      case 'others':
      case 'other':
      case 'prefer not to say':
      default:
        return 'other';
    }
  }

  String _fromOnboardingGender(String value) {
    final normalized = value.trim().toLowerCase();
    switch (normalized) {
      case 'male':
        return 'Male';
      case 'female':
        return 'Female';
      case 'other':
      case 'others':
      default:
        return 'Others';
    }
  }

  bool _shouldUseStaticFallback(DioException error) {
    if (error.type != DioExceptionType.connectionError) {
      return false;
    }
    final String message = (error.message ?? '').toLowerCase();
    return message.contains('failed host lookup') ||
        message.contains('no address associated with hostname');
  }

  String _mapDioError(DioException error) {
    if (_shouldUseStaticFallback(error)) {
      return 'Unable to resolve server hostname. Please check your internet/VPN and try again.';
    }
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return 'Network failure. Please check your internet connection.';
    }
    if (error.type == DioExceptionType.badCertificate) {
      return 'SSL certificate error. Unable to reach the server securely.';
    }
    final int? statusCode = error.response?.statusCode;
    if (statusCode != null && statusCode >= 500) {
      return 'Server error. Please try again later.';
    }
    final dynamic data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final dynamic message = data['message'] ?? data['error'];
      if (message is String && message.isNotEmpty) {
        return message;
      }
    }
    return 'Failed to save profile.';
  }

  static Dio _buildDio() {
    return Dio(
      BaseOptions(
        baseUrl: ApiConfig.uatBaseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        headers: const <String, String>{
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
  }
}
