import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goapp/core/service/sms_autofill_service.dart';
import 'package:goapp/core/storage/registration_progress_store.dart';
import 'package:goapp/core/storage/user_cache_model.dart';
import 'package:goapp/core/storage/user_cache_store.dart';
import 'package:goapp/features/home/presentation/cubit/driver_status_cubit.dart';
import 'package:goapp/features/home/presentation/pages/home_page.dart';
import 'package:goapp/core/di/injection.dart';
import '../../domain/entities/user.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../cubit/otp_cubit.dart';
import '../theme/auth_ui_tokens.dart';
import '../widgets/app_text_field.dart';
import '../widgets/auth_primary_button.dart';
import '../../../profile/presentation/pages/profile_setup_page.dart';
import 'package:goapp/core/widgets/keyboard_aware_bottom.dart';
import 'package:goapp/core/theme/app_colors.dart';

class OtpPage extends StatefulWidget {
  const OtpPage({
    super.key,
    required this.phoneNumber,
    required this.otpId,
    this.cubit,
  });

  final String phoneNumber;
  final String otpId;
  final OtpCubit? cubit;

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends SmsAutoFillState<OtpPage> {
  static const int _maxOtpLength = 4;

  bool _successHandled = false;
  late final OtpCubit _otpCubit;
  late final bool _ownsCubit;
  late final List<TextEditingController> _controllers = List.generate(
    OtpCubit.otpLength,
    (_) => TextEditingController(),
  );
  late final List<FocusNode> _focusNodes = List.generate(
    OtpCubit.otpLength,
    (_) => FocusNode(),
  );

  @override
  void initState() {
    super.initState();
    _ownsCubit = false;
    if (widget.cubit != null) {
      _otpCubit = widget.cubit!;
    } else {
      _otpCubit = context.read<OtpCubit>();
    }
    _otpCubit.updateCode('');
    _syncBoxesFromCode('');
    startSmsCodeListener();
  }

  @override
  void dispose() {
    stopSmsCodeListener();
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    if (_ownsCubit) {
      _otpCubit.close();
    }
    super.dispose();
  }

  Future<void> _handleSuccess({required bool syncSession, User? user}) async {
    if (_successHandled) return;
    _successHandled = true;
    final existing = await UserCacheStore.load();
    final resolvedPhone = (user?.phone ?? widget.phoneNumber).trim();
    await UserCacheStore.save(
      LocalUserCacheModel(
        id: user?.id ?? existing?.id ?? 'captain-001',
        fullName: existing?.fullName ?? '',
        gender: existing?.gender ?? '',
        referCode: existing?.referCode ?? '',
        emergencyContact: existing?.emergencyContact ?? '',
        email: existing?.email,
        phone: resolvedPhone.isEmpty ? existing?.phone : resolvedPhone,
        dob: existing?.dob,
        rating: existing?.rating ?? 0.0,
        totalTrips: existing?.totalTrips ?? 0,
        totalYears: existing?.totalYears ?? 0.0,
      ),
    );
    final hasCompletedProfile =
        (existing?.fullName.trim().isNotEmpty ?? false) &&
        (existing?.gender.trim().isNotEmpty ?? false);
    await RegistrationProgressStore.markOtpVerified();
    if (hasCompletedProfile) {
      await RegistrationProgressStore.setStep(RegistrationStep.home);
    } else {
      await RegistrationProgressStore.setStep(
        RegistrationStep.profileSetup,
        clearCity: true,
        clearVehicle: true,
        clearDocumentStep: true,
      );
    }
    if (!mounted) return;
    final navigator = Navigator.of(context, rootNavigator: true);
    navigator.pushReplacement(
      MaterialPageRoute(
        builder: (_) {
          if (hasCompletedProfile) {
            return BlocProvider<DriverCubit>(
              create: (_) => sl<DriverCubit>(),
              child: const HomeScreen(),
            );
          }
          return const ProfileSetupPage();
        },
      ),
    );
    _otpCubit.consumeActions();
  }

  @override
  void codeUpdated() {
    if (!mounted) return;
    final received = (code ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    final trimmed = received.length > _maxOtpLength
        ? received.substring(0, _maxOtpLength)
        : received;
    _otpCubit.updateCode(trimmed);
    _syncBoxesFromCode(trimmed);
    if (trimmed.length == _maxOtpLength) {
      FocusScope.of(context).unfocus();
    }
  }

  void _syncBoxesFromCode(String otp) {
    for (var i = 0; i < OtpCubit.otpLength; i++) {
      final next = i < otp.length ? otp[i] : '';
      if (_controllers[i].text != next) {
        _controllers[i].text = next;
      }
    }
  }

  void _onOtpChanged(int index, String value) {
    final digit = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digit != value) {
      _controllers[index].text = digit;
      _controllers[index].selection = TextSelection.collapsed(
        offset: digit.length,
      );
    }
    if (digit.isNotEmpty && index < OtpCubit.otpLength - 1) {
      _focusNodes[index + 1].requestFocus();
    } else if (digit.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    _otpCubit.updateCode(_controllers.map((c) => c.text).join());
    if (_otpCubit.state.code.length == _maxOtpLength) {
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    var hasAuthBloc = false;
    try {
      context.read<AuthBloc>();
      hasAuthBloc = true;
    } catch (_) {
      hasAuthBloc = false;
    }

    return BlocProvider<OtpCubit>.value(
      value: _otpCubit,
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: MultiBlocListener(
            listeners: [
              if (hasAuthBloc)
                BlocListener<AuthBloc, AuthState>(
                  listener: (context, state) async {
                    if (state is AuthSuccess) {
                      _otpCubit.handleAuthSuccess();
                      await _handleSuccess(syncSession: true, user: state.user);
                      return;
                    }
                    if (state is AuthFailure) {
                      _otpCubit.handleAuthFailure(state.message);
                    }
                  },
                ),
              BlocListener<OtpCubit, OtpState>(
                listenWhen: (previous, current) =>
                    previous.code != current.code ||
                    previous.submitRequested != current.submitRequested ||
                    previous.submitError != current.submitError ||
                    previous.resendMessage != current.resendMessage ||
                    previous.errorMessage != current.errorMessage ||
                    previous.isLoading != current.isLoading,
                listener: (context, state) async {
                  _syncBoxesFromCode(state.code);
                  if (state.submitRequested) {
                    try {
                      context.read<AuthBloc>().add(
                        LoginRequested(
                          phone: widget.phoneNumber,
                          otp: state.code,
                          otpId: widget.otpId,
                        ),
                      );
                      _otpCubit.consumeActions();
                      return;
                    } catch (_) {}
                    _otpCubit.handleAuthFailure('Wrong OTP');
                    return;
                  }
                },
              ),
            ],
            child: BlocBuilder<OtpCubit, OtpState>(
              builder: (context, otpState) {
                final timer =
                    '00:${otpState.secondsLeft.toString().padLeft(2, '0')}';
                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        const Text(
                          'Verification',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AuthUiColors.textDarkAlt,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Please enter the 4-digit code sent to',
                          style: TextStyle(
                            fontSize: 13.5,
                            color: AuthUiColors.textMuted,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.phoneNumber.isEmpty
                              ? '+1 (555) 012-3456'
                              : widget.phoneNumber,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: AuthUiColors.textDarkAlt,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: List.generate(
                            OtpCubit.otpLength,
                            (index) => _OtpBox(
                              fieldKey: index == 0
                                  ? const Key('otp_text_field')
                                  : null,
                              controller: _controllers[index],
                              focusNode: _focusNodes[index],
                              autoFocus: index == 0,
                              onChanged: (value) => _onOtpChanged(index, value),
                            ),
                          ),
                        ),
                        if (otpState.submitError != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            otpState.submitError!,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.red,
                            ),
                          ),
                        ],
                        if (otpState.errorMessage != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            otpState.errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.red,
                            ),
                          ),
                        ],
                        const SizedBox(height: 34),
                        const Text(
                          "Didn't receive the code?",
                          style: TextStyle(
                            fontSize: 12.5,
                            color: AuthUiColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            InkWell(
                              onTap: otpState.canResend && !otpState.isLoading
                                  ? () => _otpCubit.resend(widget.phoneNumber)
                                  : null,
                              child: Text(
                                'RESEND CODE',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: otpState.canResend
                                      ? AuthUiColors.danger
                                      : AuthUiColors.danger.withValues(
                                          alpha: 0.5,
                                        ),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            if (otpState.secondsLeft > 0) ...[
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.hexFFE4F4ED,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Text(
                                  timer,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AuthUiColors.brandGreen,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (otpState.resendMessage != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            otpState.resendMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AuthUiColors.brandGreen,
                            ),
                          ),
                        ],
                        const SizedBox(height: 36),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        bottomNavigationBar: BlocBuilder<OtpCubit, OtpState>(
          builder: (context, otpState) {
            return KeyboardAwareBottom(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
              child: SizedBox(
                width: double.infinity,
                height: 46,
                child: AuthPrimaryButton(
                  label: 'Verify Now',
                  loading: otpState.isLoading,
                  onPressed: otpState.isLoading
                      ? null
                      : () =>
                            _otpCubit.submit(widget.phoneNumber, widget.otpId),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _OtpBox extends StatelessWidget {
  const _OtpBox({
    this.fieldKey,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    this.autoFocus = false,
  });

  final Key? fieldKey;
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final bool autoFocus;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: AppColors.hex14000000,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: AppTextField(
        key: fieldKey,
        controller: controller,
        focusNode: focusNode,
        autofocus: autoFocus,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        textStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AuthUiColors.textDarkAlt,
        ),
        filled: false,
        borderless: true,
        onChanged: onChanged,
      ),
    );
  }
}
