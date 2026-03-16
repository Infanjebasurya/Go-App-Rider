import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:goapp/core/config/api_config.dart';
import 'package:goapp/core/error/failures.dart';
import 'package:goapp/core/network/api_endpoints.dart';
import 'package:goapp/core/storage/auth_token_store.dart';
import 'package:goapp/core/storage/registration_progress_store.dart';
import 'package:goapp/core/storage/user_cache_model.dart';
import 'package:goapp/core/storage/user_cache_store.dart';
import 'package:goapp/features/profile/data/models/get_profile_details_response_model.dart';
import 'package:goapp/features/profile/domain/entities/profile.dart';
import 'package:goapp/features/profile/domain/repositories/profile_repository.dart';
import 'package:goapp/features/profile/presentation/widgets/either.dart';

class LocalProfileRepository implements ProfileRepository {
  LocalProfileRepository({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: ApiConfig.uatBaseUrl,
              connectTimeout: const Duration(seconds: 20),
              receiveTimeout: const Duration(seconds: 20),
              headers: const <String, String>{
                'Content-Type': 'application/json',
              },
            ),
          );

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
    final String dobValue = trimmedDob.isEmpty ? (existing?.dob ?? '') : trimmedDob;
    final RegistrationProgress progress = await RegistrationProgressStore.load();
    final String city = (progress.cityId ?? 'Chennai').trim();
    if (city.isEmpty) {
      return const Left(ServerFailure('City is required.'));
    }

    final Map<String, dynamic> body = <String, dynamic>{
      'fullName': trimmedName,
      if (email.trim().isNotEmpty) 'email': email.trim(),
      'gender': trimmedGender,
      'dateOfBirth': _toApiDate(trimmedDob),
      if (refer.trim().isNotEmpty) 'referralCode': refer.trim(),
      'city': city,
    };

    final String? accessToken = AuthTokenStore.accessToken();
    if (accessToken == null || accessToken.isEmpty) {
      final Profile localProfile = _buildLocalProfile(
        existing: existing,
        name: trimmedName,
        email: email,
        gender: trimmedGender,
        dobValue: dobValue,
        refer: refer,
        emergencyContact: emergencyContact,
      );
      _cached = localProfile;
      await UserCacheStore.save(_toCacheModel(localProfile));
      return Right(localProfile);
    }

    try {
      final Response<dynamic> response = await _dio.post(
        ApiEndpoints.profileCreate,
        data: body,
        options: Options(
          headers: <String, String>{'Authorization': 'Bearer $accessToken'},
        ),
      );

      if (response.data is! Map<String, dynamic>) {
        return const Left(ServerFailure('Invalid profile response.'));
      }

      final GetProfileDetailsResponseModel parsed =
          GetProfileDetailsResponseModel.fromJson(
            response.data as Map<String, dynamic>,
          );
      final Profile profile = parsed.profile.toEntity().copyWith(
        name: trimmedName,
        gender: trimmedGender,
        refer: refer.trim(),
        emergencyContact: emergencyContact.trim(),
        email: email.trim().isEmpty ? null : email.trim(),
        phone: (parsed.profile.phone?.isEmpty ?? true)
            ? existing?.phone
            : parsed.profile.phone,
        dob: _toApiDate(trimmedDob),
      );

      _cached = profile;
      await UserCacheStore.save(_toCacheModel(profile));
      debugPrint(
        'Profile created successfully -> driverId=${profile.id}, fullName=${profile.name}',
      );
      return Right(profile);
    } on DioException catch (error) {
      if (_shouldUseStaticFallback(error)) {
        final Profile localProfile = _buildLocalProfile(
          existing: existing,
          name: trimmedName,
          email: email,
          gender: trimmedGender,
          dobValue: _toApiDate(trimmedDob),
          refer: refer,
          emergencyContact: emergencyContact,
        );
        _cached = localProfile;
        await UserCacheStore.save(_toCacheModel(localProfile));
        debugPrint(
          'Profile created locally (fallback) -> driverId=${localProfile.id}, fullName=${localProfile.name}',
        );
        return Right(localProfile);
      }
      return Left(ServerFailure(_mapDioError(error)));
    } catch (error) {
      return Left(ServerFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, Profile?>> getCachedProfile() async {
    final stored = await UserCacheStore.load();
    final Profile? localProfile = stored == null ? _cached : _fromCacheModel(stored);
    _cached = localProfile;

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

  Profile _buildLocalProfile({
    required LocalUserCacheModel? existing,
    required String name,
    required String email,
    required String gender,
    required String dobValue,
    required String refer,
    required String emergencyContact,
  }) {
    return Profile(
      id: existing?.id.isNotEmpty == true ? existing!.id : 'local-profile',
      name: name,
      gender: gender,
      refer: refer.trim(),
      emergencyContact: emergencyContact.trim(),
      email: email.trim().isEmpty ? null : email.trim(),
      phone: existing?.phone,
      dob: dobValue,
      rating: existing?.rating ?? 0.0,
      totalTrips: existing?.totalTrips ?? 0,
      totalYears: existing?.totalYears ?? 0.0,
    );
  }

  Profile _mergeProfiles({
    required Profile remote,
    required Profile? local,
  }) {
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

  bool _shouldUseStaticFallback(DioException error) {
    if (error.type != DioExceptionType.connectionError) {
      return false;
    }
    final String message = (error.message ?? '').toLowerCase();
    return message.contains('failed host lookup') ||
        message.contains('no address associated with hostname');
  }

  String _mapDioError(DioException error) {
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
}
