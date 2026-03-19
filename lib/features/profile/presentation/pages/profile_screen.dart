import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goapp/core/service/app_cleanup_service.dart';
import 'package:goapp/core/storage/home_trip_resume_store.dart';
import 'package:goapp/core/storage/registration_progress_store.dart';
import 'package:goapp/core/storage/ride_history_store.dart';
import 'package:goapp/core/storage/text_field_store.dart';
import 'package:goapp/core/storage/trip_session_store.dart';
import 'package:goapp/core/storage/user_cache_store.dart';
import 'package:goapp/features/auth/presentation/pages/r_login_page.dart';
import 'package:goapp/features/auth/presentation/theme/auth_ui_tokens.dart';
import 'package:goapp/features/auth/presentation/widgets/snackbar_utils.dart';
import 'package:goapp/features/profile/presentation/cubit/profile_edit_cubit.dart';
import 'package:goapp/features/profile/presentation/cubit/profile_edit_state.dart';
import 'package:goapp/features/profile/presentation/pages/profile_screen/widgets/profile_edit_field_sheet.dart';
import 'package:goapp/features/profile/presentation/pages/profile_screen/widgets/profile_header.dart';
import 'package:goapp/features/profile/presentation/pages/profile_screen/widgets/profile_logout_button.dart';
import 'package:goapp/features/profile/presentation/pages/profile_screen/widgets/profile_menu_section.dart';
import 'package:goapp/features/profile/presentation/pages/profile_screen/widgets/profile_stats.dart';
import 'package:goapp/core/di/injection.dart';

import 'package:goapp/core/theme/app_colors.dart';
import 'package:goapp/core/widgets/app_app_bar.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProfileEditCubit>(
      create: (_) => sl<ProfileEditCubit>(),
      child: const _ProfileView(),
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppAppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text('Profile Details'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.hexFFEEEEEE, height: 1),
        ),
      ),
      body: BlocConsumer<ProfileEditCubit, ProfileEditState>(
        listenWhen: (previous, current) {
          final isLogoutFlow =
              current.status == ProfileEditStatus.loggedOut ||
              current.status == ProfileEditStatus.deleted;
          final didChangeMessage =
              previous.errorMessage != current.errorMessage &&
              current.errorMessage != null;
          return isLogoutFlow || didChangeMessage;
        },
        listener: (BuildContext context, ProfileEditState state) {
          final message = state.errorMessage;
          if (message != null && message.trim().isNotEmpty) {
            SnackBarUtils.showError(context, message.trim());
          }
          if (state.status == ProfileEditStatus.loggedOut ||
              state.status == ProfileEditStatus.deleted) {
            final isDelete = state.status == ProfileEditStatus.deleted;
            _clearSessionCache(isDeleteAccount: isDelete).whenComplete(() {
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const RLoginPage()),
                (route) => false,
              );
            });
          }
        },
        builder: (BuildContext context, ProfileEditState state) {
          if ((state.status == ProfileEditStatus.loading ||
                  state.status == ProfileEditStatus.initial) &&
              state.data == null) {
            return const Center(
              child: CircularProgressIndicator(color: AuthUiColors.brandGreen),
            );
          }
          if (state.status == ProfileEditStatus.error && state.data == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      state.errorMessage?.trim().isNotEmpty == true
                          ? state.errorMessage!.trim()
                          : 'Failed to load profile.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () =>
                          context.read<ProfileEditCubit>().loadProfile(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (state.data == null) {
            return const Center(child: Text('Profile not found.'));
          }
          return Stack(
            children: [
              _ProfileBody(data: state.data!),
              if (state.status == ProfileEditStatus.loading)
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(
                    minHeight: 2,
                    color: AuthUiColors.brandGreen,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _clearSessionCache({required bool isDeleteAccount}) async {
    await RideHistoryStore.clearAll();
    await HomeTripResumeStore.clear();
    await TripSessionStore.clearAll();
    if (isDeleteAccount) {
      final cleanupService = sl<AppCleanupService>();
      await cleanupService.clearKycDraftsAndSensitiveFiles();
      await UserCacheStore.clear();
    }
    await RegistrationProgressStore.resetForSignedOut(
      showLoginOnNextLaunch: true,
    );
    if (isDeleteAccount) {
      await TextFieldStore.clearAll();
    }
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({required this.data});

  final ProfileEditData data;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ProfileHeader(data: data),
          const SizedBox(height: 18),
          ProfileStatsCard(data: data),
          const SizedBox(height: 18),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          const SizedBox(height: 18),
          ProfileMenuSection(
            data: data,
            onEditEmail: () => _showEditEmailSheet(context, data.email),
            onLogout: () => _showLogoutSheet(context),
            onDelete: () => _showDeleteSheet(context),
          ),
        ],
      ),
    );
  }

  void _showEditEmailSheet(BuildContext context, String current) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (_) => BlocProvider<ProfileEditCubit>.value(
        value: context.read<ProfileEditCubit>(),
        child: ProfileEditFieldSheet(
          title: 'Enter Your Email Address',
          icon: Icons.mail_outline,
          initialValue: current,
          storageKey: 'profile_edit.email',
          keyboardType: TextInputType.emailAddress,
          onSave: (String val) =>
              context.read<ProfileEditCubit>().updateEmail(val),
        ),
      ),
    );
  }

  void _showLogoutSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (_) => BlocProvider<ProfileEditCubit>.value(
        value: context.read<ProfileEditCubit>(),
        child: ProfileConfirmActionSheet(
          icon: Icons.logout,
          title: 'Logout',
          message: 'Are you sure you want to Logout your account?',
          actionLabel: 'Logout',
          actionColor: AppColors.dangerDeep,
          onConfirm: () => context.read<ProfileEditCubit>().logout(),
        ),
      ),
    );
  }

  void _showDeleteSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (_) => BlocProvider<ProfileEditCubit>.value(
        value: context.read<ProfileEditCubit>(),
        child: ProfileConfirmActionSheet(
          icon: Icons.delete_outline,
          title: 'Delete Account',
          message: 'Are you sure you want to Delete your account?',
          actionLabel: 'Delete',
          actionColor: AppColors.dangerDeep,
          onConfirm: () => context.read<ProfileEditCubit>().deleteAccount(),
        ),
      ),
    );
  }
}
