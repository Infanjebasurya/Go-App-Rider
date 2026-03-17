import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goapp/core/storage/user_cache_store.dart';
import 'package:goapp/features/profile/domain/usecases/get_cached_profile_usecase.dart';
import 'package:goapp/features/profile/presentation/cubit/profile_edit_state.dart';

class ProfileEditCubit extends Cubit<ProfileEditState> {
  ProfileEditCubit({
    required GetCachedProfileUseCase getCachedProfileUseCase,
    Duration saveDelay = const Duration(milliseconds: 700),
    Duration statusResetDelay = const Duration(milliseconds: 400),
    Duration actionDelay = const Duration(milliseconds: 800),
  }) : _getCachedProfileUseCase = getCachedProfileUseCase,
       _saveDelay = saveDelay,
       _statusResetDelay = statusResetDelay,
       _actionDelay = actionDelay,
       super(const ProfileEditState()) {
    loadProfile();
  }

  final GetCachedProfileUseCase _getCachedProfileUseCase;
  final Duration _saveDelay;
  final Duration _statusResetDelay;
  final Duration _actionDelay;

  Future<void> loadProfile() async {
    emit(state.copyWith(status: ProfileEditStatus.loading, errorMessage: null));
    final result = await _getCachedProfileUseCase.call();
    result.fold(
      (failure) {
        if (state.data != null) {
          emit(
            state.copyWith(
              status: ProfileEditStatus.loaded,
              errorMessage: failure.message,
            ),
          );
          return;
        }
        emit(
          state.copyWith(
            status: ProfileEditStatus.error,
            errorMessage: failure.message,
          ),
        );
      },
      (profile) {
        if (profile == null) {
          emit(
            state.copyWith(
              status: ProfileEditStatus.error,
              errorMessage: 'Profile not found.',
            ),
          );
          return;
        }
        emit(
          state.copyWith(
            status: ProfileEditStatus.loaded,
            errorMessage: null,
            data: ProfileEditData(
              fullName: profile.name,
              email: profile.email ?? '',
              phone: profile.phone ?? '',
              gender: profile.gender,
              dateOfBirth: profile.dob ?? '',
              rating: profile.rating,
              totalTrips: profile.totalTrips,
              totalYears: profile.totalYears,
            ),
          ),
        );
      },
    );
  }

  Future<void> updateFullName(String name) async {
    if (state.data == null || name.trim().isEmpty) return;
    emit(state.copyWith(status: ProfileEditStatus.saving));
    await Future<void>.delayed(_saveDelay);
    emit(
      state.copyWith(
        status: ProfileEditStatus.saved,
        data: state.data!.copyWith(fullName: name.trim()),
      ),
    );
    final cached = UserCacheStore.read();
    if (cached != null) {
      await UserCacheStore.save(cached.copyWith(fullName: name.trim()));
    }
    await Future<void>.delayed(_statusResetDelay);
    emit(state.copyWith(status: ProfileEditStatus.loaded));
  }

  Future<void> updateEmail(String email) async {
    if (state.data == null || email.trim().isEmpty) return;
    emit(state.copyWith(status: ProfileEditStatus.saving));
    await Future<void>.delayed(_saveDelay);
    emit(
      state.copyWith(
        status: ProfileEditStatus.saved,
        data: state.data!.copyWith(email: email.trim()),
      ),
    );
    final cached = UserCacheStore.read();
    if (cached != null) {
      await UserCacheStore.save(
        cached.copyWith(email: email.trim().isEmpty ? null : email.trim()),
      );
    }
    await Future<void>.delayed(_statusResetDelay);
    emit(state.copyWith(status: ProfileEditStatus.loaded));
  }

  Future<void> logout() async {
    emit(state.copyWith(status: ProfileEditStatus.saving));
    await Future<void>.delayed(_actionDelay);
    emit(state.copyWith(status: ProfileEditStatus.loggedOut));
  }

  Future<void> deleteAccount() async {
    emit(state.copyWith(status: ProfileEditStatus.saving));
    await Future<void>.delayed(_actionDelay);
    emit(state.copyWith(status: ProfileEditStatus.deleted));
  }
}
