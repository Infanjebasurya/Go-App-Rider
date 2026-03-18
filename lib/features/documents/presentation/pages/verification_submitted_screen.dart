import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:goapp/features/auth/presentation/theme/app_colors.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goapp/core/permissions/notification_permission_helper.dart';
import 'package:goapp/features/auth/presentation/widgets/appbar.dart';
import 'package:goapp/features/auth/presentation/widgets/snackbar_utils.dart';
import 'package:goapp/features/driver_activation/presentation/pages/new_driver_activation_screen.dart';
import 'package:goapp/features/home/presentation/cubit/driver_status_cubit.dart';
import 'package:goapp/features/home/presentation/pages/home_page.dart';
import 'package:goapp/core/storage/registration_progress_store.dart';
import 'package:goapp/core/widgets/shadow_button.dart';
import 'package:goapp/core/di/injection.dart';

class VerificationSubmittedScreen extends StatefulWidget {
  final VoidCallback? onGoHome;
  final String? snackbarMessage;

  const VerificationSubmittedScreen({
    super.key,
    this.onGoHome,
    this.snackbarMessage,
  });

  @override
  State<VerificationSubmittedScreen> createState() =>
      _VerificationSubmittedScreenState();
}

class _VerificationSubmittedScreenState
    extends State<VerificationSubmittedScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late AnimationController _scaleCtrl;
  late AnimationController _floatCtrl;
  late AnimationController _checkCtrl;

  late Animation<double> _fadeAnim;
  late Animation<double> _textFadeAnim;
  late Animation<Offset> _textSlideAnim;

  @override
  void initState() {
    super.initState();
    unawaited(
      RegistrationProgressStore.setStep(RegistrationStep.verificationSubmitted),
    );

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _checkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _textFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeCtrl,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );
    _textSlideAnim =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _fadeCtrl,
            curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic),
          ),
        );

    _scaleCtrl.forward();
    if (widget.snackbarMessage != null &&
        widget.snackbarMessage!.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        SnackBarUtils.show(context, widget.snackbarMessage!);
      });
    }
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _fadeCtrl.forward();
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _checkCtrl.forward();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(NotificationPermissionHelper.ensureRequestedOnce());
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _scaleCtrl.dispose();
    _floatCtrl.dispose();
    _checkCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    void goHome() {
      if (widget.onGoHome != null) {
        widget.onGoHome!();
      }
      unawaited(RegistrationProgressStore.setStep(RegistrationStep.home));
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const NewDriverActivationScreen()),
        (route) => false,
      );
    }

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: AppAppBar(
          title: 'GoApp',
          backEnabled: false,
          onBack: null,
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, color: AppColors.coolwhite),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      children: [
                        const SizedBox(height: 24),
                        Container(
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            color: AppColors.white,
                          ),
                          child: Center(
                            child: Image.asset(
                              'assets/image/register_success.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(height: 36),
                        FadeTransition(
                          opacity: _textFadeAnim,
                          child: SlideTransition(
                            position: _textSlideAnim,
                            child: Column(
                              children: [
                                const Text(
                                  'Verification Submitted',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.headingNavy,
                                    letterSpacing: -0.6,
                                    height: 1.15,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Center(
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 360,
                                    ),
                                    child: Text(
                                      'Your credentials are now under review by our\nelite concierge team. Expect a status update\nwithin 24-48 hours..',
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      softWrap: true,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                        color: AppColors.gray.shade500,
                                        height: 1.6,
                                        letterSpacing: 0.1,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 32),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
              FadeTransition(
                opacity: _fadeAnim,
                child: _GoHomeButton(onTap: goHome),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoHomeButton extends StatelessWidget {
  final VoidCallback? onTap;

  const _GoHomeButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        math.max(
              MediaQuery.viewInsetsOf(context).bottom,
              MediaQuery.of(context).padding.bottom,
            ) +
            20,
      ),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.coolwhite)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ShadowButton(
          key: const Key('go_home_button'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.emerald,
            foregroundColor: AppColors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
          onPressed:
              onTap ??
              () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) => BlocProvider<DriverCubit>(
                      create: (_) => sl<DriverCubit>(),
                      child: const HomeScreen(),
                    ),
                  ),
                  (route) => false,
                );
              },
          child: const Text(
            'Go to Home',
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.1,
            ),
          ),
        ),
      ),
    );
  }
}
