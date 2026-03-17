import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goapp/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:goapp/features/auth/presentation/bloc/auth_event.dart';
import 'package:goapp/features/auth/presentation/bloc/auth_state.dart';
import 'package:goapp/features/auth/presentation/cubit/login_form_cubit.dart';
import 'package:goapp/features/auth/presentation/cubit/login_form_state.dart';
import 'package:goapp/features/auth/presentation/cubit/otp_cubit.dart';
import 'package:goapp/features/auth/presentation/pages/otp_page.dart';
import 'package:goapp/features/auth/presentation/theme/app_colors.dart';
import 'package:goapp/features/auth/presentation/theme/auth_ui_tokens.dart';
import 'package:goapp/features/auth/presentation/widgets/app_text_field.dart';
import 'package:goapp/features/auth/presentation/widgets/auth_primary_button.dart';
import 'package:goapp/features/auth/presentation/widgets/snackbar_utils.dart';
import 'package:goapp/core/widgets/keyboard_aware_bottom.dart';
import 'package:goapp/core/di/injection.dart';
import 'package:goapp/core/service/url_launcher_service.dart';
import 'package:goapp/core/utils/env.dart';

class RLoginPage extends StatefulWidget {
  const RLoginPage({super.key});

  @override
  State<RLoginPage> createState() => _RLoginPageState();
}

class _RLoginPageState extends State<RLoginPage> {
  static final Uri _policyUri = Uri.parse('https://sybrox.com/about');
  final TextEditingController _controller = TextEditingController();
  late final TapGestureRecognizer _privacyTap;
  bool _didForceClear = false;

  @override
  void initState() {
    super.initState();
    _privacyTap = TapGestureRecognizer()..onTap = _openPolicyLink;
  }

  @override
  void dispose() {
    _privacyTap.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<LoginFormCubit>(),
      child: MultiBlocListener(
        listeners: [
          BlocListener<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is OtpRequestSuccess) {
                final phone = context.read<LoginFormCubit>().state.phoneE164;
                if (phone == null) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MultiBlocProvider(
                      providers: [
                        BlocProvider<AuthBloc>.value(
                          value: context.read<AuthBloc>(),
                        ),
                        BlocProvider<OtpCubit>(create: (_) => sl<OtpCubit>()),
                      ],
                      child: OtpPage(phoneNumber: phone, otpId: state.otpId),
                    ),
                  ),
                );
                SnackBarUtils.show(
                  context,
                  Env.mockApi
                      ? 'OTP sent (Mock). Use OTP: 5656'
                      : 'OTP sent successfully. Please check your SMS.',
                );
              }
              if (state is AuthFailure) {
                final route = ModalRoute.of(context);
                if (route?.isCurrent != true) return;
                SnackBarUtils.show(context, state.message);
              }
            },
          ),
          BlocListener<LoginFormCubit, LoginFormState>(
            listenWhen: (previous, current) =>
                previous.submitRequested != current.submitRequested ||
                previous.submitError != current.submitError,
            listener: (context, state) {
              if (state.submitError != null) {
                return;
              }
              if (state.submitRequested &&
                  state.phoneE164 != null &&
                  state.digits.length == 10 &&
                  state.error == null) {
                context.read<AuthBloc>().add(
                  RequestOtpRequested(phone: state.phoneE164!),
                );
                context.read<LoginFormCubit>().consumeSubmit();
              }
            },
          ),
        ],
        child: BlocBuilder<LoginFormCubit, LoginFormState>(
          builder: (context, formState) {
            _ensureEmptyOnFirstBuild(context);
            if (_controller.text != formState.digits) {
              _controller.value = TextEditingValue(
                text: formState.digits,
                selection: TextSelection.collapsed(
                  offset: formState.digits.length,
                ),
              );
            }
            return Scaffold(
              backgroundColor: AppColors.white,
              body: SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: IntrinsicHeight(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 24),
                                const Text(
                                  'Welcome to Goapp',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.hexFF111111,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'Enter your mobile number to begin your\njourney.',
                                  style: TextStyle(
                                    fontSize: 27 / 2,
                                    height: 1.45,
                                    color: AuthUiColors.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 30),
                                const Text(
                                  'Mobile Number',
                                  style: TextStyle(
                                    fontSize: 25 / 2,
                                    fontWeight: FontWeight.w600,
                                    color: AuthUiColors.textDark,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    const SizedBox(width: 14),
                                    const Text(
                                      '+91',
                                      style: TextStyle(
                                        fontSize: 30 / 2,
                                        fontWeight: FontWeight.w600,
                                        color: AuthUiColors.textDarkAlt,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Container(
                                      width: 1,
                                      height: 38 / 2,
                                      color: AuthUiColors.textMuted.withValues(
                                        alpha: 0.45,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: AppTextField(
                                        controller: _controller,
                                        keyboardType: TextInputType.phone,
                                        inputFormatters: [
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                          LengthLimitingTextInputFormatter(10),
                                        ],
                                        autofillHints: const <String>[],
                                        autocorrect: false,
                                        enableSuggestions: false,
                                        enableIMEPersonalizedLearning: false,
                                        isCollapsed: true,
                                        filled: false,
                                        hint: '0000000000',
                                        hintStyle: const TextStyle(
                                          color: AuthUiColors.textMuted,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 1.1,
                                        ),
                                        borderless: true,
                                        textStyle: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: AuthUiColors.textDarkAlt,
                                          letterSpacing: 1.1,
                                        ),
                                        onChanged: context
                                            .read<LoginFormCubit>()
                                            .onInputChanged,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  height: 1,
                                  color: AuthUiColors.textMuted.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                                if (formState.error != null &&
                                    formState.digits.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 14),
                                    child: Text(
                                      formState.error!,
                                      style: const TextStyle(
                                        color: AppColors.red,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 18),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 12),
                                  child: Text.rich(
                                    TextSpan(
                                      style: TextStyle(
                                        fontSize: 23 / 2,
                                        height: 1.45,
                                        color: AuthUiColors.textMuted,
                                      ),
                                      children: [
                                        TextSpan(
                                          text:
                                              'By continuing, you agree to receive SMS for verification. ',
                                        ),
                                        TextSpan(
                                          text:
                                              'Message and data rates may apply. View our ',
                                        ),
                                        TextSpan(
                                          text: 'Privacy Policy',
                                          style: TextStyle(
                                            color: AppColors.black,
                                            fontSize: 14,
                                            decoration:
                                                TextDecoration.underline,
                                          ),
                                          recognizer: _privacyTap,
                                        ),
                                        TextSpan(text: '.'),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 34),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              bottomNavigationBar: KeyboardAwareBottom(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      final bool loading = state is AuthLoading;
                      final isValid =
                          formState.digits.length == 10 &&
                          formState.error == null;
                      return AuthPrimaryButton(
                        label: 'Get Verification Code',
                        loading: loading,
                        onPressed: isValid && !loading
                            ? context.read<LoginFormCubit>().submit
                            : null,
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _ensureEmptyOnFirstBuild(BuildContext context) {
    if (_didForceClear) return;
    _didForceClear = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _controller.clear();
      context.read<LoginFormCubit>().reset();
    });
  }

  Future<void> _openPolicyLink() async {
    final launched = await sl<UrlLauncherService>().launch(
      _policyUri.toString(),
    );
    if (!mounted || launched) return;
    SnackBarUtils.show(context, 'Unable to open link');
  }
}
