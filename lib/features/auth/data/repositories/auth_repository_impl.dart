import 'package:dartz/dartz.dart';
import 'package:goapp/core/error/failures.dart';
import 'package:goapp/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:goapp/features/auth/domain/entities/user.dart';
import 'package:goapp/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._remoteDataSource);

  final AuthRemoteDataSource _remoteDataSource;

  @override
  Future<Either<Failure, User>> login({
    required String phone,
    required String otp,
    required String otpId,
  }) async {
    try {
      final response = await _remoteDataSource.login(
        phone: phone,
        otp: otp,
        otpId: otpId,
      );
      return Right<Failure, User>(response.user);
    } on Exception catch (e) {
      return Left<Failure, User>(ServerFailure(_normalizeMessage(e)));
    }
  }

  @override
  Future<Either<Failure, String>> requestOtp({required String phone}) async {
    try {
      final otpId = await _remoteDataSource.requestOtp(phone: phone);
      return Right<Failure, String>(otpId);
    } on Exception catch (e) {
      return Left<Failure, String>(ServerFailure(_normalizeMessage(e)));
    }
  }

  @override
  Future<Either<Failure, String>> resendOtp({required String phone}) async {
    try {
      final message = await _remoteDataSource.resendOtp(phone: phone);
      return Right<Failure, String>(message);
    } on Exception catch (e) {
      return Left<Failure, String>(ServerFailure(_normalizeMessage(e)));
    }
  }

  String _normalizeMessage(Exception error) {
    return error.toString().replaceFirst('Exception: ', '');
  }
}
