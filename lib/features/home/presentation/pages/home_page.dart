import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goapp/core/location/location_permission_guard.dart';
import 'package:goapp/core/storage/home_trip_resume_store.dart';
import 'package:goapp/core/storage/trip_session_store.dart';
import 'package:goapp/core/utils/env.dart';
import 'package:goapp/features/home/presentation/pages/available_orders_page.dart';
import 'package:goapp/features/home/presentation/widgets/home_no_device_back.dart';
import 'package:goapp/core/storage/registration_progress_store.dart';
import 'package:goapp/core/di/injection.dart';
import 'package:goapp/features/auth/presentation/widgets/snackbar_utils.dart';

import '../cubit/driver_status_cubit.dart';
import '../cubit/driver_status_state.dart';
import '../widgets/app_drawer.dart';
import '../widgets/offline_content.dart';
import '../widgets/online_content.dart';
import 'package:goapp/core/theme/app_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _lastNavigationToken = 0;
  int _lastShownBlockEventId = -1;
  int _lastShownSnackEventId = -1;
  int _permissionDeniedAttempts = 0;
  late final LocationPermissionGuard _locationGuard;
  Timer? _locationSyncTimer;
  bool _isLocationDialogVisible = false;

  @override
  void initState() {
    super.initState();
    _locationGuard = sl<LocationPermissionGuard>();
    WidgetsBinding.instance.addObserver(this);
    unawaited(context.read<DriverCubit>().refreshDashboardMetrics());
    // B-13 FIX: Only clear the trip store when no trip is active.
    // Calling clear() unconditionally wiped the persisted stage on every
    // home-screen mount, breaking crash-recovery if the home screen was
    // pushed while a trip was in progress.
    _clearTripStoreIfSafe();
    if (Env.mockApi) {
      unawaited(HomeTripResumeStore.markForceHomeOnNextLaunch());
    }
    unawaited(RegistrationProgressStore.setStep(RegistrationStep.home));
    _locationSyncTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      unawaited(context.read<DriverCubit>().syncWalletBalance());
      unawaited(_syncLocationUiState());
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(context.read<DriverCubit>().refreshDashboardMetrics());
    }
  }

  /// B-13 FIX: Only wipes the trip resume store when no active trip exists.
  void _clearTripStoreIfSafe() {
    unawaited(
      HomeTripResumeStore.loadStage().then((stage) {
        if (stage == HomeTripResumeStage.none) {
          unawaited(HomeTripResumeStore.clear());
          // TripSessionStore: remove active session only when back at home
          // with no trip in progress.
          unawaited(TripSessionStore.endSession());
        }
      }),
    );
  }

  @override
  void dispose() {
    _locationSyncTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DriverCubit, DriverState>(
      listener: (context, state) {
        if (state.navigateToOrdersToken > _lastNavigationToken) {
          _lastNavigationToken = state.navigateToOrdersToken;
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => AvailableOrdersPage()),
          );
        }

        if (state.snackbarMessageEventId != _lastShownSnackEventId) {
          _lastShownSnackEventId = state.snackbarMessageEventId;
          final String? message = state.snackbarMessage;
          if (message != null && message.trim().isNotEmpty) {
            SnackBarUtils.show(context, message.trim());
          }
        }

        if (state.offlineBlockIssue != null &&
            state.offlineBlockEventId != _lastShownBlockEventId) {
          _lastShownBlockEventId = state.offlineBlockEventId;
          if (state.offlineBlockIssue == LocationIssue.permissionDenied) {
            _permissionDeniedAttempts += 1;
            if (_permissionDeniedAttempts <= 2) {
              return;
            }
          } else {
            _permissionDeniedAttempts = 0;
          }
          if (_isHomeRouteActive()) {
            unawaited(_showLocationBlockedDialog(state.offlineBlockIssue!));
          }
        }
      },
      builder: (context, state) {
        return HomeNoDeviceBack(
          child: Scaffold(
            key: _scaffoldKey,
            backgroundColor: AppColors.white,
            drawer: AppDrawer(
              onReopenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            body: state.isOnline
                ? const OnlineContent()
                : const OfflineContent(),
          ),
        );
      },
    );
  }

  Future<void> _syncLocationUiState() async {
    if (!mounted) return;
    if (!_isHomeRouteActive()) return;
    if (context.read<DriverCubit>().state.isOnline) return;

    final result = await _locationGuard.ensureReady(requestPermission: false);
    if (!mounted || !result.isReady) return;

    _permissionDeniedAttempts = 0;
    context.read<DriverCubit>().clearOfflineLocationBlock();
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
  }

  bool _isHomeRouteActive() {
    final route = ModalRoute.of(context);
    return route?.isCurrent ?? false;
  }

  Future<void> _showLocationBlockedDialog(LocationIssue issue) async {
    if (!mounted || _isLocationDialogVisible) return;
    _isLocationDialogVisible = true;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Location Required'),
          content: Text(_locationBlockedMessage(issue)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Not now'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                if (issue == LocationIssue.serviceDisabled) {
                  await _locationGuard.openLocationSettings();
                } else {
                  await _locationGuard.openAppSettings();
                }
              },
              child: Text(
                issue == LocationIssue.serviceDisabled
                    ? 'Enable GPS'
                    : 'Open Settings',
              ),
            ),
          ],
        );
      },
    );
    _isLocationDialogVisible = false;
  }

  String _locationBlockedMessage(LocationIssue issue) {
    switch (issue) {
      case LocationIssue.serviceDisabled:
        return 'Location is off. Open app settings and verify location permission.';
      case LocationIssue.permissionDenied:
        return 'Allow Location permission to go online and receive ride requests.';
      case LocationIssue.permissionDeniedForever:
        return 'Location permission is permanently denied. Enable it from app settings.';
    }
  }
}
