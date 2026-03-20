import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goapp/core/storage/driver_id_store.dart';
import 'package:goapp/core/storage/driver_wallet_store.dart';
import 'package:goapp/core/location/location_permission_guard.dart';
import 'package:goapp/core/storage/online_hours_store.dart';
import 'package:goapp/core/storage/ride_history_store.dart';
import 'package:goapp/core/utils/earnings_calculator.dart';
import 'package:goapp/features/home/data/datasources/driver_status_remote_data_source.dart';
import 'package:goapp/features/home/data/datasources/online_hours_mock_api.dart';

import 'driver_status_state.dart';

class DriverCubit extends Cubit<DriverState> {
  DriverCubit({
    LocationPermissionGuard? locationGuard,
    DriverStatusRemoteDataSource? driverStatusApi,
    OnlineHoursMockApi? onlineHoursApi,
    double minimumDutyWalletBalance = kMinimumDutyWalletBalance,
  }) : _locationGuard = locationGuard ?? const LocationPermissionGuard(),
       _driverStatusApi = driverStatusApi ?? DriverStatusRemoteDataSourceImpl(),
       _onlineHoursApi = onlineHoursApi ?? const OnlineHoursMockApi(),
       _minimumDutyWalletBalance = minimumDutyWalletBalance,
       super(const DriverState());

  final LocationPermissionGuard _locationGuard;
  final DriverStatusRemoteDataSource _driverStatusApi;
  final OnlineHoursMockApi _onlineHoursApi;
  final double _minimumDutyWalletBalance;
  Timer? _onlineTimer;
  Timer? _ordersNavigationTimer;
  Timer? _locationWatchTimer;
  Timer? _lowWalletWarningTimer;
  int _onlineMinutesToday = 0;
  int? _onlineSessionStartEpochMs;
  String _onlineMinutesDateKey = '';
  bool _isCheckingLocation = false;
  bool _didBootstrapOnlineHours = false;

  Future<void> refreshDashboardMetrics() async {
    await _bootstrapOnlineHoursIfNeeded();
    final List<RideHistoryTrip> history = await RideHistoryStore.loadTrips();
    final Iterable<RideHistoryTrip> settled = history.where(
      EarningsCalculator.isSettledTrip,
    );

    final DateTime now = DateTime.now();
    final DateTime startOfDay = DateTime(now.year, now.month, now.day);
    final DateTime endOfDay = startOfDay.add(const Duration(days: 1));
    final int dayStartMs = startOfDay.millisecondsSinceEpoch;
    final int dayEndMs = endOfDay.millisecondsSinceEpoch;

    final List<RideHistoryTrip> settledToday = settled
        .where((trip) {
          final int eventEpoch =
              trip.completedAtEpochMs ??
              trip.canceledAtEpochMs ??
              trip.acceptedAtEpochMs;
          return eventEpoch >= dayStartMs && eventEpoch < dayEndMs;
        })
        .toList(growable: false);

    double totalFare = 0;
    for (final RideHistoryTrip trip in settledToday) {
      totalFare += EarningsCalculator.totalEarning(trip);
    }
    totalFare = _round2(totalFare);

    final double walletBalance = _round2(await DriverWalletStore.loadBalance());
    final int ridesToday = settledToday
        .where(EarningsCalculator.isCompletedTrip)
        .length;
    final int rewardProgress = ridesToday > state.targetRides
        ? state.targetRides
        : ridesToday;

    if (isClosed) return;
    final DriverState nextState = state.copyWith(
      tripsCompleted: ridesToday,
      totalEarnings: totalFare,
      walletBalance: walletBalance,
      completedRides: rewardProgress,
    );
    emit(nextState);
    _updateLowWalletWarning(walletBalance);

    if (nextState.isOnline && walletBalance <= _minimumDutyWalletBalance) {
      goOffline();
      if (!isClosed) {
        emit(
          state.copyWith(
            lowWalletBlockEventId: state.lowWalletBlockEventId + 1,
          ),
        );
      }
    }
  }

  Future<void> syncWalletBalance() async {
    final double walletBalance = _round2(await DriverWalletStore.loadBalance());
    if (isClosed) return;
    if ((walletBalance - state.walletBalance).abs() <= 0.0001) return;

    final DriverState nextState = state.copyWith(walletBalance: walletBalance);
    emit(nextState);
    _updateLowWalletWarning(walletBalance);

    if (nextState.isOnline && walletBalance <= _minimumDutyWalletBalance) {
      goOffline();
      if (!isClosed) {
        emit(
          state.copyWith(
            lowWalletBlockEventId: state.lowWalletBlockEventId + 1,
          ),
        );
      }
    }
  }

  Future<void> toggleStatus() async {
    if (state.isStatusUpdating) return;

    final String driverId = (DriverIdStore.driverId() ?? '').trim();
    if (driverId.isEmpty) {
      _emitSnack('Driver ID missing. Please complete profile setup.');
      return;
    }

    if (state.isOnline) {
      emit(state.copyWith(isStatusUpdating: true));
      try {
        final response = await _driverStatusApi.updateStatus(
          driverId: driverId,
          status: 'offline',
        );
        goOffline();
        _emitSnack(
          (response.message ?? '').trim().isNotEmpty
              ? response.message!.trim()
              : 'Driver is now offline',
        );
      } catch (error) {
        if (isClosed) return;
        emit(state.copyWith(isStatusUpdating: false));
        _emitSnack(_errorMessage(error));
      }
      return;
    }

    await goOnline(notifyServer: true);
  }

  Future<void> goOnline({bool notifyServer = false}) async {
    if (state.isOnline) return;
    await _bootstrapOnlineHoursIfNeeded();

    final double walletBalance = await DriverWalletStore.loadBalance();
    if (walletBalance <= _minimumDutyWalletBalance) {
      emit(
        state.copyWith(
          status: DriverStatus.offline,
          walletBalance: walletBalance,
          lowWalletBlockEventId: state.lowWalletBlockEventId + 1,
        ),
      );
      _updateLowWalletWarning(walletBalance);
      return;
    }

    final access = await _locationGuard.ensureReady(requestPermission: true);
    if (!access.isReady) {
      emit(
        state.copyWith(
          status: DriverStatus.offline,
          offlineBlockIssue: access.issue,
          offlineBlockEventId: state.offlineBlockEventId + 1,
        ),
      );
      return;
    }

    if (notifyServer) {
      final String driverId = (DriverIdStore.driverId() ?? '').trim();
      if (driverId.isEmpty) {
        _emitSnack('Driver ID missing. Please complete profile setup.');
        return;
      }

      emit(state.copyWith(isStatusUpdating: true));
      try {
        final response = await _driverStatusApi.updateStatus(
          driverId: driverId,
          status: 'online',
        );
        final String message = (response.message ?? '').trim().isNotEmpty
            ? response.message!.trim()
            : 'Driver is now online';
        _emitSnack(message);
      } catch (error) {
        if (isClosed) return;
        emit(state.copyWith(isStatusUpdating: false));
        _emitSnack(_errorMessage(error));
        return;
      }
    }

    final int nowMs = DateTime.now().millisecondsSinceEpoch;
    _onlineSessionStartEpochMs = nowMs;
    await OnlineHoursStore.saveActiveSessionStartEpochMs(nowMs);
    _startTimer();
    _startOrdersNavigationDelay();
    emit(
      state.copyWith(
        status: DriverStatus.online,
        isStatusUpdating: false,
        onlineHours: _formatMinutes(_effectiveOnlineMinutesNow()),
        clearOfflineBlockIssue: true,
      ),
    );
    await refreshDashboardMetrics();
    _startLocationWatch();
  }

  void goOffline({LocationIssue? reason}) {
    if (state.isOffline && reason == null && state.offlineBlockIssue == null) {
      return;
    }
    _stopTimer();
    _stopOrdersNavigationDelay();
    _stopLocationWatch();
    unawaited(_flushOnlineMinutesAndEndSession());
    emit(
      state.copyWith(
        status: DriverStatus.offline,
        isStatusUpdating: false,
        onlineHours: _formatMinutes(_effectiveOnlineMinutesNow()),
        offlineBlockIssue: reason,
        offlineBlockEventId: reason == null
            ? state.offlineBlockEventId
            : state.offlineBlockEventId + 1,
      ),
    );
  }

  void _emitSnack(String message) {
    final String trimmed = message.trim();
    if (trimmed.isEmpty || isClosed) return;
    emit(
      state.copyWith(
        snackbarMessage: trimmed,
        snackbarMessageEventId: state.snackbarMessageEventId + 1,
      ),
    );
  }

  String _errorMessage(Object error) {
    final String raw = error.toString();
    const String prefix = 'Exception: ';
    return raw.startsWith(prefix) ? raw.substring(prefix.length) : raw;
  }

  void _startTimer() {
    _emitOnlineHoursIfChanged();
    _onlineTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _emitOnlineHoursIfChanged();
      unawaited(_syncOnlineMinutes());
    });
  }

  void _stopTimer() {
    _onlineTimer?.cancel();
    _onlineTimer = null;
  }

  void _startOrdersNavigationDelay() {
    _ordersNavigationTimer?.cancel();
    _ordersNavigationTimer = Timer(const Duration(seconds: 10), () {
      if (!state.isOnline) return;
      if (state.walletBalance <= _minimumDutyWalletBalance) {
        goOffline();
        if (!isClosed) {
          emit(
            state.copyWith(
              lowWalletBlockEventId: state.lowWalletBlockEventId + 1,
            ),
          );
        }
        return;
      }
      emit(
        state.copyWith(navigateToOrdersToken: state.navigateToOrdersToken + 1),
      );
    });
  }

  void _stopOrdersNavigationDelay() {
    _ordersNavigationTimer?.cancel();
    _ordersNavigationTimer = null;
  }

  void _startLocationWatch() {
    _locationWatchTimer?.cancel();
    _locationWatchTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      unawaited(_validateLocationAvailability());
    });
    unawaited(_validateLocationAvailability());
  }

  void _stopLocationWatch() {
    _locationWatchTimer?.cancel();
    _locationWatchTimer = null;
  }

  Future<void> _validateLocationAvailability() async {
    if (_isCheckingLocation || state.isOffline) return;
    _isCheckingLocation = true;
    try {
      final result = await _locationGuard.ensureReady(requestPermission: false);
      if (!result.isReady && state.isOnline) {
        goOffline(reason: result.issue);
      }
    } finally {
      _isCheckingLocation = false;
    }
  }

  Future<void> addMoney(double amount) async {
    final double next = _round2(await DriverWalletStore.addAmount(amount));
    if (isClosed) return;
    emit(state.copyWith(walletBalance: next));
    _updateLowWalletWarning(next);
  }

  bool addMoneyFromInput(String input) {
    final String normalized = input.replaceAll(RegExp(r'[^0-9.]'), '').trim();
    final double? amount = double.tryParse(normalized);
    if (amount == null || amount <= 0) return false;
    final double next = _round2(state.walletBalance + amount);
    emit(state.copyWith(walletBalance: next));
    _updateLowWalletWarning(next);
    unawaited(DriverWalletStore.saveBalance(next));
    return true;
  }

  void _updateLowWalletWarning(double walletBalance) {
    if (walletBalance > _minimumDutyWalletBalance) {
      _lowWalletWarningTimer?.cancel();
      _lowWalletWarningTimer = null;
      if (state.showLowWalletWarning) {
        emit(state.copyWith(showLowWalletWarning: false));
      }
      return;
    }

    if (!state.showLowWalletWarning) {
      emit(state.copyWith(showLowWalletWarning: true));
    }

    _lowWalletWarningTimer?.cancel();
    _lowWalletWarningTimer = Timer(const Duration(seconds: 10), () {
      if (isClosed) return;
      if (state.walletBalance <= _minimumDutyWalletBalance &&
          state.showLowWalletWarning) {
        emit(state.copyWith(showLowWalletWarning: false));
      }
    });
  }

  Future<void> _bootstrapOnlineHoursIfNeeded() async {
    if (_didBootstrapOnlineHours) return;
    _didBootstrapOnlineHours = true;

    final int cachedMinutes = await OnlineHoursStore.loadTodayMinutes();
    final int mockedMinutes = await _onlineHoursApi.fetchTodayOnlineMinutes();
    _onlineMinutesToday = mockedMinutes >= cachedMinutes
        ? mockedMinutes
        : cachedMinutes;
    _onlineSessionStartEpochMs =
        await OnlineHoursStore.loadActiveSessionStartEpochMs();
    _onlineMinutesDateKey = _todayKey();
    _ensureTodayWindow();

    if (!isClosed) {
      final String onlineHoursLabel = _formatMinutes(
        _effectiveOnlineMinutesNow(countRunningSession: state.isOnline),
      );
      if (onlineHoursLabel != state.onlineHours) {
        emit(state.copyWith(onlineHours: onlineHoursLabel));
      }
    }
  }

  int _effectiveOnlineMinutesNow({bool countRunningSession = true}) {
    _ensureTodayWindow();
    if (!countRunningSession) return _onlineMinutesToday;
    final int? startMs = _onlineSessionStartEpochMs;
    if (startMs == null) return _onlineMinutesToday;
    final DateTime now = DateTime.now();
    final int dayStartMs = DateTime(
      now.year,
      now.month,
      now.day,
    ).millisecondsSinceEpoch;
    final int effectiveStartMs = startMs < dayStartMs ? dayStartMs : startMs;
    final int elapsedMs = now.millisecondsSinceEpoch - effectiveStartMs;
    final int elapsedMinutes = elapsedMs <= 0 ? 0 : elapsedMs ~/ 60000;
    return _onlineMinutesToday + elapsedMinutes;
  }

  void _emitOnlineHoursIfChanged() {
    final String label = _formatMinutes(
      _effectiveOnlineMinutesNow(countRunningSession: state.isOnline),
    );
    if (label == state.onlineHours) return;
    emit(state.copyWith(onlineHours: label));
  }

  String _formatMinutes(int totalMinutes) {
    final int normalized = totalMinutes < 0 ? 0 : totalMinutes;
    final int hours = normalized ~/ 60;
    final int minutes = normalized % 60;
    return '${hours}h ${minutes}m';
  }

  double _round2(double value) {
    return double.parse(value.toStringAsFixed(2));
  }

  Future<void> _syncOnlineMinutes() async {
    _ensureTodayWindow();
    final int total = _effectiveOnlineMinutesNow(countRunningSession: true);
    _onlineMinutesToday = total;
    _onlineSessionStartEpochMs = DateTime.now().millisecondsSinceEpoch;
    _onlineMinutesDateKey = _todayKey();
    await OnlineHoursStore.saveTodayMinutes(total);
    await OnlineHoursStore.saveActiveSessionStartEpochMs(
      _onlineSessionStartEpochMs!,
    );
    await _onlineHoursApi.syncTodayOnlineMinutes(total);
  }

  Future<void> _flushOnlineMinutesAndEndSession() async {
    _ensureTodayWindow();
    final int total = _effectiveOnlineMinutesNow(countRunningSession: true);
    _onlineMinutesToday = total;
    _onlineSessionStartEpochMs = null;
    _onlineMinutesDateKey = _todayKey();
    await OnlineHoursStore.saveTodayMinutes(total);
    await OnlineHoursStore.clearActiveSessionStartEpochMs();
    await _onlineHoursApi.syncTodayOnlineMinutes(total);
  }

  String _todayKey() {
    final DateTime now = DateTime.now();
    final String month = now.month.toString().padLeft(2, '0');
    final String day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }

  void _ensureTodayWindow() {
    final DateTime now = DateTime.now();
    final String todayKey = _todayKey();

    if (_onlineMinutesDateKey.isEmpty) {
      _onlineMinutesDateKey = todayKey;
      return;
    }
    if (_onlineMinutesDateKey == todayKey) return;

    _onlineMinutesDateKey = todayKey;
    _onlineMinutesToday = 0;
    unawaited(OnlineHoursStore.saveTodayMinutes(0));

    final int dayStartMs = DateTime(
      now.year,
      now.month,
      now.day,
    ).millisecondsSinceEpoch;
    if (_onlineSessionStartEpochMs != null &&
        _onlineSessionStartEpochMs! < dayStartMs) {
      _onlineSessionStartEpochMs = dayStartMs;
      unawaited(OnlineHoursStore.saveActiveSessionStartEpochMs(dayStartMs));
    }
  }

  void toggleEarningsExpanded() {
    emit(state.copyWith(isEarningsExpanded: !state.isEarningsExpanded));
  }

  void completeRide(double fare) {
    emit(
      state.copyWith(
        totalEarnings: state.totalEarnings + fare,
        tripsCompleted: state.tripsCompleted + 1,
        completedRides: (state.completedRides < state.targetRides)
            ? state.completedRides + 1
            : state.completedRides,
      ),
    );
  }

  void clearOfflineLocationBlock() {
    if (state.offlineBlockIssue == null) return;
    emit(state.copyWith(clearOfflineBlockIssue: true));
  }

  @override
  Future<void> close() {
    _stopTimer();
    _stopOrdersNavigationDelay();
    _stopLocationWatch();
    _lowWalletWarningTimer?.cancel();
    _lowWalletWarningTimer = null;
    if (state.isOnline) {
      unawaited(_flushOnlineMinutesAndEndSession());
    }
    return super.close();
  }
}

// Backwards-compatible alias for older imports.
class DriverStatusCubit extends DriverCubit {
  DriverStatusCubit({super.locationGuard}) : super(minimumDutyWalletBalance: 0);
}
