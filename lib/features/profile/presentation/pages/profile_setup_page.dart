import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goapp/core/theme/app_colors.dart';
import 'package:goapp/core/storage/text_field_store.dart';
import 'package:goapp/core/storage/user_cache_model.dart';
import 'package:goapp/core/storage/user_cache_store.dart';
import 'package:goapp/features/auth/presentation/widgets/appbar.dart';
import 'package:goapp/features/auth/presentation/widgets/snackbar_utils.dart';
import 'package:goapp/features/city_vehicle/city_selection/presentation/pages/city_selection_screen.dart';
import 'package:goapp/features/profile/domain/entities/profile.dart';
import 'package:goapp/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:goapp/features/profile/presentation/bloc/profile_event.dart';
import 'package:goapp/features/profile/presentation/bloc/profile_state.dart';
import 'package:goapp/features/profile/presentation/cubit/profile_setup_cubit.dart';
import 'package:goapp/features/profile/presentation/cubit/profile_setup_state.dart';
import 'package:goapp/features/profile/presentation/pages/profile_setup/widgets/profile_address_section.dart';
import 'package:goapp/features/profile/presentation/pages/profile_setup/widgets/profile_form_section.dart';
import 'package:goapp/features/profile/presentation/pages/profile_setup/widgets/profile_photo_section.dart';
import 'package:goapp/features/profile/presentation/pages/profile_setup/widgets/profile_setup_header.dart';
import 'package:goapp/features/profile/presentation/pages/profile_setup/widgets/profile_setup_submit_button.dart';
import 'package:goapp/features/profile/presentation/pages/profile_setup/widgets/profile_vehicle_section.dart';
import 'package:goapp/core/di/injection.dart';
import 'package:goapp/core/service/url_launcher_service.dart';

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key, this.allowBack = false});

  final bool allowBack;

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  static final Uri _termsUri = Uri.parse('https://sybrox.com/about');
  static const List<String> _genders = [
    'Male',
    'Female',
    'Others',
    'Prefer not to say',
  ];
  static const List<String> _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _referController = TextEditingController();
  final _emergencyController = TextEditingController();
  late final TapGestureRecognizer _termsTap;

  bool _prefilled = false;
  bool _didNavigate = false;
  late final ProfileSetupCubit _cubit;
  late final ProfileBloc _profileBloc;
  late final bool _ownsProfileBloc;

  @override
  void initState() {
    super.initState();
    _termsTap = TapGestureRecognizer()..onTap = _openTermsOfService;
    _cubit = sl<ProfileSetupCubit>();
    _profileBloc = sl<ProfileBloc>();
    _ownsProfileBloc = true;
    _cubit.setInitial(
      name: '',
      email: '',
      gender: '',
      dob: '',
      refer: '',
      emergencyContact: '',
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = _profileBloc.state;
      if (state is ProfileSuccess) {
        _prefillFromProfile(state.profile);
      } else {
        _profileBloc.add(const ProfileRequested());
      }
    });
  }

  @override
  void dispose() {
    _termsTap.dispose();
    _cubit.close();
    if (_ownsProfileBloc) {
      _profileBloc.close();
    }
    _nameController.dispose();
    _emailController.dispose();
    _referController.dispose();
    _emergencyController.dispose();
    super.dispose();
  }

  Future<void> _openTermsOfService() async {
    final launched = await sl<UrlLauncherService>().launch(
      _termsUri.toString(),
    );
    if (!mounted || launched) return;
    SnackBarUtils.showError(context, 'Unable to open link');
  }

  String _formatDob(DateTime date) {
    return '${date.day} ${_months[date.month - 1]} ${date.year}';
  }

  String _normalizeDobForUi(String value) {
    final raw = value.trim();
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(raw);
    if (match == null) return raw;
    final year = int.tryParse(match.group(1)!);
    final month = int.tryParse(match.group(2)!);
    final day = int.tryParse(match.group(3)!);
    if (year == null || month == null || day == null) return raw;
    if (month < 1 || month > 12) return raw;
    final parsed = DateTime(year, month, day);
    if (parsed.year != year || parsed.month != month || parsed.day != day) {
      return raw;
    }
    return '${parsed.day} ${_months[parsed.month - 1]} ${parsed.year}';
  }

  void _prefillFromProfile(Profile profile) {
    if (_prefilled) return;
    _prefilled = true;
    final name = _nameController.text.isNotEmpty
        ? _nameController.text
        : profile.name;
    final email = _emailController.text.isNotEmpty
        ? _emailController.text
        : (profile.email ?? '');
    final refer = _referController.text.isNotEmpty
        ? _referController.text
        : profile.refer;
    final emergency = _emergencyController.text.isNotEmpty
        ? _emergencyController.text
        : profile.emergencyContact;
    _nameController.text = name;
    _emailController.text = email;
    _referController.text = refer;
    _emergencyController.text = emergency;
    _cubit.setInitial(
      name: name,
      email: email,
      gender: profile.gender,
      dob: _normalizeDobForUi(profile.dob ?? ''),
      refer: refer,
      emergencyContact: emergency,
    );
  }

  void _clearForm() {
    _nameController.clear();
    _emailController.clear();
    _referController.clear();
    _emergencyController.clear();
    _prefilled = false;
    _cubit.setInitial(
      name: '',
      email: '',
      gender: '',
      dob: '',
      refer: '',
      emergencyContact: '',
    );
    unawaited(TextFieldStore.remove('profile_setup.name'));
    unawaited(TextFieldStore.remove('profile_setup.email'));
    unawaited(TextFieldStore.remove('profile_setup.gender'));
    unawaited(TextFieldStore.remove('profile_setup.dob'));
    unawaited(TextFieldStore.remove('profile_setup.refer'));
    unawaited(TextFieldStore.remove('profile_setup.emergency'));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProfileBloc>.value(
      value: _profileBloc,
      child: BlocProvider<ProfileSetupCubit>.value(
        value: _cubit,
        child: PopScope(
          canPop: widget.allowBack,
          child: Scaffold(
            backgroundColor: AppColors.white,
            appBar: AppAppBar(title: 'GoApp', backEnabled: false, onBack: null),
            body: MultiBlocListener(
              listeners: [
                BlocListener<ProfileBloc, ProfileState>(
                  listener: (context, state) async {
                    if (state is! ProfileSuccess) return;
                    if (_didNavigate) return;
                    final formState = context.read<ProfileSetupCubit>().state;
                    final hasSubmission = formState.submission != null;
                    if (!hasSubmission) {
                      _prefillFromProfile(state.profile);
                      return;
                    }
                    if (widget.allowBack) {
                      Navigator.of(context).pop();
                      return;
                    }
                    await UserCacheStore.save(
                      LocalUserCacheModel(
                        id: state.profile.id,
                        fullName: formState.name.trim(),
                        gender: formState.gender.trim(),
                        referCode: formState.refer.trim(),
                        emergencyContact: formState.emergencyContact.trim(),
                        email: formState.email.trim().isEmpty
                            ? null
                            : formState.email.trim(),
                        phone: state.profile.phone,
                        dob: formState.dob.trim().isEmpty
                            ? null
                            : formState.dob.trim(),
                        rating: state.profile.rating,
                        totalTrips: state.profile.totalTrips,
                        totalYears: state.profile.totalYears,
                      ),
                    );
                    if (!context.mounted) return;
                    SnackBarUtils.show(context, 'Profile saved successfully');
                    _didNavigate = true;
                    _clearForm();
                    Navigator.of(context)
                        .pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => const CitySelectionScreen(),
                          ),
                        )
                        .then((_) {
                          if (!mounted) return;
                          _didNavigate = false;
                        });
                  },
                ),
                BlocListener<ProfileSetupCubit, ProfileSetupState>(
                  listenWhen: (previous, current) =>
                      previous.submitRequested != current.submitRequested,
                  listener: (context, state) {
                    if (!state.submitRequested || state.submission == null) {
                      return;
                    }
                    _profileBloc.add(
                      ProfileSubmitted(
                        name: state.submission!.name,
                        email: state.submission!.email,
                        gender: state.submission!.gender,
                        dob: state.submission!.dob,
                        refer: state.submission!.refer,
                        emergencyContact: state.submission!.emergencyContact,
                      ),
                    );
                    context.read<ProfileSetupCubit>().consumeSubmit();
                  },
                ),
              ],
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: BlocBuilder<ProfileSetupCubit, ProfileSetupState>(
                  builder: (context, formState) {
                    return SafeArea(
                      child: ListView(
                        padding: const EdgeInsets.only(bottom: 16),
                        children: [
                          const ProfileSetupHeader(),
                          const ProfilePhotoSection(),
                          const SizedBox(height: 24),
                          ProfileFormSection(
                            formState: formState,
                            nameController: _nameController,
                            emailController: _emailController,
                            onNameChanged: context
                                .read<ProfileSetupCubit>()
                                .updateName,
                            onEmailChanged: context
                                .read<ProfileSetupCubit>()
                                .updateEmail,
                          ),
                          const SizedBox(height: 20),
                          ProfileAddressSection(
                            formState: formState,
                            onOpenGender: () => showGenderSheet(
                              context,
                              cubit: _cubit,
                              genders: _genders,
                            ),
                            onOpenDob: () => showDobSheet(
                              context,
                              cubit: _cubit,
                              months: _months,
                              formatDob: _formatDob,
                            ),
                          ),
                          const SizedBox(height: 20),
                          ProfileVehicleSection(
                            referController: _referController,
                            onReferChanged: context
                                .read<ProfileSetupCubit>()
                                .updateRefer,
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            bottomNavigationBar:
                BlocBuilder<ProfileSetupCubit, ProfileSetupState>(
                  builder: (context, formState) {
                    final isFormValid = context
                        .read<ProfileSetupCubit>()
                        .isFormValid;
                    return BlocBuilder<ProfileBloc, ProfileState>(
                      builder: (context, profileState) {
                        final effectiveProfileState =
                            profileState is ProfileFailure &&
                                formState.submission == null
                            ? const ProfileInitial()
                            : profileState;
                        return ProfileSetupSubmitButton(
                          profileState: effectiveProfileState,
                          isFormValid: isFormValid,
                          onSubmit: () =>
                              context.read<ProfileSetupCubit>().submit(),
                          termsTap: _termsTap,
                        );
                      },
                    );
                  },
                ),
          ),
        ),
      ),
    );
  }
}
